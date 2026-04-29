# 武器系统 (Weapon System)

> **Status**: Approved
> **Author**: user + agents
> **Last Updated**: 2026-04-24
> **Implements Pillar**: 操作感即玩法、每一秒都在做选择

## Overview

武器系统是游戏中所有武器数据的唯一权威来源。它不管理攻击逻辑（那是混合战斗系统的职责），也不管理伤害计算（那是生命/伤害系统的职责）——它只做一件事：**定义武器的参数**，供其他系统读取。每把武器是一个 Godot Resource（`.tres`），包含类型（`melee` 或 `ranged`）、基础伤害、冷却时间、攻击范围、弹道属性等参数。MVP 阶段提供两把默认武器：大剑（近战）和手枪（远程），战斗系统从资源文件加载这些数据后执行攻击逻辑。

## Player Fantasy

你从地上捡起一把新的武器——霰弹枪。装备后，你的右键攻击从单发子弹变成了扇形散射，每发伤害略低但近距离覆盖面积更大。你能**看到**武器之间的差异：大剑的挥砍弧线宽而慢，手枪的弹道快而精准，霰弹枪的散射密集而短距。武器不是"数值换皮"，而是**改变玩法的工具**。当你尝试不同的左右手搭配时，你是在实验自己的战斗风格——是贴身猛砍、远处点射，还是近战牵制+远程补刀的组合？每一次更换武器，都是一次策略的重置。

## Detailed Design

### Core Rules

1. **武器 Resource 定义**
   - 每把武器是一个自定义 Resource 类 `WeaponData`，继承自 Godot `Resource`
   - 所有武器参数通过 `@export` 属性暴露，支持编辑器直接调整
   - 武器数据文件存储在 `assets/data/weapons/` 目录下（`.tres` 格式）

2. **武器类型**
   - 每把武器有 `weapon_type: String`，值为 `"melee"` 或 `"ranged"`
   - 类型决定哪些参数生效：近战武器忽略弹道参数，远程武器忽略扇形参数
   - 类型在武器创建时确定，运行时不可更改

3. **近战武器参数**
   - `melee_angle`: 扇形角度（度），范围 60-180°，默认 105°
   - `melee_radius`: 扇形半径（像素），范围 30-100px
   - 近战武器没有弹药和射程概念，这两个参数设为 0

4. **远程武器参数**
   - `bullet_speed`: 弹体飞行速度（px/s），范围 300-1000
   - `max_range`: 弹体最大射程（px），范围 200-800
   - `scatter_degrees`: 双远程配置下的散射角度（度），范围 0-15°
   - `max_ammo`: 弹药上限（整数），范围 5-30
   - 远程武器没有扇形参数，`melee_angle` 和 `melee_radius` 设为 0

5. **通用参数**（所有武器都有）
   - `weapon_name`: 武器显示名称（String）
   - `base_damage`: 基础伤害（int），范围 1-999
   - `attack_cooldown`: 攻击冷却时间（float 秒），范围 0.1-2.0s
   - `weapon_type`: 类型（"melee" 或 "ranged"）

6. **武器槽位**
   - 玩家有左手槽和右手槽两个武器位
   - 每个槽位存储一个 `WeaponData` Resource 引用
   - MVP 默认配置：左手 = 大剑（近战），右手 = 手枪（远程）
   - 武器槽位数据由战斗系统读取，本系统不管理装备/切换逻辑

7. **数据暴露接口**
   - `WeaponData` Resource 的 `@export` 属性就是接口本身
   - 战斗系统通过 `weapon_data.base_damage` 等方式直接读取属性
   - 不定义额外信号或方法——武器数据是**只读**的

### States and Transitions

武器系统是纯数据定义层，**不管理运行时状态**。`WeaponData` Resource 的所有属性在加载后为只读，不存在状态转换。

运行时状态（如冷却进度、当前弹药量、是否正在攻击）由**混合战斗系统**管理，不属于本系统职责。

### Interactions with Other Systems

| 交互系统 | 方向 | 接口说明 |
|---------|------|---------|
| 混合战斗系统 | 本系统 → 战斗 | 战斗系统读取 `WeaponData` Resource 的所有参数（伤害、冷却、扇形、弹道、弹药）执行攻击逻辑 |
| 生命/伤害系统 | 本系统 → 生命/伤害 | 间接交互：战斗系统读取本系统的 `base_damage` 和 `weapon_type`，传给 `take_damage()` |
| UI 系统 | 本系统 → UI | UI 系统读取 `weapon_name`、`base_damage` 等用于武器信息显示（如装备界面） |
| 局内升级系统 | 升级 → 本系统 | 升级系统可能修改武器的运行时参数（如 +20% 伤害），但**不修改 Resource 文件本身**，修改由战斗系统持有 |

## Formulas

武器系统本身不执行计算公式，但定义**所有参数的合法范围**，供战斗系统验证：

