# 输入系统 (Input System)

> **Status**: Approved
> **Author**: user + agents
> **Last Updated**: 2026-04-23
> **Implements Pillar**: 操作感即玩法、每一秒都在做选择

## Overview

输入系统是所有玩家操作的入口，负责将键盘/鼠标和游戏手柄的原始输入转化为标准化的动作信号。它管理 7 个核心动作映射（移动、近战攻击、远程攻击、闪避、交互、暂停、升级界面），为移动系统提供原始的 `move_vector: Vector2`（范围 -1 到 1），为战斗和闪避系统提供攻击持续信号（`is_pressed`）和动作触发信号（`just_pressed`）。系统基于 Godot 内置的 Input Map 实现，支持键盘+鼠标和游戏手柄两套方案无缝切换，无需代码修改。输入系统本身没有上游依赖，是整个游戏控制链的最底层——没有它，移动、战斗、闪避都无法响应玩家操作。

## Player Fantasy

你按下 W 的瞬间，角色已经启动——没有延迟、没有犹豫，就像你的手指直接牵着角色一样。左手 WASD 控制走位，右手鼠标控制战斗：左键近战挥砍、右键远程射击、空格键随时闪避，整套操作流畅自然。你换上手柄，摇杆推动的方向被完美捕捉，肩键和扳机对应近战、远程、闪避，手感无缝衔接。按下闪避的一刹那无敌帧启动，不多不少。这个系统让你忘记"输入"的存在——你的想法直接变成屏幕上的动作。

## Detailed Design

### Core Rules

1. **动作映射（Godot Input Map）**
   - 在 `project.godot` 中定义 7 个 Input Action：
     - `move_up`、`move_down`、`move_left`、`move_right`（4 方向离散按键）
     - `melee_attack`、`ranged_attack`、`dodge`、`interact`、`pause`、`upgrade`（离散动作）
   - 每个 Action 绑定两套设备输入：键盘键位 + 手柄按键/摇杆

2. **按键绑定表**

   | 动作 | 键盘+鼠标 | 手柄 | 输出类型 |
   |------|----------|------|---------|
   | 移动 | WASD / 方向键 | 左摇杆（轴） | Vector2（连续） |
   | 近战攻击 | 鼠标左键 | X / A | is_pressed（持续） |
   | 远程攻击 | 鼠标右键 | RT / R2 | is_pressed（持续） |
   | 闪避 | 空格键 | B / 圈 | just_pressed |
   | 交互 | E 键 | Y / 三角 | just_pressed |
   | 暂停 | Esc 键 | Start / Options | just_pressed |
   | 升级界面 | Tab 键 | Back / Select | just_pressed |

3. **移动向量计算**
   - 每帧读取 4 个方向按键状态（或左摇杆轴值），合成 `raw_vector: Vector2`：
     - 水平分量：`move_right` 按下为 +1，`move_left` 按下为 -1，同时按下为 0
     - 垂直分量：`move_down` 按下为 +1，`move_up` 按下为 -1，同时按下为 0
     - 手柄左摇杆直接读取轴值（-1 到 1）
   - 键盘输入时 `raw_vector` 分量只可能是 -1、0、+1；手柄摇杆输入时可以是任意浮点值
   - 两套设备同时激活，取**非零优先**：如果键盘有非零输入，使用键盘值；否则使用手柄值
   - 最终输出 `move_vector: Vector2`，范围 (-1,-1) 到 (1,1)，**未归一化**（由移动系统负责归一化和 8 方向吸附）
   - 当 `move_vector` 长度 < `deadzone`（默认 0.1）时，输出 `(0, 0)`

