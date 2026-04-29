# 分数/统计系统 (Score / Stats System)

> **Status**: Approved
> **Author**: user + agents
> **Last Updated**: 2026-04-27
> **Implements Pillar**: 每一秒都在做选择、死亡有意义

## Overview

分数/统计系统负责追踪和记录单局游戏中的所有数值统计——击杀数、受到伤害、输出伤害、存活波次、存活时间等。它是游戏内所有"数字反馈"的数据源头：战斗 HUD 从本系统读取当前分数和波次显示，波次系统从本系统读取击杀数判断波次完成，结算画面从本系统读取全部分析数据。本系统不渲染任何 UI，不控制任何玩法逻辑，它只做一件事：**准确地记下发生了什么**。

## Player Fantasy

第 12 波结束了，你扫一眼右上角：分数 47,200，击杀 83。你知道前天的记录是 52,100，还差一点。这次你选了近战流 build，近战击杀占比 68%——比上次纯远程流的体验完全不同。你死了，但结算画面告诉你"本局最长存活 9 分 32 秒"，比上周多了 1 分钟。数字不会撒谎，它们证明你在变强。

## Detailed Design

### 1. 追踪的统计数据

本系统维护一个 `RunStats` 资源，包含以下字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `score` | int | 总分数 |
| `wave_reached` | int | 到达的最高波次 |
| `total_kills` | int | 总击杀数 |
| `melee_kills` | int | 近战击杀数 |
| `ranged_kills` | int | 远程击杀数 |
| `total_damage_dealt` | float | 总输出伤害 |
| `total_damage_taken` | float | 总受到伤害 |
| `survival_time` | float | 存活时间（秒） |
| `upgrades_acquired` | int | 获取升级次数 |

### 2. 数据来源与信号监听

本系统通过监听其他系统的信号来收集数据，不主动轮询：

| 数据 | 来源信号 | 来源系统 |
|------|---------|---------|
| 击杀数 +1 | `enemy_killed(kill_type: String, position, enemy_color)` | 生命/伤害系统 |
| 输出伤害 | `damage_dealt(amount: float, hit_position, attack_type)` | 生命/伤害系统 |
| 受到伤害 | `damage_taken(amount: float, position)` | 生命/伤害系统 |
| 到达波次 | `wave_started(wave_number: int)` | 波次系统 |
| 获取升级 | `upgrade_acquired(upgrade_data, current_stacks)` | 升级池/数据系统 |
| 生成敌人数 | `wave_spawn_complete(count: int)` | 敌人生成系统 |

### 3. 分数计算

分数不是单一值累加，而是由击杀行为驱动：

```
击杀近战敌人 → +100 分
击杀远程敌人 → +150 分（远程更难接近，奖励更高）
```

分数在击杀时即时累加，不做延时或批量计算。

### 4. 存活时间追踪

- 对局开始时启动计时（记录起始时间戳）
- 每帧更新 `survival_time = current_time - start_time`
- 玩家死亡时停止计时，最终值冻结

### 5. 对外接口

| 方法/信号 | 类型 | 说明 |
|----------|------|------|
| `get_score() -> int` | 方法 | 当前分数 |
| `get_wave_reached() -> int` | 方法 | 当前波次 |
| `get_total_kills() -> int` | 方法 | 总击杀数 |
| `get_stats() -> RunStats` | 方法 | 返回完整统计快照（供结算画面使用） |
| `score_changed(new_score: int)` | 信号 | 分数变化时通知 HUD |
| `kill_count_changed(total: int)` | 信号 | 击杀数变化时通知 HUD |

### 6. 重置逻辑

- 每局开始时调用 `reset()`，所有统计归零
- `reset()` 由游戏状态管理（或主场景）在对局开始时调用
- 重置后重新启动存活计时

## Formulas

### 分数计算

```
# 单次击杀得分
kill_score(melee)  = SCORE_MELEE_KILL    # 100
kill_score(ranged) = SCORE_RANGED_KILL   # 150

# 累加
score += kill_score(enemy_type)
```

### 存活时间

```
# 每帧更新（存活期间）
survival_time = Time.get_ticks_msec() / 1000.0 - start_timestamp

# 死亡时冻结
final_survival_time = survival_time  # 不再更新
```

### 变量表

| 变量 | 类型 | 范围 | 来源 | 说明 |
|------|------|------|------|------|
| `SCORE_MELEE_KILL` | int | 50-200 | 调参旋钮 | 近战击杀得分 |
| `SCORE_RANGED_KILL` | int | 75-300 | 调参旋钮 | 远程击杀得分 |
| `start_timestamp` | float | — | 运行时 | 对局开始时间戳，reset() 时设置 |

## Edge Cases

| 场景 | 预期行为 | 理由 |
|------|---------|------|
| 同一帧内多个敌人被击杀 | 每次击杀信号独立处理，分数和击杀数逐次累加 | 信号驱动，天然支持批量 |
| `enemy_killed` 信号的 `kill_type` 不在预期值中 | 忽略该击杀，不计分不计数，打印警告 | 未知类型属于配置错误，不崩溃 |
| 对局未开始就收到击杀信号 | 仍然记录（系统始终处于可记录状态） | 防御性处理，不应在非游戏状态收到信号 |
| `reset()` 后立即收到旧信号 | 正常记录到新一轮统计 | reset 后统计已归零，新数据正常累加 |
| 玩家从未受到伤害 | `total_damage_taken` 保持 0 | 初始值即为 0，无伤通关的合理结果 |
| 游戏暂停期间 | `survival_time` 继续计时（暂停不停止） | MVP 不做暂停时间排除，简化实现 |
| 一局时间极长（>1 小时） | `survival_time` 正常累加，无溢出风险 | float 精度足够支撑数小时 |

