# 升级池/数据系统 (Upgrade Pool / Data System)

> **Status**: Approved
> **Author**: user + agents
> **Last Updated**: 2026-04-27
> **Implements Pillar**: 每一秒都在做选择、小而深

## Overview

升级池/数据系统是所有升级效果的数据源头和选择逻辑引擎。它定义每种升级的属性（名称、描述、效果值、稀有度、标签），维护当前对局中可用的升级池，并在每次升级窗口触发时从中随机抽取不重复的 3 个升级供玩家选择。本系统不执行升级效果的实际应用（由各玩法系统自行读取属性变化），不渲染升级界面（由局内升级系统负责 UI），它只做两件事：**定义升级是什么，以及决定出现哪些升级**。

## Player Fantasy

你刚清完一波，屏幕中央弹出三个选项：+20% 近战伤害、闪避冷却 -0.3s、移速 +15%。你的手指悬在键盘上犹豫——上次你选了近战流，这次你想试试闪避流。你选了闪避冷却缩短，下一波你明显感觉更灵活了，闪避更频繁地可用。但你知道，如果多叠几层近战伤害，一刀砍死的感觉会更爽。每次三选一都是一次岔路——你选的不是"更强的自己"，而是"哪种更强的自己"。

## Detailed Design

### 1. 升级数据定义

每种升级是一个 `UpgradeData` Resource（`.tres` 文件），包含以下字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | String | 唯一标识，如 `"melee_damage_up"` |
| `display_name` | String | 显示名称，如 "利刃强化" |
| `description` | String | 效果描述，如 "近战伤害 +20%" |
| `rarity` | enum { COMMON, UNCOMMON, RARE } | 稀有度，影响抽中权重 |
| `tags` | Array[String] | 标签，如 `["melee", "offense"]`，用于互斥和筛选 |
| `max_stacks` | int | 最大叠加层数，1 = 不可叠加，-1 = 无限 |
| `effects` | Array[UpgradeEffect] | 效果列表（目标属性 + 修改方式） |

### 2. UpgradeEffect 结构

| 字段 | 类型 | 说明 |
|------|------|------|
| `target_stat` | String | 修改的属性名，如 `"melee_damage_bonus"` |
| `modifier_type` | enum { ADD_ABSOLUTE, ADD_PERCENT } | 绝对值加法或百分比加法 |
| `value` | float | 修改值，如 0.2 (百分比=+20%) 或 50 (绝对值=+50) |

### 3. MVP 升级列表（5 种）

| ID | 名称 | 稀有度 | 效果 | 标签 | 最大层数 |
|----|------|--------|------|------|---------|
| `melee_damage_up` | 利刃强化 | COMMON | melee_damage_bonus +20%（ADD_PERCENT） | melee, offense | 5 |
| `ranged_damage_up` | 穿透弹头 | COMMON | ranged_damage_bonus +20%（ADD_PERCENT） | ranged, offense | 5 |
| `move_speed_up` | 风之步 | COMMON | move_speed_bonus +15%（ADD_PERCENT） | movement | 3 |
| `dodge_cooldown_down` | 幻影步 | UNCOMMON | dodge_cooldown -0.3s（ADD_ABSOLUTE） | dodge, defense | 3 |
| `max_health_up` | 铁壁 | COMMON | max_hp +50（ADD_ABSOLUTE），同时 heal 50 | defense | 5 |

### 4. 升级池管理

- 对局开始时，从所有 `UpgradeData` 资源构建初始升级池
- 每次抽取前，过滤掉已达 `max_stacks` 的升级
- 已选升级记录在 `acquired_upgrades: Dictionary` 中（key=升级id, value=当前层数）

### 5. 抽取逻辑

- 对外暴露方法：`draw_upgrades(count: int) -> Array[UpgradeData]`
- 默认 `count = 3`（三选一）
- 从可用池中按权重随机抽取 `count` 个不重复升级
- 权重由稀有度决定：COMMON=60, UNCOMMON=30, RARE=10

### 6. 叠加逻辑

- 玩家选择升级后，调用 `acquire_upgrade(upgrade_id: String)`
- 如果该升级已存在，层数 +1
- 如果已达 `max_stacks`，该升级不再出现在抽取池中
- 多次叠加同一升级时，效果累加（百分比加法：100% + 20% + 20% = 140%，非乘法 ×1.44）
- `max_health_up` 升级获取时同时调用 `heal(50)`，确保升级后 HP 跟随上限增长

### 7. 与局内升级系统的接口

- 本系统暴露 `draw_upgrades()` 供局内升级系统调用
- 玩家确认选择后，局内升级系统调用 `acquire_upgrade(id)` 记录获取
- 本系统发出 `upgrade_acquired(upgrade_data: UpgradeData, current_stacks: int)` 信号
- 各玩法系统监听此信号，自行应用属性变化

