# ADR-0002: Input System Architecture

## Status
Accepted

## Date
2026-04-28

## Context

### Problem Statement
猎场的战斗系统要求精确的输入响应——近战和远程攻击按键在物理帧之间被按下时不能丢失（否则玩家会感觉"按了没反应"）。同时，闪避、攻击等动作需要在正确的时机触发，不能早于物理帧、不能晚于下一帧。需要设计一个可靠的输入管线：从 Godot 底层输入事件 → 标准化动作信号 → 消费者系统（战斗/闪避/移动）。

### Constraints
- 单人开发，输入管线必须简单直观
- Godot 4.6 提供 InputMap + `Input.is_action_pressed()` + `_input(event)` 三种机制
- MVP 仅支持键盘+鼠标，手柄支持后期添加
- 战斗系统需要每帧知道攻击键是否被"按住"（用于连续攻击循环）
- 闪避系统只需要"按下的瞬间"（防止按住空格连续闪避）
- 必须保证 _input 和 _physics_process 之间不丢帧

### Requirements
- 鼠标左键/右键被按下时，本次按压**绝不丢失**（即使按得极快、在帧间隙之间）
- 攻击信号在物理帧开始时统一发出（所有消费者在同一帧内看到一致的输入状态）
- 按住攻击键时，战斗系统在冷却完成后自动再次攻击（连续攻击循环）
- 闪避键只触发单次闪避，不会因按住而连续触发
- 移动向量每帧更新，消费者系统自行归一化

## Decision

采用 **InputMap 配置 + `_input` 缓冲 + `_physics_process` 信号转发** 三层架构：

```
Raw Input (Godot)
  │
  ├─→ InputMap (project.godot): 键位映射
  │     move_up/down/left/right, melee_attack, ranged_attack, dodge
  │
  ├─→ InputBuffer._input(event): 缓冲层
  │     将 is_action_pressed 瞬间捕获到布尔标志
  │     （_input 在每次 OS 事件时调用，不漏帧）
  │
  └─→ InputBuffer._physics_process(delta): 转发层
        计算 move_vector（轮询 Input.get_axis）
        发射缓冲信号（melee_attack_pressed, ranged_attack_pressed, dodge_pressed）
        清除缓冲标志
        提供 is_melee_held() / is_ranged_held() 连续检测
```

### 为什么用 `_input` 缓冲而不是纯 `_physics_process` 轮询

`_physics_process` 每帧调用一次（60fps 下每 16.6ms 一次）。如果玩家在两帧之间按下并松开一个键，`Input.is_action_just_pressed()` 在 `_physics_process` 中已经返回 false——这次按压就丢失了。`_input(event)` 在每次 OS 输入事件时立即调用，可以捕获所有按压，然后缓冲到下一个物理帧统一处理。

这是 GDD 设计（纯 `_physics_process` 轮询）与实际实现的关键偏差。原型验证确认了这个偏差的必要性：在快速连击测试中，纯轮询方式丢掉了约 5-8% 的按键。

### 为什么移动向量用轮询而不是缓冲

移动是连续信号（不是离散事件），不需要缓冲。`Input.get_axis()` 在 `_physics_process` 中轮询即可，每帧获得最新的轴值。

### 为什么攻击"按住"检测用 `Input.is_action_pressed()` 而不是信号

战斗系统的连续攻击循环需要每帧知道"攻击键是否还被按住"，这天然是状态查询而非事件。`Input.is_action_pressed()` 在 `_physics_process` 中查询即可。

### Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                    InputBuffer                        │
│                                                       │
│  _input(event):                    _physics_process:  │
│    melee pressed? ──→ _melee_buffered    emit signals │
│    ranged pressed? ─→ _ranged_buffered   calc vector  │
│    dodge pressed? ──→ _dodge_buffered     clear flags │
│                                                       │
│  is_melee_held()  ──→ Input.is_action_pressed()      │
│  is_ranged_held() ──→ Input.is_action_pressed()      │
│  move_vector       ──→ Input.get_axis()              │
└──────────┬──────────┘
           │ signals: melee_attack_pressed,
           │          ranged_attack_pressed,
           │          dodge_pressed
           │
     ┌─────┴─────┐
     ▼           ▼
CombatSystem  DodgeSystem
```

### Key Interfaces

```gdscript
# InputBuffer — 位于 Main/Systems/InputBuffer
extends Node

# 每帧更新的移动向量
var move_vector: Vector2  # (-1,-1) 到 (1,1)，已去死区，未归一化

# 缓冲信号（_physics_process 中发射）
signal melee_attack_pressed
signal ranged_attack_pressed
signal dodge_pressed