## Dependencies

| 依赖系统 | 方向 | 依赖内容 | 状态 |
|---------|------|---------|------|
| 生命/伤害系统 | 上游 → 本系统 | 发出 `enemy_killed`、`damage_dealt`、`damage_taken` 信号 | GDD 已通过 ✅ |
| 混合战斗系统 | 上游 → 本系统 | 通过生命/伤害系统间接触发击杀统计 | GDD 已通过 ✅ |
| 敌人生成系统 | 上游 → 本系统 | 发出 `wave_spawn_complete` 信号 | GDD 已通过 ✅ |
| 升级池/数据系统 | 上游 → 本系统 | 发出 `upgrade_acquired` 信号 | GDD 已通过 ✅ |
| 波次系统 | 双向 | 本系统监听 `wave_started`；波次系统读取击杀数判断波次完成 | GDD 未设计 |
| 战斗 HUD | 下游 ← 本系统 | 读取分数、波次、击杀数显示 | GDD 未设计 |
| 结算/局外界面 | 下游 ← 本系统 | 读取 `get_stats()` 完整统计 | GDD 未设计（v1.0） |

**双向依赖说明**：
- 波次系统需要从本系统读取当前波次击杀数来判断"本波是否清完"——此接口待波次系统 GDD 确认具体需求
- 生命/伤害系统的 `enemy_killed` 信号需包含 `kill_type`（"melee"/"ranged"），需确认该信号定义

## Tuning Knobs

| 旋钮 | 类型 | 默认值 | 安全范围 | 影响玩法 | 说明 |
|------|------|--------|---------|---------|------|
| `SCORE_MELEE_KILL` | int | 100 | 50–200 | 分数增长速度 | 近战击杀得分，影响分数通胀率 |
| `SCORE_RANGED_KILL` | int | 150 | 75–300 | 分数增长速度 | 远程击杀得分，应 > 近战得分以补偿风险差异 |

**配置方式**：分数定义在 `assets/data/score_config.tres`（Resource 文件），运行时加载。

**备注**：MVP 阶段分数仅为展示用途（无排行榜、无碎片换算），调参优先级低。v1.0 碎片/货币系统上线后，分数可能影响碎片获取量，届时再精细调参。

## Visual/Audio Requirements

**MVP 阶段：本系统无专属视觉/音频**。

本系统是纯数据记录层，不播放音效或渲染视觉元素。分数变化、击杀数变化等视觉反馈由战斗 HUD 负责（监听本系统的 `score_changed` 和 `kill_count_changed` 信号）。

## UI Requirements

**MVP 阶段：本系统无专属 UI**。

本系统不直接驱动任何界面。战斗 HUD 和结算画面从本系统读取数据来展示：

- **战斗 HUD** 需读取：`score`、`wave_reached`、`total_kills`
- **结算画面**（v1.0）需读取：`get_stats()` 返回的完整 `RunStats` 快照

本系统通过 `score_changed` 和 `kill_count_changed` 信号主动推送变化，HUD 可选择监听信号或轮询 getter。

## Acceptance Criteria

| 编号 | 标准 | 验证方式 |
|------|------|---------|
| AC-1 | 击杀近战敌人后 `total_kills` +1、`melee_kills` +1、分数 +100 | 单元测试：模拟 `enemy_killed("melee")` 信号，断言三项更新 |
| AC-2 | 击杀远程敌人后 `ranged_kills` +1、分数 +150 | 单元测试：模拟 `enemy_killed("ranged")` 信号，断言更新正确 |
| AC-3 | `total_kills = melee_kills + ranged_kills` 始终成立 | 单元测试：混合击杀后断言等式 |
| AC-4 | 收到 `damage_dealt` 信号后 `total_damage_dealt` 累加 | 单元测试：发送信号，断言累加值 |
| AC-5 | 收到 `damage_taken` 信号后 `total_damage_taken` 累加 | 单元测试：发送信号，断言累加值 |
| AC-6 | `wave_started` 信号更新 `wave_reached` 为更大值 | 单元测试：发送 wave_started(5) 后 wave_started(3)，断言 wave_reached=5 |
| AC-7 | `upgrade_acquired` 信号使 `upgrades_acquired` +1 | 单元测试：发送信号，断言计数增加 |
| AC-8 | `reset()` 后所有统计归零、存活时间重新计时 | 单元测试：reset 后断言所有字段为初始值 |
| AC-9 | `score_changed` 信号在分数变化时发出 | 单元测试：监听信号，断言触发且参数正确 |
| AC-10 | `get_stats()` 返回的快照与当前统计一致 | 单元测试：多次操作后调用，断言快照值匹配 |

## Open Questions

1. **波次击杀数 vs 总击杀数**：波次系统可能需要"当前波次击杀数"来判断波次完成，本系统目前只追踪总击杀数。是否需要新增 `current_wave_kills` 字段？待波次系统 GDD 确认。
2. **`enemy_killed` 信号定义**：已在生命/伤害系统 GDD 中统一定义为 `enemy_killed(kill_type: String, position: Vector2, enemy_color: Color)` ✅
3. **暂停期间时间处理**：MVP 不排除暂停时间，后续如果加入暂停功能需重新评估。
4. **分数是否影响碎片获取**：v1.0 碎片/货币系统可能将分数作为碎片换算因子，届时分数公式可能需要波次乘数等加成。
5. **历史记录持久化**：当前统计为单局内存数据，`reset()` 后丢失。是否需要将每局结果持久化到本地文件供"历史最佳"对比？v1.0 再考虑。
