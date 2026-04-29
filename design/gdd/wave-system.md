# 波次系统 (Wave System)

> **Status**: Approved
> **Author**: user + agents
> **Last Updated**: 2026-04-27
> **Implements Pillar**: 每一秒都在做选择、死亡有意义、小而深

## Overview

波次系统是游戏节奏的指挥官。它决定敌人何时来、来多少、来什么类型，以及何时暂停战斗让玩家升级。每一波由本系统触发敌人生成、等待清场、判断完成，然后决定下一波或触发升级窗口。本系统不控制敌人行为（由 AI 系统驱动），不控制升级内容（由升级池系统驱动），它只做一件事：**编排"战斗-清场-升级"的节奏循环**。

## Player Fantasy

你刚清完第 3 波，屏幕中央弹出升级选择——三选一，你快速挑了近战伤害。还没来得及回味，第 4 波已经开始，这次敌人更多了，而且混入了远程型。你一边闪避一边数：还剩大概 5 个，能撑住。第 5 波结束了，你喘口气，等下一波来——但这次没有升级窗口，下一波直接开始，难度又上了一档。你意识到节奏在加速，升级窗口是珍贵的喘息，不是每波都有。

## Detailed Design

### 1. 波次状态机

本系统维护一个状态机控制波次循环：

```
IDLE → WAVE_ACTIVE → WAVE_CLEARED → (UPGRADE_WINDOW 或) → IDLE
```

| 状态 | 说明 | 转换条件 |
|------|------|---------|
| IDLE | 等待开始 | 接收到游戏开始信号 → WAVE_ACTIVE |
| WAVE_ACTIVE | 本波敌人生成中/战斗中 | 所有敌人被击杀 → WAVE_CLEARED |
| WAVE_CLEARED | 本波完成，判断是否升级 | 需要升级 → UPGRADE_WINDOW；否则 → 短暂延迟后回 IDLE |
| UPGRADE_WINDOW | 升级选择界面显示中 | 玩家确认选择 → 短暂延迟后回 IDLE |

### 2. 波次配置

每波的敌人配置由 `WaveConfig` Resource 定义：

| 字段 | 类型 | 说明 |
|------|------|------|
| `wave_number` | int | 波次编号 |
| `melee_count` | int | 近战敌人数量 |
| `ranged_count` | int | 远程敌人数量 |
| `spawn_delay` | float | 敌人生成间隔（秒） |

MVP 波次配置（5 波）：

| 波次 | 近战 | 远程 | 生成间隔 | 升级窗口？ |
|------|------|------|---------|-----------|
| 1 | 3 | 0 | 0.5s | 否 |
| 2 | 4 | 1 | 0.5s | 否 |
| 3 | 4 | 2 | 0.4s | ✅ 第 3 波后升级 |
| 4 | 5 | 3 | 0.4s | 否 |
| 5 | 6 | 4 | 0.3s | ✅ 第 5 波后升级 |

第 5 波后循环回第 5 波配置但 `melee_count` +2、`ranged_count` +1，持续递增（无尽模式）。

### 3. 波次循环流程

1. 进入 IDLE → 自增 `current_wave`，发出 `wave_started(current_wave)` 信号
2. 调用敌人生成系统的 `spawn_enemies("melee", melee_count, current_wave)` 和 `spawn_enemies("ranged", ranged_count, current_wave)`
3. 进入 WAVE_ACTIVE，等待本波所有敌人被击杀
4. 击杀判定：追踪本波生成的敌人总数 vs 击杀数，两者相等时进入 WAVE_CLEARED
5. WAVE_CLEARED → 判断是否触发升级窗口（每 `upgrade_interval` 波触发一次，默认 3 波）
6. 如需升级：发出 `upgrade_window_requested()` 信号，等待局内升级系统回复 `upgrade_completed()`
7. 如不需升级：等待 `post_wave_delay`（默认 2.0s）后回到步骤 1

### 4. 波次完成判定

- 本系统自行追踪 `enemies_spawned_this_wave` 和 `enemies_killed_this_wave`
- 敌人生成系统发出 `wave_spawn_complete(count)` 时累加 `enemies_spawned_this_wave`
- 收到生命/伤害系统的 `enemy_killed` 信号时累加 `enemies_killed_this_wave`
- 当 `enemies_killed_this_wave == enemies_spawned_this_wave` 时判定波次完成

### 5. 无尽模式递增

- 超过配置的最大波次（5）后，沿用最后一波配置并递增
- 每次循环：`melee_count += 2`，`ranged_count += 1`
- 无上限，直到玩家死亡

### 6. 对外接口