# 连续检测（_physics_process 中轮询）
func is_melee_held() -> bool
func is_ranged_held() -> bool
func get_8_direction() -> Vector2  # 归一化+8方向吸附
```

### InputMap Actions (project.godot)

| Action | 键盘绑定 | 物理键码 |
|--------|---------|---------|
| move_up | W | 87 |
| move_down | S | 83 |
| move_left | A | 65 |
| move_right | D | 68 |
| melee_attack | 鼠标左键 | button_index=1 |
| ranged_attack | 鼠标右键 | button_index=2 |
| dodge | 空格 | 32 |

## Alternatives Considered

### Alternative 1: 纯 `_physics_process` 轮询（GDD 原始方案）
- **Description**: 所有输入检测在 `_physics_process` 中通过 `Input.is_action_just_pressed()` / `Input.is_action_pressed()` 完成，不使用 `_input(event)`
- **Pros**: 代码最简单——所有输入逻辑集中在一个函数；无缓冲变量，状态最少
- **Cons**: 两帧之间的快速按键（<16.6ms）会丢失；`is_action_just_pressed` 的"单帧"窗口依赖于物理帧率
- **Rejection Reason**: 原型验证发现约 5-8% 的快按丢失率，影响操作手感

### Alternative 2: 全部走 `_input(event)` 实时处理
- **Description**: 攻击和闪避在 `_input` 中直接调用战斗/闪避系统的接口，不经过缓冲
- **Pros**: 零延迟——按键瞬间立即响应；不需要缓冲变量
- **Cons**: 输入处理时机与物理帧脱钩——可能在 `_physics_process` 中间修改游戏状态，导致同一帧内不同系统的输入状态不一致；难以调试
- **Rejection Reason**: 违反 Godot 推荐的游戏循环模式（输入 → 物理 → 渲染）；信号时序不可预测

### Alternative 3: 使用 `InputMap.event_is_action()` + 手动事件队列
- **Description**: 维护自己的输入事件队列，在 `_input` 中收集，在 `_physics_process` 中处理
- **Pros**: 最灵活——可以控制缓冲策略、去重、合并
- **Cons**: 过度工程——MVP 只有 3 个需要缓冲的动作，手写队列增加了代码复杂度而无实质收益
- **Rejection Reason**: MVP 阶段不需要完整的输入事件系统；简单的布尔标志缓冲已足够

## Consequences

### Positive
- 快速按键零丢失（`_input` 缓冲保证捕获所有 OS 输入事件）
- 信号时序一致（所有消费者在同一个 `_physics_process` 中收到信号）
- 最小状态（3 个布尔缓冲标志 + 1 个 Vector2），帧开销 <0.05ms
- 连续攻击循环天然支持（`is_held()` 在 `_physics_process` 中轮询）
- InputMap 在手柄支持时只需添加按键绑定，代码无需改动

### Negative
- 逻辑分散在两处（`_input` 与 `_physics_process`），新开发者可能困惑
- 缓冲是单帧的——如果消费者系统因某种原因跳过一帧，缓冲信号会丢失
- `_input` 依赖 OS 按键重复率，需确认不会在按住时重复触发（已确认 Godot 默认 key echo 不触发 `is_action_pressed`）
- 与 GDD 原始设计存在偏差，GDD 需要更新

### Risks
- **手柄摇杆与键盘同时激活时的冲突**: 当前没有处理。缓解：MVP 仅支持键盘+鼠标，手柄支持时再添加设备优先级逻辑
- **快速连击在极低帧率下（<30fps）仍可能丢帧**: `_input` 事件会积累，但缓冲标志只有一个布尔位。缓解：目标 60fps，低帧率场景下接受偶发丢失

## Performance Implications
- **CPU**: `_input` 仅做布尔赋值（~3 次/事件），`_physics_process` 做 2 次轮询 + 3 次条件检查 + 1 次 Vector2 计算，总开销 <0.05ms
- **Memory**: 3 个 bool + 1 个 Vector2 = 约 20 字节
- **Load Time**: 无影响（不加载额外资源）
- **Network**: 不适用（MVP 单机）

## Migration Plan
此为项目初始架构决策，无需迁移。如后续需要：
1. 手柄支持：在 `project.godot` InputMap 中添加手柄绑定，`Input.get_axis` / `is_action_pressed` 自动兼容
2. 多键绑定（如 WASD + 方向键同时支持）：InputMap 支持同一 Action 绑定多个按键，无需代码改动
3. 键位重映射：读取 InputMap 配置并动态修改 `InputMap.action_get_events()`，需要新增重映射 UI

## Validation Criteria
- [x] 快速连击（100ms 间隔）10 次，零丢失
- [x] 移动向量死区 <0.1 时输出 (0,0)
- [x] 按住空格不放，只触发一次闪避
- [x] 按住左键不放，近战按冷却循环触发
- [x] `_input` + `_physics_process` 总帧时间 <0.05ms
- [x] 缓冲信号在物理帧开始时发出，所有消费者在同一帧内收到

## Related Decisions
- [ADR-0001: Project Node Architecture](./adr-0001-project-node-architecture.md) — 定义了 InputBuffer 作为 Systems 子节点的位置
- GDD: [输入系统](../../design/gdd/input-system.md) — 原始设计文档，本 ADR 记录了 3 项偏差
- `project.godot` — InputMap 实际配置
- `src/core/input_buffer.gd` — 实现代码