## Formulas

### 抽取权重

```
# 稀有度权重
WEIGHT_COMMON = 60
WEIGHT_UNCOMMON = 30
WEIGHT_RARE = 10

# 单个升级的抽取权重
upgrade_weight = RARITY_WEIGHT[upgrade.rarity]

# 可用池中某升级的抽中概率
probability = upgrade_weight / sum(all_available_upgrades_weights)
```

### 属性修改计算

```
# 百分比加法修改：累加百分比后乘以基础值
# 例：两层利刃强化 → bonus = 20% + 20% = 40%，final = base × 1.4
percent_bonus = sum(all_ADD_PERCENT_effects)  # 如 0.2 + 0.2 = 0.4
final_value = base_value * (1.0 + percent_bonus)  # base × 1.4

# 绝对值加法修改：直接相加
final_value = base_value + sum(all_ADD_ABSOLUTE_effects)
# 例：两层铁壁 → max_hp = 100 + 50 + 50 = 200

# 混合计算顺序：先算百分比，再算绝对值
# （当前无升级同时使用两种类型，预留扩展）
```

### 变量表

| 变量 | 类型 | 范围 | 来源 | 说明 |
|------|------|------|------|------|
| `draw_count` | int | 1-5 | 调参旋钮 | 每次抽取的升级数量 |
| `WEIGHT_COMMON` | int | 10-100 | 调参旋钮 | 普通升级权重 |
| `WEIGHT_UNCOMMON` | int | 5-50 | 调参旋钮 | 稀有升级权重 |
| `WEIGHT_RARE` | int | 1-20 | 调参旋钮 | 罕见升级权重 |

## Edge Cases

| 场景 | 预期行为 | 理由 |
|------|---------|------|
| 可用池中升级数 < `draw_count`（如只剩 2 个可选但需要抽 3 个） | 返回池中所有可用升级（不足 3 个），不报错 | 不强制凑齐，有啥给啥 |
| 可用池为空（所有升级已满层） | 返回空数组，局内升级系统应跳过升级窗口 | 无可选升级时不应卡住游戏 |
| 同一帧内多次调用 `acquire_upgrade()` | 按调用顺序逐次叠加，层数正常递增 | 调用顺序即执行顺序 |
| `UpgradeData` 的 `effects` 为空 | 仍可被抽取和获取，但无实际效果（记录层数） | 防御性处理，空效果属于配置错误但不崩溃 |
| `max_stacks = -1`（无限叠加）的升级 | 永远不会被过滤出池，可无限抽取 | 无上限设计，由玩家自然限制（局越长越强） |
| `max_stacks = 1` 的升级 | 获取一次后从池中移除，不再出现 | 一次性升级，如"解锁二段跳"类效果 |
| 百分比叠加层数极高（如 5 层 +20%） | 属性值按加法百分比计算，5 层 = +100%（翻倍），不做上限截断 | 加法百分比比乘法更可控，数值爆炸由 max_stacks 限制 |
| `dodge_cooldown_down` 叠加后冷却 < 0.3s | 冷却最低 0.3s，不再继续减少 | 防止闪避冷却过低导致无敌循环 |
| `max_health_up` 升级时当前 HP 已满 | max_hp +50 并 heal 50，HP 仍为满 | 符合预期，升级后保持满血 |
| `draw_count` 为 0 | 返回空数组，不执行抽取 | 无意义调用，防御性处理 |

## Dependencies

| 依赖系统 | 方向 | 依赖内容 | 状态 |
|---------|------|---------|------|
| 局内升级系统 | 下游 ← 本系统 | 调用 `draw_upgrades()` 获取选项，选择后调用 `acquire_upgrade()` | GDD 未设计 |
| 混合战斗系统 | 下游监听 | 监听 `upgrade_acquired` 信号，应用 melee/ranged damage 修改 | GDD 已通过 ✅ |
| 玩家移动系统 | 下游监听 | 监听 `upgrade_acquired` 信号，应用 move_speed 修改 | GDD 已通过 ✅ |
| 闪避系统 | 下游监听 | 监听 `upgrade_acquired` 信号，应用 dodge_cooldown 修改 | GDD 已通过 ✅ |
| 生命/伤害系统 | 下游监听 | 监听 `upgrade_acquired` 信号，应用 max_hp 修改并 heal | GDD 已通过 ✅ |

**本系统无上游依赖**（Foundation 层），是纯数据定义 + 选择逻辑，不依赖任何其他系统。

**双向依赖说明**：
- 局内升级系统的 GDD 必须确认 `draw_upgrades()` 和 `acquire_upgrade()` 接口
- 各下游系统需要定义与 `UpgradeEffect.target_stat` 对应的属性名，确保命名一致

## Tuning Knobs