| 方法/信号 | 类型 | 说明 |
|----------|------|------|
| `start_run()` | 方法 | 开始新一轮，重置波次并启动第 1 波 |
| `wave_started(wave_number: int)` | 信号 | 通知新波次开始 |
| `wave_cleared(wave_number: int)` | 信号 | 通知波次完成 |
| `upgrade_window_requested()` | 信号 | 请求局内升级系统显示升级界面 |
| `upgrade_completed()` | 方法 | 局内升级系统通知升级选择完成 |
| `run_ended()` | 信号 | 玩家死亡，通知所有系统停止 |

## Formulas

### 升级窗口触发判定

```
# 每 upgrade_interval 波触发一次升级
should_upgrade = (current_wave % upgrade_interval == 0) and (current_wave > 0)
# 默认 upgrade_interval = 3
# 波次 3、6、9、12... 触发升级
```

### 无尽模式敌人数量递增

```
# 波次 > max_configured_wave 时
loop_count = current_wave - max_configured_wave
melee_count = base_melee + loop_count * INFINITE_MELEE_INCREMENT   # +2
ranged_count = base_ranged + loop_count * INFINITE_RANGED_INCREMENT # +1
```

### 变量表

| 变量 | 类型 | 范围 | 来源 | 说明 |
|------|------|------|------|------|
| `upgrade_interval` | int | 2-5 | 调参旋钮 | 每几波触发一次升级 |
| `post_wave_delay` | float | 1.0-5.0 s | 调参旋钮 | 波次间暂停时长 |
| `INFINITE_MELEE_INCREMENT` | int | 1-5 | 调参旋钮 | 无尽模式每轮近战敌人增量 |
| `INFINITE_RANGED_INCREMENT` | int | 1-3 | 调参旋钮 | 无尽模式每轮远程敌人增量 |
| `base_melee` | int | — | 波次配置 | 最后一波配置的近战数量 |
| `base_ranged` | int | — | 波次配置 | 最后一波配置的远程数量 |

## Edge Cases

| 场景 | 预期行为 | 理由 |
|------|---------|------|
| 玩家在 WAVE_ACTIVE 中死亡 | 停止状态机，发出 `run_ended()` 信号，不再生成新波次 | 死亡即结束，不继续循环 |
| 波次中敌人全部被击杀的同一帧有新生成 | 击杀判定在所有生成完成之后才检查 | 生成系统先发 `wave_spawn_complete`，再比较击杀数 |
| 升级窗口期间玩家收到伤害 | 升级窗口不暂停游戏，敌人仍可攻击 | MVP 不做暂停，升级时仍有风险，增加紧张感 |
| `upgrade_completed()` 未被调用（UI 故障） | 设置超时（默认 30s），超时后自动关闭升级窗口继续下一波 | 防止游戏卡死 |
| `start_run()` 在已有波次进行中被调用 | 重置所有状态，从第 1 波重新开始 | 新一局覆盖旧状态 |
| 第 5 波后无尽模式持续数十轮 | 敌人数量持续增长，无软上限 | 由性能和设计侧控制，代码不做限制 |
| 波次配置文件缺失某波次 | 断言失败，提示配置缺失 | 波次配置不完整属于构建错误 |
| 敌人生成系统生成数量少于请求数量 | 按实际生成数量追踪，不等请求数量 | 以实际生成为准，避免死等 |

## Dependencies

| 依赖系统 | 方向 | 依赖内容 | 状态 |
|---------|------|---------|------|
| 敌人生成系统 | 本系统 → 下游 | 调用 `spawn_enemies()` 触发每波敌人生成 | GDD 已通过 ✅ |
| 敌人生成系统 | 下游 → 本系统 | 发出 `wave_spawn_complete` 信号通知实际生成数量 | GDD 已通过 ✅ |
| 生命/伤害系统 | 上游 → 本系统 | 发出 `enemy_killed` 信号用于波次完成判定 | GDD 已通过 ✅ |
| 分数/统计系统 | 本系统 → 下游 | 发出 `wave_started` 信号通知波次进度 | GDD 已通过 ✅ |
| 升级池/数据系统 | 间接 | 局内升级系统调用 `draw_upgrades()`，本系统不直接交互 | GDD 已通过 ✅ |
| 局内升级系统 | 双向 | 本系统发出 `upgrade_window_requested`，局内升级回复 `upgrade_completed()` | GDD 未设计 |

**双向依赖说明**：
- 局内升级系统的 GDD 需确认 `upgrade_window_requested` / `upgrade_completed()` 的交互协议
- 生命/伤害系统的 `enemy_killed` 信号被本系统和分数/统计系统同时监听，需确保信号可多播

## Tuning Knobs

