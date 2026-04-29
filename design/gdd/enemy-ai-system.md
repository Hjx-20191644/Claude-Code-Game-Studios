# 敌人 AI 系统 (Enemy AI System)

> **Status**: Approved
> **Author**: user + agents
> **Last Updated**: 2026-04-24
> **Implements Pillar**: 操作感即玩法、每一秒都在做选择、小而深

## Overview

敌人 AI 系统管理所有敌人的行为决策和自动操作。MVP 阶段定义两种敌人类型：**近战型**和**远程型**。近战敌人追踪玩家位置并以接触造成伤害，但不会直线冲来——它们会从侧翼包抄，迫使玩家不断调整朝向和走位。远程敌人保持与玩家的距离，在射程内射击弹体，当玩家靠近时主动闪避退开。两种敌人共享简单的直线追踪寻路（MVP 竞技场无障碍物），通过状态机控制行为切换（追踪、攻击、闪避、死亡）。敌人 AI 从移动系统读取玩家位置，从生命/伤害系统接收伤害和死亡信号，对玩家调用 `take_damage()` 造成伤害。敌人数据（速度、HP、伤害等）通过 Godot Resource 定义，支持数据驱动调整。后期计划加入 Boss 敌人——更高的血量、更大的体型、更高的伤害、击败后获得更好的奖励，具体细节待定。

## Player Fantasy

你正在处理正面涌来的近战敌人，忽然余光瞥到侧面又有两只从侧翼包抄过来——你被迫转身闪避，但正面的敌人趁机贴了上来。这就是包抄带来的压力：你永远无法只盯一个方向。远程敌人更狡猾——你想冲上去砍它，它却在你接近的瞬间侧身闪开，然后拉开距离继续射击。你开始学着预判：包抄的近战敌人什么时候到位？远程敌人闪避后往哪个方向退？当你掌握了这些规律，原本混乱的战场变成了棋盘——每个敌人都是一枚棋子，而你在读它们的步法。击杀的瞬间，敌人的死亡特效和数字弹起，你的判断得到了回报。

## Detailed Design

### Core Rules

1. **敌人数据定义**
   - 每种敌人是一个自定义 Resource 类 `EnemyData`，继承自 Godot `Resource`
   - 所有参数通过 `@export` 属性暴露，支持编辑器调整
   - 敌人数据文件存储在 `assets/data/enemies/` 目录下（`.tres` 格式）

2. **敌人类型**

   **近战型 (Melee)**:
   - 行为模式：两段式包抄——先横向移动到侧翼位置，再朝玩家冲刺
   - 伤害方式：接触即伤害（碰撞体与玩家重叠时每 `contact_damage_interval` 秒调用一次 `take_damage()`）
   - 不与敌人碰撞体互相排斥

   **远程型 (Ranged)**:
   - 行为模式：在射程内射击弹体，玩家靠近时侧向滑步闪避，拉开后继续射击
   - 射击方式：朝玩家方向发射直线弹体（与玩家远程弹体类似的 `Area2D` 节点）
   - 不与敌人碰撞体互相排斥

3. **近战型两段式包抄**
   - **阶段一（侧移）**：生成时计算侧移方向（垂直于敌人到玩家连线方向，随机选左或右），以 `flank_speed` 横向移动 `flank_distance` 距离
   - **阶段二（冲刺）**：侧移完成后，锁定玩家当前位置，以加速曲线冲向锁定位置——起步慢，中段快
     - 冲刺速度 = `charge_speed` × 加速曲线（起步 50%，中段峰值 150%）
     - 加速曲线使用 `ease(t, -2.0)` 实现（Godot 内置缓动函数），t 从 0 到 1
   - 冲刺到达目标位置后，重新评估：如果玩家在 `charge_resume_range` 内，继续追踪；否则重新进入侧移阶段
   - 侧移方向：从敌人到玩家的连线方向的垂直方向，随机选择左或右