```
# 近战武器有效参数检查
if weapon_type == "melee":
    assert melee_angle >= 60 and melee_angle <= 180
    assert melee_radius >= 30 and melee_radius <= 100
    assert bullet_speed == 0
    assert max_range == 0
    assert scatter_degrees == 0
    assert max_ammo == 0

# 远程武器有效参数检查
if weapon_type == "ranged":
    assert bullet_speed >= 300 and bullet_speed <= 1000
    assert max_range >= 200 and max_range <= 800
    assert scatter_degrees >= 0 and scatter_degrees <= 15
    assert max_ammo >= 5 and max_ammo <= 30
    assert melee_angle == 0
    assert melee_radius == 0
```

#### 完整参数表

| 变量 | 类型 | 范围 | 默认值 | 说明 |
|------|------|------|--------|------|
| `weapon_name` | String | — | "未命名武器" | 显示名称 |
| `weapon_type` | String | "melee"/"ranged" | "melee" | 武器类型 |
| `base_damage` | int | 1-999 | 25（近战）/ 15（远程） | 基础伤害 |
| `attack_cooldown` | float | 0.1-2.0s | 0.5（近战）/ 0.3（远程） | 攻击冷却 |
| `melee_angle` | float | 0, 60-180° | 105（近战）/ 0（远程） | 扇形角度 |
| `melee_radius` | float | 0, 30-100px | 60（近战）/ 0（远程） | 扇形半径 |
| `bullet_speed` | float | 0, 300-1000 px/s | 0（近战）/ 600（远程） | 弹速 |
| `max_range` | float | 0, 200-800px | 0（近战）/ 400（远程） | 射程 |
| `scatter_degrees` | float | 0-15° | 0（近战）/ 5（远程） | 散射角度 |
| `max_ammo` | int | 0, 5-30 | 0（近战）/ 10（远程） | 弹药上限 |

## Edge Cases

| 场景 | 预期行为 | 理由 |
|------|---------|------|
| `WeaponData` 的 `weapon_type` 既不是 "melee" 也不是 "ranged" | 游戏启动时 `_init()` 中断言失败，拒绝加载 | 非法类型不应进入运行时 |
| 近战武器的 `melee_angle` 或 `melee_radius` 超出范围 | 启动时断言失败，编辑器中 Resource 验证提示 | 参数越界会破坏战斗系统碰撞检测 |
| 远程武器的 `bullet_speed`、`max_range`、`max_ammo` 超出范围 | 同上 | 弹道参数越界会导致弹体行为异常 |
| 近战武器设置了弹道参数（`bullet_speed > 0` 等） | 启动时断言失败，近战武器弹道参数必须为 0 | 类型与参数不匹配属于数据错误 |
| 远程武器设置了扇形参数（`melee_angle > 0` 等） | 启动时断言失败，远程武器扇形参数必须为 0 | 同上 |
| `base_damage` 为 0 | 启动时断言失败，伤害至少为 1 | 0 伤害武器无意义 |
| `attack_cooldown` ≤ 0 | 启动时断言失败，冷却时间至少 0.1s | 0 冷却会导致每帧攻击 |
| `weapon_name` 为空字符串 | 使用默认值 "未命名武器"，不报错 | 名称不影响逻辑，降级处理即可 |
| 两个槽位引用同一个 `WeaponData` Resource 实例 | 允许，两只手可以持有同一种武器 | 双近战/双远程是合法配置 |
| `WeaponData` Resource 引用为 null（槽位为空） | 战斗系统跳过该槽位，不执行攻击 | 空槽位不应崩溃 |
| 运行时升级系统修改武器参数后，原 `.tres` 文件 | 不受影响，`.tres` 文件始终不变 | 升级修改的是内存中的副本，不回写磁盘 |

## Dependencies

| 系统 | 方向 | 性质 |
|------|------|------|
| 混合战斗系统 | 本系统 → 战斗 | 硬依赖：战斗系统读取 `WeaponData` 的所有参数执行攻击逻辑 |
| 生命/伤害系统 | 本系统 → 生命/伤害 | 间接：战斗系统将 `base_damage` 和 `weapon_type` 传递给 `take_damage()`，本系统不直接调用 |
| 战斗 HUD | 本系统 → HUD | 软依赖：HUD 读取弹药量、武器类型用于显示 |
| 升级池/数据系统 | 升级 → 本系统 | 软依赖：`melee_damage_bonus`/`ranged_damage_bonus` 升级影响伤害计算，但不修改 `WeaponData` 本身 |

> **注意**：本系统是纯数据层，不主动调用任何系统，只被动提供数据。依赖方向均为"其他系统读取本系统"。

## Tuning Knobs