4. **离散动作信号**
   - 近战攻击和远程攻击使用 `Input.is_action_pressed(action_name)`（持续检测）：
     - 每帧检查攻击键是否按住，按住就向战斗系统发送攻击信号
     - 实际攻击频率（如近战 0.5s 一次挥砍、远程 0.3s 一发子弹）由战斗系统的冷却/攻速控制
     - 输入系统只传递"攻击意图"，不控制攻击节奏
   - 其他离散动作（闪避、交互、暂停、升级）使用 `Input.is_action_just_pressed(action_name)`：
     - `just_pressed` 为单帧事件：按键按下的那一帧返回 `true`，之后返回 `false` 直到松开再按下
     - 不做输入缓冲——快速连按时只触发一次，不积累
   - 所有按键（包括鼠标左键和右键）统一通过 `is_action_pressed()` / `is_action_just_pressed()` 轮询，不使用 `_input(event)` 事件回调

5. **设备检测与优先级**
   - 两套输入方案始终激活，不需要手动切换
   - 移动向量：键盘非零优先，否则使用手柄（见规则 3）
   - 离散动作：任意设备触发即响应（键盘或手柄按下近战键都触发近战）

6. **输入暂停行为**
   - 游戏暂停时（`get_tree().paused = true`），输入系统停止读取所有输入
   - `pause` 动作本身例外——通过 `Input` 全局函数直接读取，不受场景暂停影响
   - **Godot 实现提示**：在 Project Settings → Input Map 中，`pause` Action 不需要额外配置（Godot 的 `Input.is_action_just_pressed()` 不受 SceneTree 暂停影响）；若使用 `Node._input()`，需将节点的 `process_mode` 设为 `PROCESS_MODE_ALWAYS`

7. **当前主输入设备检测**
   - 每帧根据最后一帧产生非零输入的设备更新 `current_input_device`：
     - 键盘有非零方向输入或任意键盘 Action 被按下 → `"keyboard"`
     - 手柄摇杆超过死区或任意手柄 Action 被按下 → `"gamepad"`
     - 无输入时保持上一次的 device 值
   - 用于 UI 显示当前操作设备图标和 Visual/Audio Requirements 中的设备切换提示

8. **每帧执行流程**
   - 读取 4 方向按键/摇杆 → 合成 `move_vector` → 应用死区 → 输出给移动系统
   - 检查攻击键 `is_pressed` 和其他离散动作 `just_pressed` → 触发对应信号 → 下游系统响应
   - 更新 `current_input_device` → 输出给 UI 系统

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| `ACTIVE` | 游戏运行中，未暂停 | 游戏暂停 | 每帧读取输入，输出 move_vector 和动作信号 |
| `PAUSED` | 游戏暂停 | 游戏恢复 | 仅响应 `pause` 动作，忽略其他所有输入 |

- 状态转换由游戏状态管理系统控制（MVP 阶段可由任意节点调用 `get_tree().paused`）

### Interactions with Other Systems

| 交互系统 | 方向 | 接口说明 |
|---------|------|---------|
| 玩家移动系统 | 本系统 → 移动 | 提供 `move_vector: Vector2`（-1 到 1，未归一化）；移动系统负责归一化和速度计算 |
| 混合战斗系统 | 本系统 → 战斗 | 提供 `melee_attack` 和 `ranged_attack` 的 is_pressed 信号（持续） |
| 闪避系统 | 本系统 → 闪避 | 提供 `dodge` 的 just_pressed 信号 |
| 游戏状态管理 | 本系统 ↔ 状态 | 提供 `pause` 和 `upgrade` 信号；状态系统控制 ACTIVE/PAUSED 切换 |

## Formulas

### 移动向量合成

```
# 键盘方向合成
keyboard_x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
keyboard_y = int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))
keyboard_vector = Vector2(keyboard_x, keyboard_y)

# 手柄摇杆直接读取
# 注意：不使用 Input.get_vector() 的内置环形死区，而是手动线性死区以保持与键盘行为一致
gamepad_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")

# 非零优先：键盘有输入时用键盘，否则用手柄
if keyboard_vector != Vector2.ZERO:
    move_vector = keyboard_vector
else:
    move_vector = gamepad_vector

# 死区过滤
if move_vector.length() < deadzone:
    move_vector = Vector2.ZERO
```

### 变量表