4. **远程型射击与闪避**
   - **射击**：当与玩家距离 ≤ `shoot_range` 时，以 `shoot_interval` 间隔发射弹体，弹体沿当时玩家方向直线飞行
   - **闪避**：当与玩家距离 ≤ `evade_trigger_range` 时触发侧向滑步——以 `evade_speed` 垂直于玩家接近方向移动 `evade_distance`，滑步期间不射击
   - 滑步结束后重新评估距离，如仍在危险距离内则再次滑步（最多连续 `max_consecutive_evades` 次）
   - **逼近**：当与玩家距离 > `shoot_range` 时，以 `approach_speed` 朝玩家移动，直到进入射程

5. **寻路**
   - 所有敌人均使用直线追踪——每帧计算到玩家位置的方向向量，沿该方向移动
   - MVP 竞技场无障碍物，不需要 Navigation2D
   - 敌人被墙壁阻挡时沿墙壁滑动（与玩家相同的 `move_and_slide()` 行为）

6. **接触伤害（近战型）**
   - 近战敌人碰撞体与玩家碰撞体重叠时触发伤害
   - 调用玩家的 `take_damage(enemy_data.contact_damage, "melee", self)`
   - 伤害间隔 `contact_damage_interval`（默认 0.5s），防止每帧扣血
   - 玩家无敌帧期间不触发接触伤害

7. **击退机制**
   - 所有敌人受击时触发击退——沿远离伤害来源方向位移 `knockback_distance`
   - 击退距离 = 武器的 `knockback_value`（近战武器有击退值，远程武器默认 0）
   - 击退持续时间 = `knockback_distance / knockback_speed`，默认 `knockback_speed` = 400 px/s
   - 击退期间敌人行为中断（停止侧移/冲刺/射击/闪避），位移由击退系统控制
   - 击退结束后恢复之前的行为状态
   - 击退方向 = `(enemy_position - player_position).normalized()`
   - 近战型被击退后，如果之前在冲刺中，击退结束后重新进入侧移阶段（不继续旧冲刺）
   - 远程型被击退后，击退结束后重新评估距离决定行为

8. **敌人弹体（远程型）**
   - 弹体为 `Area2D` 节点，直线飞行
   - 弹体参数：`bullet_speed`（默认 250 px/s）、`bullet_damage`（默认 10）、`bullet_range`（默认 300px）
   - 命中玩家时调用 `take_damage(bullet_damage, "ranged", self)`，销毁弹体
   - 超出射程后自动销毁
   - 敌人弹体不命中其他敌人

9. **每帧执行流程（近战型）**
   - 检查死亡状态 → 检查击退状态 → 执行当前阶段行为（侧移/冲刺/追踪）→ 更新位置 → 检查接触伤害

10. **每帧执行流程（远程型）**
    - 检查死亡状态 → 检查击退状态 → 闪避/射击/逼近 → 更新位置 → 更新射击冷却

### States and Transitions

**近战型状态机：**

| 状态 | 进入条件 | 退出条件 | 行为 |
|-------|---------|---------|------|
| `SPAWN` | 敌人生成 | 生成动画结束（0.3s） | 播放生成动画，不移动 |
| `FLANKING` | 生成结束 / 冲刺后玩家超出追踪范围 / 击退结束 | 侧移距离达到 `flank_distance` | 以 `flank_speed` 横向移动 |
| `CHARGING` | 侧移完成 | 到达锁定位置 | 以加速曲线冲向锁定位置 |
| `KNOCKBACK` | 受击时 | 击退位移完成 | 沿远离玩家方向位移，行为中断 |
| `DYING` | HP ≤ 0 | `on_death()` 触发 | 0.3s 死亡特效后销毁 |
| `DEAD` | `on_death()` 触发 | 实体移除 | 不参与游戏逻辑 |

**远程型状态机：**

