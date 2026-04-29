# 敌人生成系统 (Enemy Spawn System)

> **Status**: Approved
> **Author**: user + agents
> **Last Updated**: 2026-04-27
> **Implements Pillar**: 操作感即玩法、小而深

## Overview

敌人生成系统负责在竞技场中创建敌人实例，是敌人出现的唯一入口。波次系统通过指令接口告诉本系统"生成 N 个某类型的敌人"，本系统确定每个敌人的生成位置并完成实例化。敌人在玩家周围随机位置生成——距玩家一定距离外、竞技场边界内的随机点，确保玩家不会在敌人正脚下突然遭遇。本系统为每个敌人注入对应的 `EnemyData` Resource（定义在 `assets/data/enemies/`），创建后敌人自动进入敌人 AI 系统的 SPAWN 状态。本系统不控制生成节奏（由波次系统驱动），不控制敌人行为（由 AI 系统驱动），它只做一件事：**在正确的位置创建正确的敌人**。

## Player Fantasy

你刚清完一波，四周短暂安静——然后你听到生成音效，余光中敌人开始在周围浮现。你扫一眼：左边两只近战型侧移准备包抄，右后方一只远程型已经拉开距离准备射击。你没有被吓到，因为你有时间反应——敌人生成时有短暂的浮现动画，不是突然闪现。你快速判断优先级：先冲远程，再回头收拾近战。每一次敌人出现，都是一次新的决策时刻。

## Detailed Design

### Core Rules

1. **生成接口**
   - 对外暴露方法：`spawn_enemies(enemy_type: String, count: int, wave_number: int)`
   - `enemy_type`：敌人类型标识（"melee" 或 "ranged"），对应 `EnemyData` Resource
   - `count`：本次生成的敌人数量
   - `wave_number`：当前波次编号，用于难度缩放（后期扩展）
   - 波次系统调用此接口触发生成，本系统不主动生成

2. **生成位置计算**
   - 在玩家周围环形区域内随机选取生成点
   - 最小距离：`spawn_min_distance`（默认 200px）——不会在玩家身边突然出现
   - 最大距离：`spawn_max_distance`（默认 400px）——不会太远导致玩家看不到
   - 角度：0-360° 随机均匀分布
   - 生成点必须在竞技场边界内，超出边界的位置沿最近边界修正

3. **多敌人位置分散**
   - 同一次 `spawn_enemies()` 调用中的多个敌人，位置不完全重叠
   - 每个敌人在基础角度上增加 `±spawn_angle_spread`（默认 ±30°）的随机偏移
   - 偏移后仍需验证是否在竞技场内

4. **位置验证与修正**
   - 计算生成点后检查是否在竞技场 `Rect2` 内
   - 超出边界：将生成点沿最近边界方向修正到边界内
   - 修正后如果距玩家 < `spawn_min_distance`，放弃该位置，重新随机（最多重试 `max_spawn_retries` 次，默认 3 次）
   - 3 次重试仍失败，在竞技场边缘随机位置生成

5. **敌人实例化**
   - 根据敌人类型加载对应的 `EnemyData` Resource（`.tres` 文件）
   - 实例化敌人场景（`PackedScene`），注入 `EnemyData`
   - 设置生成位置
   - 添加到场景树，敌人自动进入敌人 AI 系统的 SPAWN 状态（0.3s 生成动画）
   - 敌人场景存储在 `assets/scenes/enemies/` 目录下

6. **敌人类别映射**
   - `"melee"` → `EnemyData`: `assets/data/enemies/melee_enemy.tres`，场景: `assets/scenes/enemies/melee_enemy.tscn`
   - `"ranged"` → `EnemyData`: `assets/data/enemies/ranged_enemy.tres`，场景: `assets/scenes/enemies/ranged_enemy.tscn`
   - 映射关系通过字典配置，新增敌人类型只需添加映射条目

7. **波次系统接口（临时定义，待波次系统 GDD 确认）**
   - 本系统暴露 `spawn_enemies()` 供波次系统调用
   - 本系统在敌人全部生成后发出 `wave_spawn_complete` 信号（含生成数量）
   - 本系统不跟踪敌人存活状态——存活/死亡由生命/伤害系统和统计系统管理

### States and Transitions

本系统是无状态的——每次调用 `spawn_enemies()` 独立执行，不维护内部状态机。

### Interactions with Other Systems