| 变量 | 类型 | 范围 | 来源 | 说明 |
|------|------|------|------|------|
| `keyboard_x` | int | -1, 0, 1 | 键盘 WASD/方向键 | 水平方向键盘输入 |
| `keyboard_y` | int | -1, 0, 1 | 键盘 WASD/方向键 | 垂直方向键盘输入 |
| `keyboard_vector` | Vector2 | (-1,-1) 到 (1,1) | 计算 | 键盘合成移动向量 |
| `gamepad_vector` | Vector2 | (-1,-1) 到 (1,1) | 手柄左摇杆 | 手柄摇杆原始轴值 |
| `move_vector` | Vector2 | (-1,-1) 到 (1,1) | 输出 | 最终输出的移动向量（未归一化） |
| `deadzone` | float | 0.0-0.3 | 调参旋钮 | 摇杆死区阈值 |

> **注意**：`move_vector` 是**未归一化**的。移动系统接收后负责归一化和 8 方向吸附。

### 攻击信号节律（MVP 阶段未启用）

```
# 如果 attack_repeat_interval > 0，控制攻击信号发送频率
if Input.is_action_pressed("melee_attack"):
    if attack_repeat_interval == 0 or time_since_last_melee_signal >= attack_repeat_interval:
        send_melee_signal()
        time_since_last_melee_signal = 0.0
```

> MVP 阶段 `attack_repeat_interval = 0`，每帧直接发送攻击信号，由战斗系统冷却控制节奏。

### 当前主输入设备检测

```
# 每帧更新当前主操作设备
if keyboard_vector != Vector2.ZERO or any_keyboard_action_pressed:
    current_input_device = "keyboard"
elif gamepad_vector.length() >= deadzone or any_gamepad_action_pressed:
    current_input_device = "gamepad"
# 无输入时保持上一次的 device 值
```

## Edge Cases

| 场景 | 预期行为 | 理由 |
|------|---------|------|
| 同时按下 W 和 S（相反方向） | `keyboard_y = 0`，`move_vector = (0, 0)`，不移动 | 输入自然抵消 |
| 同时按下 W 和 D（对角线） | `move_vector = (1, -1)`，长度 ≈ 1.414 | 输出未归一化，由移动系统处理 |
| 手柄摇杆轻微漂移（0.05） | 低于 deadzone 0.1，输出 `(0, 0)` | 防止漂移导致意外移动 |
| 快速连按近战键（一帧内多次） | 每帧检测 `is_pressed`，按住期间每帧发送攻击信号 | 攻击频率由战斗系统冷却控制 |
| 按住近战键不放 | 每帧输出 `melee_attack = true`，持续发送攻击信号 | 按住持续攻击，频率由战斗系统控制 |
| 同时用键盘和手柄输入不同方向 | 键盘非零优先，忽略手柄 | 避免两套设备冲突 |
| 游戏暂停期间按近战键 | 近战信号被忽略，只有 `pause` 动作响应 | 暂停期间不应触发战斗 |
| 鼠标移出游戏窗口 | 不触发任何行为，鼠标按键仍需窗口焦点 | 防止误触 |
| 玩家死亡后按移动键 | 输入系统仍输出 `move_vector`，但移动系统不响应 | 输入系统不感知死亡状态，由下游系统过滤 |
| 手柄断开连接 | 手柄输入自动归零，键盘仍可正常使用 | Godot Input Map 自动处理 |
| 暂停期间按 Esc 键 | `pause` 动作正常响应，解除暂停 | pause 不受场景暂停影响 |

## Dependencies

| 系统 | 方向 | 性质 |
|------|------|------|
| 无上游依赖 | — | Foundation 层，不需要任何其他系统 |
| 玩家移动系统 | 本系统 → 移动 | 硬依赖：提供 `move_vector: Vector2` |
| 混合战斗系统 | 本系统 → 战斗 | 硬依赖：提供 `melee_attack` 和 `ranged_attack` 的 is_pressed 信号 |
| 闪避系统 | 本系统 → 闪避 | 硬依赖：提供 `dodge` 的 just_pressed 信号 |
| 游戏状态管理 | 本系统 ↔ 状态 | 软依赖：提供 `pause`/`upgrade` 信号；接收 ACTIVE/PAUSED 状态切换 |