| 状态 | 进入条件 | 退出条件 | 行为 |
|-------|---------|---------|------|
| `SPAWN` | 敌人生成 | 生成动画结束（0.3s） | 播放生成动画，不移动 |
| `APPROACH` | 与玩家距离 > `shoot_range` | 距离 ≤ `shoot_range` | 以 `approach_speed` 朝玩家移动 |
| `SHOOTING` | 距离 ≤ `shoot_range` 且不在闪避中 | 玩家进入 `evade_trigger_range` 或距离超出 `shoot_range` | 以 `shoot_interval` 间隔射击 |
| `EVADING` | 玩家距离 ≤ `evade_trigger_range` | 滑步距离达到 `evade_distance` | 以 `evade_speed` 侧向滑步，不射击 |
| `KNOCKBACK` | 受击时 | 击退位移完成 | 沿远离玩家方向位移，行为中断 |
| `DYING` | HP ≤ 0 | `on_death()` 触发 | 0.3s 死亡特效后销毁 |
| `DEAD` | `on_death()` 触发 | 实体移除 | 不参与游戏逻辑 |

### Interactions with Other Systems

| 交互系统 | 方向 | 接口说明 |
|---------|------|---------|
| 玩家移动系统 | 本系统读取移动 | 读取玩家 `position` 用于追踪和射击方向计算 |
| 生命/伤害系统 | 本系统 → 生命/伤害 | 近战接触伤害和远程弹体命中调用玩家 `take_damage()`；敌人自身 HP 由生命/伤害系统管理 |
| 混合战斗系统 | 战斗 → 本系统 | 战斗系统对敌人调用 `take_damage()`，敌人受击后进入 DYING 或 KNOCKBACK |
| 敌人生成系统 | 生成 → 本系统 | 生成系统创建敌人实例并注入 `EnemyData` Resource |
| 分数/统计系统 | 本系统 → 统计 | 敌人 `on_death()` 信号通知统计系统记录击杀 |
| 武器系统 | 武器 → 本系统 | 战斗系统读取武器的 `knockback_value` 传递给击退机制；近战武器有击退值，远程武器默认 0 |

## Formulas

### 近战型方向计算

```
# 侧移方向（垂直于到玩家连线，随机左或右）
to_player = (player_position - enemy_position).normalized()
perpendicular = Vector2(-to_player.y, to_player.x)  # 或取反
flank_sign = 1 or -1  # 随机
flank_direction = perpendicular * flank_sign
```

### 近战型位移（每帧）

```
# 侧移阶段
flank_displacement = flank_direction * flank_speed * delta

# 冲刺阶段（加速曲线）
charge_direction = (locked_target - enemy_position).normalized()
charge_progress = elapsed_charge_time / total_charge_time  # 0 到 1
speed_multiplier = ease(charge_progress, -2.0) * 1.5 + 0.5  # 起步50% → 峰值150%
charge_displacement = charge_direction * charge_speed * speed_multiplier * delta
```

### 远程型射击方向

```
shoot_direction = (player_position - enemy_position).normalized()
```

### 远程型闪避方向

```
# 侧向滑步（垂直于玩家接近方向）
player_approach = (enemy_position - player_position).normalized()
evade_perpendicular = Vector2(-player_approach.y, player_approach.x)
evade_sign = 1 or -1  # 随机
evade_direction = evade_perpendicular * evade_sign
```

### 距离检测

```
distance_to_player = (player_position - enemy_position).length()
```

### 击退计算

```
# 击退方向（远离玩家）
knockback_direction = (enemy_position - player_position).normalized()

# 击退距离由武器 knockback_value 决定
knockback_distance = weapon_knockback_value

# 击退持续时间
knockback_duration = knockback_distance / knockback_speed

# 击退位移（每帧）
knockback_displacement = knockback_direction * knockback_speed * delta
```

### 变量表