| 交互系统 | 方向 | 接口说明 |
|---------|------|---------|
| 波次系统 | 波次 → 本系统 | 调用 `spawn_enemies(enemy_type, count, wave_number)` 触发生成 |
| 敌人 AI 系统 | 本系统 → AI | 创建敌人实例并注入 `EnemyData`，敌人自动进入 SPAWN 状态 |
| 玩家移动系统 | 本系统读取移动 | 读取玩家 `position` 用于计算生成位置 |
| 生命/伤害系统 | 间接 | 敌人 HP 由生命/伤害系统管理，本系统只负责创建 |
| 分数/统计系统 | 本系统 → 统计 | 发出 `wave_spawn_complete` 信号通知生成了多少敌人 |

## Formulas

### 生成位置计算

```
# 基础角度（随机）
base_angle = randf() * TAU  # 0 到 2π

# 单个敌人角度偏移
enemy_angle = base_angle + randf_range(-spawn_angle_spread, spawn_angle_spread)

# 生成距离（在最小和最大之间随机）
spawn_distance = randf_range(spawn_min_distance, spawn_max_distance)

# 生成位置
spawn_position = player_position + Vector2(cos(enemy_angle), sin(enemy_angle)) * spawn_distance
```

### 竞技场边界修正

```
# 将生成点限制在竞技场 Rect2 内
spawn_position.x = clamp(spawn_position.x, arena_rect.position.x, arena_rect.end.x)
spawn_position.y = clamp(spawn_position.y, arena_rect.position.y, arena_rect.end.y)
```

### 变量表

| 变量 | 类型 | 范围 | 来源 | 说明 |
|------|------|------|------|------|
| `spawn_min_distance` | float | 100-400 px | 调参旋钮 | 生成点距玩家最小距离 |
| `spawn_max_distance` | float | 200-600 px | 调参旋钮 | 生成点距玩家最大距离 |
| `spawn_angle_spread` | float | 0-90° | 调参旋钮 | 同批敌人生成角度偏移范围 |
| `max_spawn_retries` | int | 1-10 | 调参旋钮 | 位置重试次数上限 |
| `arena_rect` | Rect2 | — | 竞技场配置 | 竞技场边界矩形 |

## Edge Cases

| 场景 | 预期行为 | 理由 |
|------|---------|------|
| 玩家贴墙时生成敌人 | 部分生成点可能超出边界，修正到边界内 | 竞技场边界修正保证有效 |
| 修正后距玩家 < `spawn_min_distance` | 重新随机位置（最多重试 3 次） | 防止敌人生成在玩家脚下 |
| 3 次重试均失败 | 在竞技场边缘随机位置生成 | 保底策略，确保敌人一定能生成 |
| `count` 为 0 | 不执行任何操作，不发出信号 | 空生成无意义 |
| `enemy_type` 不在映射表中 | 断言失败，拒绝生成 | 非法类型属于配置错误 |
| 一次生成大量敌人（如 20 个） | 同批敌人在不同角度偏移位置生成，可能部分重叠 | 无同屏上限，位置分散但不保证完全不重叠 |
| 玩家在竞技场正中央 | 生成点均匀分布在周围环形区域 | 理想情况，无边界问题 |
| 竞技场极小，`spawn_min_distance` 大于竞技场半径 | 大部分生成点需要修正，重试概率高 | 竞技场尺寸与生成距离需匹配，属于配置约束 |
| `spawn_enemies()` 在同一帧被调用多次 | 每次调用独立执行，所有敌人在同一帧生成 | 无状态系统，不排队 |
| 敌人场景文件缺失 | 启动时断言失败，提示缺少场景文件 | 资源缺失属于构建错误 |

## Dependencies

| 依赖系统 | 方向 | 依赖内容 | 状态 |
|---------|------|---------|------|
| 波次系统 | 上游 → 本系统 | 调用 `spawn_enemies()` 触发生成，提供 enemy_type / count / wave_number | GDD 未设计 |
| 敌人 AI 系统 | 本系统 → 下游 | 创建敌人实例后，敌人自动进入 AI 的 SPAWN 状态 | GDD 已通过 ✅ |
| 玩家移动系统 | 本系统读取 | 读取玩家 `global_position` 计算生成位置 | GDD 已通过 ✅ |
| 生命/伤害系统 | 间接 | 敌人 HP/受伤由该系统管理，本系统只创建不跟踪 | GDD 已通过 ✅ |
| 竞技场/地图系统 | 本系统读取 | 读取 `arena_rect: Rect2` 作为边界约束 | GDD 未设计 |

**双向依赖说明**：
- 波次系统的 GDD 必须确认 `spawn_enemies()` 接口和 `wave_spawn_complete` 信号
- 竞技场系统必须提供 `arena_rect`，否则本系统无法做边界修正

**阻塞关系**：本系统可以被实现，但 `arena_rect` 需要竞技场系统提供临时默认值，波次系统接口为临时定义，待其 GDD 确认后可能调整参数。

## Tuning Knobs