| 参数 | 当前值 | 安全范围 | 调高效果 | 调低效果 |
|------|--------|----------|---------|---------|
| `base_damage`（近战） | 25 | 10-80 | 近战单次伤害更高，击杀更快 | 近战伤害不足，需要更多次攻击 |
| `base_damage`（远程） | 15 | 5-50 | 远程单次伤害更高 | 远程伤害不足，过度依赖近战 |
| `attack_cooldown`（近战） | 0.5s | 0.2-1.5s | 近战节奏更慢，容错率更高 | 近战更快但可能过于强势 |
| `attack_cooldown`（远程） | 0.3s | 0.1-1.0s | 远程节奏更慢，鼓励近战 | 远程更快，可能压制近战 |
| `melee_angle` | 105° | 60-180° | 近战覆盖范围更大，更容易命中 | 近战更精准，需要走位 |
| `melee_radius` | 60px | 30-100px | 近战攻击距离更远 | 近战需要更贴近敌人 |
| `bullet_speed` | 600 px/s | 300-1000 px/s | 弹体更快命中，手感更好 | 弹体更慢，需要预判 |
| `max_range` | 400px | 200-800px | 远程可以打更远的敌人 | 远程需要更靠近敌人 |
| `scatter_degrees` | 5° | 0-15° | 双远程更不准，风险更大 | 双远程更准，可能过于强势 |
| `max_ammo` | 10 | 5-30 | 弹药更充足，减少近战压力 | 弹药紧张，强制切换近战 |

> **注意**：本系统只定义参数值和安全范围，不执行调谐逻辑。实际调谐通过修改 `.tres` 文件完成，即时生效无需重新编译。

## Visual/Audio Requirements

| 事件 | 视觉反馈 | 音频反馈 | 说明 |
|------|---------|---------|------|
| 近战挥砍 | 武器挥砍轨迹粒子（弧形，颜色随武器变化） | 挥砍音效（短促破风声） | 粒子形状由 `melee_angle` 和 `melee_radius` 驱动 |
| 远程射击 | 枪口闪光 + 弹体发光粒子轨迹 | 射击音效（清脆爆破感） | 弹体速度由 `bullet_speed` 决定 |
| 弹药耗尽 | 无弹体生成 | 空弹咔哒声 | 提示玩家弹药不足 |
| 切换武器 | 武器切换动画（0.1s 渐变） | 装备音效（金属碰撞感） | MVP 后期考虑 |

> **注意**：本系统是纯数据层，不负责渲染或播放。视觉/音频反馈由战斗系统和视觉/音效系统根据 `WeaponData` 参数触发。本表定义的是**期望的反馈效果**，供其他系统实现时参考。

## UI Requirements

| UI 元素 | 数据来源 | 显示规则 | MVP 状态 |
|---------|---------|---------|---------|
| 武器名称 | `weapon_name` | 始终显示，空值降级为"未命名武器" | MVP |
| 武器图标 | `icon: Texture2D`（新增可选字段） | 有则显示，无则显示占位符 | MVP（占位符） |
| 弹药数 / 上限 | 战斗系统运行时状态 + `max_ammo` | 仅远程武器显示，格式 "3/10" | MVP |
| 冷却指示器 | 战斗系统运行时冷却进度 | 攻击后显示进度条，冷却结束隐藏 | MVP 后期 |

新增 `WeaponData` 字段：`icon: Texture2D`（`@export`，默认 null，可选）

## Acceptance Criteria

- [ ] `WeaponData` 继承 Godot `Resource`，所有参数通过 `@export` 暴露
- [ ] 近战武器默认值：`weapon_type="melee"`, `base_damage=25`, `attack_cooldown=0.5`, `melee_angle=105`, `melee_radius=60`，弹道参数全为 0
- [ ] 远程武器默认值：`weapon_type="ranged"`, `base_damage=15`, `attack_cooldown=0.3`, `bullet_speed=600`, `max_range=400`, `scatter_degrees=5`, `max_ammo=10`，扇形参数全为 0
- [ ] `weapon_type` 不是 "melee" 或 "ranged" 时，启动断言失败
- [ ] 近战武器弹道参数不为 0 时，启动断言失败
- [ ] 远程武器扇形参数不为 0 时，启动断言失败
- [ ] `base_damage` 为 0 时，启动断言失败
- [ ] `attack_cooldown` < 0.1 时，启动断言失败
- [ ] `weapon_name` 为空时，降级显示 "未命名武器"
- [ ] 大剑 `.tres` 和手枪 `.tres` 文件存在于 `assets/data/weapons/` 目录
- [ ] `icon` 字段为可选 Texture2D，默认 null，不影响武器功能
- [ ] 战斗系统能通过 `weapon_data.base_damage` 等方式直接读取参数
- [ ] 运行时修改 `WeaponData` 副本的值不影响原 `.tres` 文件

## Open Questions

| 问题 | 状态 | 备注 |
|------|------|------|
| 武器切换是否需要专属 UI（武器轮盘/快捷栏）？ | 待定 | 取决于输入系统 GDD 的槽位切换设计，MVP 默认左右手固定不切换 |
| 武器稀有度是否影响 UI 显示（边框颜色/特效）？ | 待定 | MVP 无稀有度系统，留待局内升级系统设计时决定 |
| 远程武器弹药恢复方式影响 UI 显示逻辑？ | 待定 | 弹药恢复属于战斗/升级系统职责，确认后更新 UI 规则 |