| 变量 | 类型 | 范围 | 来源 | 说明 |
|------|------|------|------|------|
| `flank_speed` | float | 100-400 px/s | 调参旋钮 | 近战侧移速度 |
| `flank_distance` | float | 50-200 px | 调参旋钮 | 近战侧移距离 |
| `charge_speed` | float | 200-600 px/s | 调参旋钮 | 近战冲刺速度 |
| `charge_resume_range` | float | 30-150 px | 调参旋钮 | 冲刺后继续追踪的距离阈值 |
| `contact_damage` | int | 5-50 | 调参旋钮 | 近战接触伤害 |
| `contact_damage_interval` | float | 0.2-1.0s | 调参旋钮 | 接触伤害间隔 |
| `approach_speed` | float | 80-300 px/s | 调参旋钮 | 远程逼近速度 |
| `shoot_range` | float | 150-500 px | 调参旋钮 | 远程射击范围 |
| `shoot_interval` | float | 0.5-3.0s | 调参旋钮 | 远程射击间隔 |
| `bullet_speed` | float | 150-500 px/s | 调参旋钮 | 远程弹体速度 |
| `bullet_damage` | int | 5-30 | 调参旋钮 | 远程弹体伤害 |
| `bullet_range` | float | 200-600 px | 调参旋钮 | 远程弹体射程 |
| `evade_trigger_range` | float | 80-200 px | 调参旋钮 | 触发闪避的距离 |
| `evade_speed` | float | 200-500 px/s | 调参旋钮 | 远程闪避速度 |
| `evade_distance` | float | 50-150 px | 调参旋钮 | 远程闪避滑步距离 |
| `max_consecutive_evades` | int | 1-3 | 调参旋钮 | 最大连续闪避次数 |
| `knockback_speed` | float | 200-800 px/s | 调参旋钮 | 击退位移速度（所有敌人通用） |
| `weapon_knockback_value` | float | 0-200 px | 武器数据 | 武器击退值（近战有值，远程默认 0） |

## Edge Cases

| 场景 | 预期行为 | 理由 |
|------|---------|------|
| 近战敌人侧移时撞墙 | 沿墙壁滑动，侧移距离可能缩短 | `move_and_slide()` 自动处理，不卡住 |
| 近战敌人冲刺目标位置已被玩家离开 | 冲刺到达后重新评估，进入下一轮侧移 | 冲刺目标是锁定位置，不是实时追踪 |
| 多个近战敌人选到相同侧移方向 | 允许重叠，不做碰撞排斥 | 敌人互不碰撞，视觉上可重叠 |
| 远程敌人闪避时撞墙 | 沿墙壁滑动，闪避距离可能缩短 | 同近战，不卡住 |
| 远程敌人闪避后仍在危险距离内 | 再次闪避，最多连续 `max_consecutive_evades` 次，之后强制进入射击 | 防止无限闪避导致敌人无法攻击 |
| 远程敌人在竞技场角落，无处闪避 | 闪避距离缩短（撞墙），仍尝试射击 | 角落是玩家的战术优势 |
| 敌人在玩家 DYING 期间 | 近战敌人停止追踪，远程敌人停止射击 | 玩家死亡后敌人不需要继续攻击 |
| 敌人 HP 被一击清零 | 直接进入 DYING，跳过当前行为 | 伤害结算优先于行为逻辑 |
| 近战敌人接触伤害间隔中玩家进入无敌帧 | 跳过该次伤害，间隔计时继续 | 生命/伤害系统 `is_invincible` 判断 |
| 远程敌人弹体命中正在闪避的玩家 | 弹体正常命中判定，闪避无敌帧由生命/伤害系统处理 | 敌人弹体不感知玩家闪避状态 |
| 同一帧内多个近战敌人接触玩家 | 每个敌人独立结算接触伤害 | 各敌人独立伤害计时器 |
| 敌人生成在玩家身上 | 生成动画 0.3s 内不造成接触伤害 | 给玩家反应时间 |
| 远程敌人射击冷却中玩家进入射程 | 等待冷却结束后再射击 | 射击间隔不可缩短 |
| 敌人被击退时撞墙 | 击退位移缩短（被墙挡住），击退时间照常流逝 | 与闪避/侧移撞墙行为一致 |
| 敌人击退期间再次受击 | 当前击退结束前不叠加新击退，新伤害正常结算 | 防止连续击退导致无限位移 |
| 近战型击退结束后 | 重新进入侧移阶段（不继续旧冲刺方向） | 冲刺已被打断，需要重新包抄 |
| 远程型击退结束后 | 重新评估距离，决定逼近/射击/闪避 | 击退可能将敌人推出射程 |
| 近战冲刺加速曲线在极短距离下 | 如果锁定位置很近，冲刺时间极短，加速曲线几乎不生效 | 正常行为，短距离冲刺本来就不需要长加速 |

## Dependencies