| 旋钮 | 类型 | 默认值 | 安全范围 | 影响玩法 | 说明 |
|------|------|--------|---------|---------|------|
| `draw_count` | int | 3 | 1–5 | 选择深度 | 每次抽取数量，3=三选一，越少决策压力越大 |
| `WEIGHT_COMMON` | int | 60 | 10–100 | 基础升级出现频率 | 越高普通升级越常出现，build 方向性越弱 |
| `WEIGHT_UNCOMMON` | int | 30 | 5–50 | 稀有升级出现频率 | 影响闪避冷却缩短等关键升级的获取难度 |
| `WEIGHT_RARE` | int | 10 | 1–20 | 罕见升级出现频率 | MVP 暂无 RARE 升级，预留扩展 |

**配置方式**：权重定义在 `assets/data/upgrade_pool_config.tres`（Resource 文件），运行时加载，支持热重载调参。

**备注**：MVP 阶段只有 5 种升级且 4 种为 COMMON，权重对实际体验影响有限。升级种类增多后权重调参才有明显意义。

## Visual/Audio Requirements

**MVP 阶段：本系统无专属视觉/音频**。

本系统是纯数据和逻辑层，不直接播放任何音效或渲染任何视觉元素。升级的视觉反馈由以下系统负责：

- **升级界面动画/音效** → 局内升级系统
- **属性变化后的战斗反馈**（如伤害数字变大、移动变快） → 各下游玩法系统

本系统只发出 `upgrade_acquired` 信号，下游系统决定如何表现。

## UI Requirements

**MVP 阶段：本系统无专属 UI**。

本系统不直接驱动任何界面。升级选择界面的渲染和交互由局内升级系统负责。本系统只提供数据（`draw_upgrades()` 返回的 `UpgradeData` 数组），局内升级系统读取其中的 `display_name`、`description`、`rarity` 来渲染 UI。

**数据契约**：局内升级系统需要从 `UpgradeData` 读取以下字段用于 UI 展示：
- `display_name` — 升级名称
- `description` — 效果描述文本
- `rarity` — 用于稀有度边框/颜色区分

## Acceptance Criteria

| 编号 | 标准 | 验证方式 |
|------|------|---------|
| AC-1 | `draw_upgrades(3)` 返回恰好 3 个不同的 `UpgradeData` | 单元测试：断言返回数组长度=3，所有 id 互不相同 |
| AC-2 | 返回的升级均未达 `max_stacks` | 单元测试：预设某升级已满层，断言不出现在结果中 |
| AC-3 | `acquire_upgrade("melee_damage_up")` 后层数从 0 变为 1 | 单元测试：断言 `acquired_upgrades` 字典更新正确 |
| AC-4 | 同一升级叠加 2 次后层数为 2，百分比加法 100%+20%+20%=140% | 单元测试：2 次调用后断言层数=2，计算值=base×1.4 |
| AC-5 | 可用池为空时 `draw_upgrades()` 返回空数组 | 单元测试：所有升级满层后断言返回 [] |
| AC-6 | 可用池仅剩 1 个升级时 `draw_upgrades(3)` 返回 1 个 | 单元测试：断言返回长度=1 |
| AC-7 | `upgrade_acquired` 信号携带正确的 `UpgradeData` 和层数 | 单元测试：监听信号，断言参数匹配 |
| AC-8 | ADD_PERCENT 和 ADD_ABSOLUTE 混合时计算顺序正确 | 单元测试：同时应用两种效果，断言结果值 |
| AC-9 | `max_stacks = 1` 的升级获取后从池中移除 | 单元测试：获取后再次抽取，断言该升级不出现在结果中 |
| AC-10 | MVP 5 种升级均可被抽取且数据完整 | 集成测试：遍历所有 UpgradeData，断言字段非空 |

## Open Questions

1. **升级效果 target_stat 命名映射**：已确定命名映射——`melee_damage_bonus` 对应战斗系统、`move_speed_bonus` 对应移动系统、`dodge_cooldown` 对应闪避系统、`max_hp` 对应生命/伤害系统。实现时需确保各系统属性名与此一致。
2. **局内升级系统接口确认**：`draw_upgrades()` 和 `acquire_upgrade()` 接口已在局内升级系统 GDD 中确认对齐 ✅
3. **升级互斥规则**：MVP 不做互斥，但后续是否需要"选了近战流就不能选远程流"的互斥标签机制？预留了 `tags` 字段但 MVP 不启用。
4. **RARE 稀有度升级**：MVP 暂无 RARE 升级，后续加入时需定义其具体效果和出现条件（如仅在高波次出现）。
5. **`dodge_cooldown_down` 冷却下限**：叠加 3 层后冷却为 2.0 - 0.3×3 = 1.1s，最低 0.3s。需 playtest 验证是否过强。