## Tuning Knobs

| 参数 | 当前值 | 安全范围 | 调高效果 | 调低效果 |
|------|--------|----------|---------|---------|
| `deadzone` | 0.1 | 0.0-0.3 | 更宽容，防止摇杆漂移误触 | 更灵敏，摇杆漂移可能导致意外移动 |
| `attack_repeat_interval` | 0.0s | 0.0-0.5s | 攻击信号发送间隔增大（防重复触发） | 每帧发送，由战斗系统冷却控制 |

> **注意**：`attack_repeat_interval` 控制输入系统向战斗系统发送攻击信号的最小间隔。设为 0 时每帧发送（攻击频率完全由战斗系统控制），设为非零值时可降低信号频率。MVP 阶段建议保持 0。

## Visual/Audio Requirements

输入系统本身不产生视觉/音频反馈——反馈由下游系统（移动、战斗、闪避）负责。以下情况例外：

| 事件 | 视觉反馈 | 音频反馈 | 说明 |
|------|---------|---------|------|
| 设备切换（首次检测到手柄输入） | 屏幕右下角短暂提示"手柄已连接"图标 | 短促确认音 | 仅首次检测时触发 |

## UI Requirements

输入系统不直接渲染 HUD，但需要为 UI 系统暴露：

| 数据 | 类型 | 用途 |
|------|------|------|
| `current_input_device` | String（"keyboard"/"gamepad"） | UI 显示当前主操作设备图标 |
| `is_any_input_active` | bool | UI 判断是否有输入设备活跃 |

## Acceptance Criteria

- [ ] 只按 W 键时，`move_vector` 输出 `(0, -1)`
- [ ] 同时按 W+D 时，`move_vector` 输出 `(1, -1)`，长度 ≈ 1.414
- [ ] 同时按 W+S 时，`move_vector` 输出 `(0, 0)`
- [ ] 松开所有移动键后，`move_vector` 输出 `(0, 0)`
- [ ] 手柄左摇杆推到右上极限时，`move_vector` 输出接近 `(1, -1)`
- [ ] 手柄摇杆漂移值 0.05 时，`move_vector` 输出 `(0, 0)`（deadzone 0.1）
- [ ] 按住鼠标左键期间，每帧 `melee_attack` 信号为 `true`
- [ ] 松开鼠标左键后，`melee_attack` 信号为 `false`
- [ ] 按空格键一次，`dodge` 的 `just_pressed` 仅在按下那一帧返回 `true`
- [ ] 按住空格键不放，`dodge` 的 `just_pressed` 只在第一帧返回 `true`，后续帧为 `false`
- [ ] 同时用键盘 W 和手柄左摇杆下方向，`move_vector` 输出 `(0, -1)`（键盘优先）
- [ ] 游戏暂停后按 W 键，`move_vector` 输出 `(0, 0)`
- [ ] 游戏暂停后按 Esc 键，`pause` 的 `just_pressed` 返回 `true`
- [ ] 输入系统的 `_process` 每帧执行时间 < 0.1ms

## Open Questions

1. **鼠标瞄准与战斗系统的接口** — 当前输入系统只输出攻击信号，不涉及瞄准方向。如果战斗系统需要鼠标位置/瞄准角度，输入系统是否需要额外提供 `aim_direction: Vector2`？待战斗系统设计时确认。

2. **手柄摇杆死区曲线类型** — 当前使用线性死区（`length < deadzone`）。环形死区手感更平滑但计算更复杂。MVP 阶段先用线性，playtest 后评估。

3. **按键重映射功能** — MVP 阶段不支持按键重映射。v1.0 阶段是否需要可自定义按键绑定？

4. **游戏手柄振动反馈** — 手柄受击/闪避/命中等事件是否需要振动反馈？MVP 阶段不做，v1.0 评估。