| 系统 | 方向 | 性质 |
|------|------|------|
| 玩家移动系统 | 本系统依赖移动 | 硬依赖：读取玩家 `position` 用于追踪、射击方向、距离计算 |
| 生命/伤害系统 | 本系统 ↔ 生命/伤害 | 硬依赖：对玩家调用 `take_damage()`；敌人自身 HP 和 DYING/DEAD 状态由该系统管理 |
| 混合战斗系统 | 战斗 → 本系统 | 硬依赖：战斗系统对敌人调用 `take_damage()` 造成伤害 |
| 敌人生成系统 | 生成 → 本系统 | 硬依赖：创建敌人实例并注入 `EnemyData` Resource |
| 分数/统计系统 | 本系统 → 统计 | 软依赖：敌人死亡时发送 `on_death()` 信号通知统计 |
| 武器系统 | 间接 | 软依赖：战斗系统读取武器数据对敌人造成伤害，本系统不直接交互 |
| 局内升级系统 | 升级 → 本系统 | 软依赖：可能修改敌人参数（如波次难度加成），后期设计 |

## Tuning Knobs

### 近战型

| 参数 | 当前值 | 安全范围 | 调高效果 | 调低效果 |
|------|--------|----------|---------|---------|
| `flank_speed` | 200 px/s | 100-400 | 侧移更快，包抄更难反应 | 侧移更慢，容易被玩家追上 |
| `flank_distance` | 100 px | 50-200 | 侧移更远，包抄角度更大 | 侧移更短，更接近直线冲锋 |
| `charge_speed` | 350 px/s | 200-600 | 冲刺更快，更难闪避 | 冲刺更慢，更容易躲开 |
| `charge_resume_range` | 80 px | 30-150 | 冲刺后追踪范围更大 | 冲刺后更容易脱离追踪 |
| `contact_damage` | 15 | 5-50 | 接触伤害更高，容错更低 | 接触伤害更低，更宽容 |
| `contact_damage_interval` | 0.5s | 0.2-1.0 | 伤害更频繁 | 伤害更稀疏，更容易脱身 |

### 远程型

| 参数 | 当前值 | 安全范围 | 调高效果 | 调低效果 |
|------|--------|----------|---------|---------|
| `approach_speed` | 150 px/s | 80-300 | 逼近更快，更快进入射程 | 逼近更慢，给玩家更多时间 |
| `shoot_range` | 300 px | 150-500 | 射程更远，更早开始射击 | 射程更短，需要更靠近 |
| `shoot_interval` | 1.5s | 0.5-3.0 | 射击更频繁，弹幕更密 | 射击更稀疏，压力更小 |
| `bullet_speed` | 250 px/s | 150-500 | 弹体更快，更难闪避 | 弹体更慢，更容易走位躲 |
| `bullet_damage` | 10 | 5-30 | 弹体伤害更高 | 弹体伤害更低 |
| `bullet_range` | 300 px | 200-600 | 弹体飞得更远 | 弹体更短，需要更近射击 |
| `evade_trigger_range` | 120 px | 80-200 | 更早触发闪避，更难近身 | 更晚触发闪避，更容易近身击杀 |
| `evade_speed` | 300 px/s | 200-500 | 闪避更快，更难追上 | 闪避更慢，更容易追击 |
| `evade_distance` | 80 px | 50-150 | 闪避更远，拉开距离更大 | 闪避更短，更容易再次靠近 |
| `max_consecutive_evades` | 2 | 1-3 | 连续闪避更多，更难近身 | 连续闪避更少，更容易抓住 |

### 通用

| 参数 | 当前值 | 安全范围 | 调高效果 | 调低效果 |
|------|--------|----------|---------|---------|
| `knockback_speed` | 400 px/s | 200-800 | 击退更快，手感更干脆 | 击退更慢，击退期间更易受击 |

## Visual/Audio Requirements