| 旋钮 | 类型 | 默认值 | 安全范围 | 影响玩法 | 说明 |
|------|------|--------|---------|---------|------|
| `upgrade_interval` | int | 3 | 2–5 | 升级频率 | 每 2 波升级节奏快成长感强，每 5 波升级节奏慢压迫感强 |
| `post_wave_delay` | float | 2.0 s | 1.0–5.0 s | 喘息时长 | 波次间暂停，给玩家短暂整理时间 |
| `upgrade_timeout` | float | 30.0 s | 10.0–60.0 s | 升级安全网 | 升级窗口超时自动关闭，防止卡死 |
| `INFINITE_MELEE_INCREMENT` | int | 2 | 1–5 | 无尽难度曲线 | 每轮近战增量，越大后期越压迫 |
| `INFINITE_RANGED_INCREMENT` | int | 1 | 1–3 | 无尽难度曲线 | 每轮远程增量，远程太多可能失控 |

**配置方式**：旋钮定义在 `assets/data/wave_config.tres`（Resource 文件），波次序列定义在 `assets/data/wave_sequences/` 目录下的 `WaveConfig` 资源数组，运行时加载。

**备注**：波次配置本身（每波敌人数量）也是重要的调参内容，但属于内容设计而非代码旋钮，直接编辑 `WaveConfig` 资源文件即可。

## Visual/Audio Requirements

**视觉**：
- 波次开始时屏幕上方短暂显示波次编号（如 "Wave 3"），持续 2 秒后淡出——由战斗 HUD 实现
- 本系统通过 `wave_started` 信号触发 HUD 显示，不自行渲染

**音频**：
- 波次开始时播放"新波次"提示音——由音效系统实现，本系统不直接播放
- 升级窗口触发时可播放提示音——由局内升级系统实现

**备注**：本系统是逻辑编排层，所有视听反馈通过信号委托给下游系统实现。

## UI Requirements

**MVP 阶段：本系统无专属 UI**。

本系统不直接驱动任何界面。波次信息展示由战斗 HUD 负责：

- **波次编号显示**：HUD 监听 `wave_started` 信号，显示当前波次
- **波次完成提示**：HUD 监听 `wave_cleared` 信号，可选显示"波次清除"
- **升级选择界面**：由局内升级系统负责，本系统只发出 `upgrade_window_requested` 触发

## Acceptance Criteria

| 编号 | 标准 | 验证方式 |
|------|------|---------|
| AC-1 | `start_run()` 后发出 `wave_started(1)` 信号 | 单元测试：监听信号，断言 wave_number=1 |
| AC-2 | 第 1 波生成 3 个近战、0 个远程敌人 | 单元测试：验证 `spawn_enemies` 调用参数 |
| AC-3 | 本波所有敌人击杀后发出 `wave_cleared` 信号 | 单元测试：模拟 spawn_complete + N 次 enemy_killed，断言信号触发 |
| AC-4 | 第 3 波清除后发出 `upgrade_window_requested` 信号 | 单元测试：推进到第 3 波清除，断言升级信号触发 |
| AC-5 | 第 2 波清除后不发出升级信号 | 单元测试：推进到第 2 波清除，断言无升级信号 |
| AC-6 | `upgrade_completed()` 调用后开始下一波 | 单元测试：触发升级→调用 completed→断言 wave_started(N+1) |
| AC-7 | 升级窗口超时后自动继续下一波 | 单元测试：触发升级→等待超时→断言自动继续 |
| AC-8 | 玩家死亡后发出 `run_ended` 信号，不再生成新波次 | 单元测试：模拟死亡，断言信号发出且状态机停止 |
| AC-9 | 第 6 波（无尽模式）近战=8、远程=5 | 单元测试：推进到第 6 波，断言敌人数量计算正确 |
| AC-10 | `start_run()` 在已有波次中调用后从第 1 波重新开始 | 单元测试：中途调用 start_run，断言 current_wave=1 |

## Open Questions

1. **升级窗口是否暂停游戏**：MVP 不暂停，升级期间仍可受伤。但这是否会让玩家不敢慢慢选？需 playtest 验证，后续可加半速或暂停选项。
2. **波次间是否自动开始**：当前设计是 `post_wave_delay` 后自动开始下一波。是否需要玩家按键确认？自动开始节奏更好，但新手可能觉得仓促。
3. **局内升级系统交互协议**：`upgrade_window_requested` / `upgrade_completed()` 的交互需在局内升级系统 GDD 中确认，特别是错误处理和超时行为。
4. **波次配置热重载**：开发时是否需要支持运行时修改波次配置并即时生效？对调参效率影响大，但增加实现复杂度。
5. **多人远程敌人上限**：无尽模式远程敌人持续增长可能导致弹幕密度失控。是否需要对远程敌人设置独立上限？MVP 暂不处理。