| 旋钮 | 类型 | 默认值 | 安全范围 | 影响玩法 | 说明 |
|------|------|--------|---------|---------|------|
| `spawn_min_distance` | float | 200 px | 100–400 px | 敌人出现时机感 | 过小会让敌人"贴脸生成"，过大则玩家看不到敌人出现 |
| `spawn_max_distance` | float | 400 px | 200–600 px | 战斗空间感知 | 需 > `spawn_min_distance`，过大敌人在视野外，过小包围感太强 |
| `spawn_angle_spread` | float | 30° | 0–90° | 同批敌人分散度 | 0° = 完全重叠，90° = 半圆分散，影响玩家是否需要多方向应对 |
| `max_spawn_retries` | int | 3 | 1–10 | 生成可靠性 | 重试越多位置越安全，但单帧计算开销增加（MVP 场景下可忽略） |

**配置方式**：所有旋钮定义在 `assets/data/spawn_config.tres`（Resource 文件），运行时加载，支持热重载调参。

**约束**：`spawn_max_distance` 必须 > `spawn_min_distance`，启动时断言校验。

## Visual/Audio Requirements

**视觉**：
- 敌人生成时播放 0.3s 浮现动画（从透明到不透明），对应敌人 AI 的 SPAWN 状态时长
- 浮现动画由敌人场景内部实现，本系统不控制动画内容，只触发敌人实例化
- 无额外生成特效（MVP 不需要地面光圈/粒子等）

**音频**：
- 每次调用 `spawn_enemies()` 播放一次生成音效（不论本次生成多少敌人）
- 音效为短促的"出现"提示音，让玩家感知新敌人到来
- 音效资源路径：`assets/audio/sfx/enemy_spawn.ogg`
- 多次快速调用时允许音效重叠，不做防重复

**备注**：本系统只负责触发（实例化敌人 + 播放音效），浮现动画细节由敌人 AI 系统 SPAWN 状态定义，视觉特效可在后续迭代中扩展。

## UI Requirements

**MVP 阶段：无专属 UI**。

本系统不直接驱动任何 UI 元素。敌人数量显示、波次信息等由波次系统和统计系统负责。本系统唯一的间接 UI 关联是通过 `wave_spawn_complete` 信号通知统计系统"本波生成了多少敌人"，由统计系统决定如何展示。

**后续迭代可扩展**：
- 敌人生成时的方向指示器（屏幕边缘箭头提示视野外敌人）——属于 HUD 系统，非本系统职责

## Acceptance Criteria

| 编号 | 标准 | 验证方式 |
|------|------|---------|
| AC-1 | 调用 `spawn_enemies("melee", 3, 1)` 后场景树中出现 3 个近战敌人 | 单元测试：断言场景树新增 3 个敌人节点 |
| AC-2 | 所有生成敌人的位置在 `arena_rect` 内 | 单元测试：断言每个敌人 `position` 在 Rect2 范围内 |
| AC-3 | 所有生成敌人的位置距玩家 ≥ `spawn_min_distance` | 单元测试：断言距离 >= 200px |
| AC-4 | 所有生成敌人的位置距玩家 ≤ `spawn_max_distance` | 单元测试：断言距离 <= 400px |
| AC-5 | 同批多个敌人位置不完全重叠（角度有偏移） | 单元测试：生成 5 个敌人，断言至少 3 个位置互不相同 |
| AC-6 | 玩家贴墙时生成的敌人仍在竞技场内 | 单元测试：设置玩家位置在边界，验证边界修正生效 |
| AC-7 | `count` 为 0 时不生成敌人、不发出信号 | 单元测试：断言无新节点、无信号 |
| AC-8 | 非法 `enemy_type` 不生成敌人并报错 | 单元测试：断言传入不存在类型时推错 |
| AC-9 | 生成完成后发出 `wave_spawn_complete` 信号，携带实际生成数量 | 单元测试：监听信号，断言参数正确 |
| AC-10 | 每次生成播放一次音效 | 手动验证 / 集成测试 |

## Open Questions

1. **波次系统接口确认**：`spawn_enemies()` 的参数和 `wave_spawn_complete` 信号是否最终确认？待波次系统 GDD 设计时对齐。
2. **竞技场 rect 来源**：`arena_rect` 由竞技场/地图系统提供，该系统 GDD 未设计。MVP 阶段可硬编码一个固定矩形，但正式版需要动态获取。
3. **生成音效与浮现动画同步**：音效由本系统触发，动画由敌人 AI SPAWN 状态驱动，两者是否需要精确同步？MVP 阶段允许微小偏差。
4. **同屏敌人过多时的性能策略**：当前无同屏上限，后期是否需要增加屏幕外敌人休眠或降级策略？MVP 阶段敌人数量有限（每波 ≤20），暂不处理。