| 事件 | 视觉反馈 | 音频反馈 | 说明 |
|------|---------|---------|------|
| 敌人生成 | 从地面淡入（0.3s），生成圆环扩散特效 | 生成音效（低沉涌动） | SPAWN 状态期间 |
| 近战侧移 | 无特殊特效 | 轻微移动声 | 与普通移动一致 |
| 近战冲刺 | 冲刺拖影（1-2 帧半透明残影） | 冲刺音效（急促破风） | 区别于普通移动 |
| 近战接触伤害 | 玩家闪烁白（由生命/伤害系统处理） | 命中音效（钝击） | 本系统不控制玩家端反馈 |
| 远程射击 | 枪口闪光 | 射击音效（短促爆破） | 敌人射击视觉比玩家弱 |
| 远程闪避 | 侧移残影 | 闪避音效（轻微） | 提示玩家敌人闪避了 |
| 敌人受击 | 闪烁红色 0.1s + 击退位移 | 受击音效 | 击退方向远离伤害来源 |
| 敌人死亡 | 爆散粒子 + 淡出 0.3s | 死亡音效（碎裂感） | DYING 状态期间 |

## UI Requirements

敌人 AI 系统不直接渲染 HUD 元素，但需要为 UI 系统暴露：

| 数据 | 类型 | 用途 |
|------|------|------|
| `enemy_type` | String | 区分敌人种类用于显示不同图标 |
| `current_hp` / `max_hp` | int | 敌人头上的血条（如有） |
| `state` | String | 状态指示（调试用，MVP 可不显示） |

- [ ] 近战敌人生成后先侧移 100px 再冲刺，侧移方向垂直于到玩家连线
- [ ] 近战敌人冲刺时采用加速曲线（起步 50% → 峰值 150%），手感有"蓄力→爆发"的节奏
- [ ] 近战敌人冲刺时朝锁定位置移动，玩家移动不影响冲刺方向
- [ ] 近战敌人冲刺到达后，玩家在 80px 内则继续追踪，否则重新侧移
- [ ] 近战敌人接触玩家时调用 `take_damage(15, "melee", self)`，间隔 0.5s
- [ ] 远程敌人在 300px 射程内以 1.5s 间隔射击弹体
- [ ] 远程弹体沿玩家方向飞行，速度 250 px/s，命中玩家调用 `take_damage(10, "ranged", self)`
- [ ] 远程弹体超出 300px 射程后自动销毁
- [ ] 远程敌人在 120px 内触发侧向滑步闪避，速度 300 px/s，距离 80px
- [ ] 远程敌人最多连续闪避 2 次后强制进入射击
- [ ] 远程敌人在射程外以 150 px/s 逼近玩家
- [ ] 敌人被墙壁阻挡时沿墙壁滑动，不卡住
- [ ] 敌人之间不碰撞，允许重叠
- [ ] 敌人 HP 归零后进入 DYING 状态（0.3s），不再移动或攻击
- [ ] 玩家 DYING 期间敌人停止追踪和射击
- [ ] 玩家无敌帧期间近战接触伤害被忽略
- [ ] 敌人生成动画 0.3s 内不造成接触伤害
- [ ] 敌人受击时沿远离玩家方向击退，击退距离 = 武器 `knockback_value`
- [ ] 击退期间敌人行为中断，击退结束后近战型进入侧移，远程型重新评估距离
- [ ] 远程武器 `knockback_value` 默认为 0，不触发击退
- [ ] 击退期间再次受击不叠加击退位移，但伤害正常结算
- [ ] `EnemyData` Resource 包含所有参数，`.tres` 文件存在于 `assets/data/enemies/`
- [ ] 单个敌人 `_physics_process` 每帧执行时间 < 0.5ms，10 个同屏敌人 < 3ms

## Open Questions

| 问题 | 状态 | 备注 |
|------|------|------|
| Boss 敌人具体设计（血量、体型、伤害、奖励） | 待定 | 用户已确认后期加入，具体数值待波次系统设计后决定 |
| 远程敌人弹体是否应该有预警线/标记？ | 待定 | 无预警更紧张，有预警更公平，需 playtest 决定 |
| 侧移方向是否应该受其他敌人位置影响（避免重叠）？ | 待定 | 当前随机选择，可能多个敌人选同侧。互相避让更真实但开销更大 |
| 击退是否需要叠加衰减（连续击退距离递减）？ | 待定 | 当前无衰减，连续击退可能导致敌人被无限推墙角 |
