# 生命/伤害系统 (Health / Damage System)

> **Status**: Approved
> **Author**: user + agents
> **Last Updated**: 2026-04-22
> **Implements Pillar**: 操作感即玩法、每一秒都在做选择

## Overview

生命/伤害系统是所有战斗交互的底层基础设施。它管理玩家和敌人的生命值（HP）、伤害计算、以及死亡判定。玩家和敌人都有数十到数百点 HP，每次受击造成浮动数值伤害（整数）。近战伤害通常高于远程，但近战风险也更高。伤害计算支持基础值、升级加成和状态修正。当 HP 归零时，角色立即死亡——没有濒死挣扎窗口。该系统通过 `take_damage()` 和 `heal()` 两个核心接口被战斗系统、武器系统、敌人 AI 和升级系统调用，是整个游戏中被依赖最多的基础系统。

## Player Fantasy

当玩家的近战武器砍中敌人时，屏幕上弹出一个鲜艳的伤害数字——"47"——伴随着敌人的后退和闪烁。那一瞬间，玩家感受到力量和精确。当连续命中后伤害数字从 15 跳到 30 再到 60（因为升级了），玩家清晰地看到自己变强的轨迹。每一次命中都是一个微小的确认：你在进步，你在掌控局面。当自己的 HP 被击中下降时，血条的缩减和伤害数字同样清晰——危险是可见的，死亡是即时的，但每一格 HP 的失去都让你更谨慎、更专注。这个系统让玩家**看到**自己的成长和危险，而不是靠猜测。

## Detailed Design

### Core Rules

1. **生命值属性**
   - 每个有生命值的实体（玩家和敌人）都有一个 `max_hp`（最大生命值）和 `current_hp`（当前生命值）
   - `current_hp` 范围：`0` 到 `max_hp`
   - `current_hp` 为 0 时，实体死亡

2. **伤害计算**
   - 伤害来源（武器/敌人攻击）提供 `base_damage`（基础伤害，整数值）
   - 伤害最终值 = `base_damage` × 所有修正系数的乘积
   - 伤害类型分为两种：`melee`（近战）和 `ranged`（远程），用于后续升级区分
   - 最终伤害最小值为 1（即使所有修正极低，至少造成 1 点伤害）

3. **受到伤害（take_damage）**
   - 调用接口：`take_damage(amount: int, damage_type: String, source: Node)`
   - `source` 用于追踪伤害来源（如哪个敌人/武器），供统计系统和击杀判定使用
   - 从 `current_hp` 中扣除 `amount`
   - 如果 `current_hp` ≤ 0，触发死亡流程
   - 受击实体闪烁白色 0.1 秒（视觉反馈）
   - 发出 `damage_taken(amount: float, position: Vector2)` 信号，由视觉反馈和统计系统消费

4. **治疗（heal）**
   - 调用接口：`heal(amount: int)`
   - `current_hp` 增加 `amount`，但不能超过 `max_hp`
   - 治疗量为 0 或负数时忽略

5. **死亡判定**
   - `current_hp` ≤ 0 时立即进入 `DYING` 状态，不再接受伤害或治疗
   - `DYING` 状态结束后（玩家 3s / 敌人 0.3s）触发死亡信号
   - 敌人死亡时发出 `enemy_killed(kill_type: String, position: Vector2, enemy_color: Color)` 信号
   - 玩家死亡时发出 `player_died()` 信号
   - 死亡信号触发后实体转为 `DEAD`，不可恢复、不可继续受击
   - 玩家死亡 → `player_died()` 后触发游戏结束/结算流程
   - 敌人死亡 → `enemy_killed()` 后触发击杀统计、掉落（如有）、销毁实体

6. **伤害输出信号**
   - 当实体造成伤害时，发出 `damage_dealt(amount: float, hit_position: Vector2, attack_type: String)` 信号
   - `hit_position`：命中点的世界坐标，供视觉反馈系统生成粒子
   - `attack_type`：`"melee"` 或 `"ranged"`，供统计系统和视觉反馈系统区分
   - 此信号由战斗系统在调用 `take_damage()` 成功扣血后触发

7. **伤害修正**
   - 升级系统可以添加伤害修正（如"+20% 近战伤害"）
   - 修正分为两类：`additive`（加算，如 +10 基础伤害）和 `multiplicative`（乘算，如 ×1.5）
   - 加算修正先累加，乘算修正后累乘
   - 公式：`final_damage = max(1, ceil((base_damage + sum_additive) × product_multiplicative))`

7. **无敌帧（invincibility）**
   - 受击后 0.2 秒内免疫后续伤害（防止单次碰撞多帧重复判定）
   - 闪避期间另有无敌帧（由闪避系统控制），与本无敌帧不叠加，取较长者
   - 无敌状态通过 `is_invincible` 标志管理

### States and Transitions

**实体生命周期状态机：**

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| `ALIVE` | 实体生成时 | `current_hp` ≤ 0 | 正常接受伤害和治疗 |
| `DYING` | `current_hp` ≤ 0 | `on_death()` 触发后进入 `DEAD` | 触发死亡特效、击杀统计、掉落；不可再受击或治疗 |
| `DEAD` | `on_death()` 触发 | 实体从场景移除 | 不再参与游戏逻辑 |

- 玩家 `DYING` 状态持续 3 秒：尸体留在场上，显示倒计时，让玩家看到战场
- 敌人 `DYING` 状态持续 0.3 秒：短暂特效后快速移除（保持节奏）

**无敌状态机：**

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| `VULNERABLE` | 默认状态 / 无敌结束 | 受到伤害 / 闪避触发 | 正常接受伤害 |
| `INVINCIBLE` | 受击后 0.2s / 闪避触发 | 计时结束 | 忽略所有伤害，不接受新无敌请求 |

- 两种无敌来源不叠加，取剩余时间较长者
- 无敌状态通过 `is_invincible: bool` + `invincible_timer: float` 管理

### Interactions with Other Systems

| 交互系统 | 方向 | 接口说明 |
|---------|------|---------|
| 混合战斗系统 | 本系统 → 战斗 | 提供 `take_damage()` 和 `heal()` 接口；战斗系统调用后获得伤害结果和死亡信号 |
| 武器系统 | 武器 → 本系统 | 武器提供 `base_damage` 和 `damage_type`，本系统计算最终伤害 |
| 闪避系统 | 闪避 → 本系统 | 闪避触发时设置 `is_invincible = true`，本系统查询无敌状态 |
| 敌人 AI 系统 | 本系统 ↔ 敌人AI | 敌人 AI 调用 `take_damage()` 对玩家造成伤害；敌人自身的 HP 也通过本系统管理 |
| 分数/统计系统 | 本系统 → 统计 | 死亡信号触发时通知统计系统记录击杀/死亡 |
| 视觉反馈系统 | 本系统 → 视觉 | 受击/死亡时发出信号，触发闪烁、飘字、屏幕震动 |
| 局内升级系统 | 升级 → 本系统 | 升级修改 `max_hp`、伤害修正系数等属性 |

## Formulas

### 最终伤害计算

```
final_damage = max(1, ceil((base_damage + sum_additive) × product_multiplicative))
```

| 变量 | 类型 | 范围 | 来源 | 说明 |
|------|------|------|------|------|
| `base_damage` | int | 1-999 | 武器数据/敌人数据 | 基础伤害值 |
| `sum_additive` | int | -50 到 +200 | 升级系统 | 所有加算修正的总和 |
| `product_multiplicative` | float | 0.1 到 5.0 | 升级系统 | 所有乘算修正的累乘 |

**预期输出范围**: 1 到 ~2000（极端升级叠加下）
**边界**: 最终值至少为 1（`max(1, ...)` 保证）

### 治疗上限

```
actual_heal = min(amount, max_hp - current_hp)
current_hp += actual_heal
```

| 变量 | 类型 | 范围 | 来源 | 说明 |
|------|------|------|------|------|
| `amount` | int | 1 到 max_hp | 升级/道具 | 请求治疗量 |
| `actual_heal` | int | 0 到 max_hp - current_hp | 计算 | 实际治疗量（不能超过上限） |

**边界**: 如果 `current_hp == max_hp`，`actual_heal = 0`（满血时治疗无效）

## Edge Cases

| 场景 | 预期行为 | 理由 |
|------|---------|------|
| 同一帧内多个伤害源同时命中 | 按注册顺序依次结算，每个都检查 HP ≤ 0 | 防止"负血复活"bug |
| 受击同时触发治疗 | 先结算伤害，再结算治疗（若 HP 已 ≤ 0 则死亡，治疗不生效） | 伤害优先，防止死亡后治疗复活 |
| 升级将 `max_hp` 降低至低于 `current_hp` | `current_hp` 等比例降低到新的 `max_hp` | 保持百分比一致性 |
| 玩家在无敌帧期间再次受击 | 伤害被忽略，不触发新的闪烁/飘字 | 防止多帧重复判定 |
| 敌人 HP 为 0 后又收到伤害信号 | 忽略（`on_death` 触发后移除碰撞体） | 防止重复击杀统计 |
| 浮点精度导致伤害为 0.999 | `final_damage` 向上取整（`ceil`），最小值 1 | 确保整数伤害，避免 0 伤害 |
| 所有升级修正叠加后伤害溢出 | 使用 32 位 int（最大 2,147,483,647），实际不可能溢出 | Godot int 足够 |

## Dependencies

| 系统 | 方向 | 性质 |
|------|------|------|
| 无 | — | Foundation 层，零上游依赖 |
| 混合战斗系统 | 战斗依赖本系统 | 硬依赖：调用 `take_damage()` 和 `heal()` 接口 |
| 武器系统 | 武器依赖本系统 | 硬依赖：提供 `base_damage` 和 `damage_type` |
| 闪避系统 | 闪避依赖本系统 | 软依赖：设置 `is_invincible` 状态 |
| 敌人 AI 系统 | 敌人AI依赖本系统 | 硬依赖：敌人 HP 管理和对玩家造成伤害 |
| 分数/统计系统 | 统计依赖本系统 | 软依赖：监听 `enemy_killed` 和 `damage_dealt`/`damage_taken` 信号 |
| 波次系统 | 波次依赖本系统 | 软依赖：监听 `enemy_killed` 信号判定波次完成 |
| 视觉反馈系统 | 视觉依赖本系统 | 软依赖：监听 `damage_dealt`/`damage_taken`/`enemy_killed`/`player_died` 信号触发特效 |
| 升级池/数据系统 | 升级依赖本系统 | 硬依赖：修改 `max_hp` 和伤害修正系数，升级 max_health_up 时调用 `heal()` |

**信号清单（本系统发出）**：

| 信号 | 参数 | 消费者 |
|------|------|--------|
| `damage_dealt` | `amount: float, hit_position: Vector2, attack_type: String` | 分数/统计、视觉反馈 |
| `damage_taken` | `amount: float, position: Vector2` | 分数/统计、视觉反馈 |
| `enemy_killed` | `kill_type: String, position: Vector2, enemy_color: Color` | 分数/统计、波次、视觉反馈 |
| `player_died` | （无参数） | 波次、视觉反馈 |

## Tuning Knobs

| 参数 | 当前值 | 安全范围 | 调高效果 | 调低效果 |
|------|--------|----------|---------|---------|
| `player_max_hp` | 100 | 50-500 | 玩家更肉，容错率高 | 更紧张，更容易死 |
| `player_base_damage_melee` | 25 | 10-100 | 近战更强势 | 近战无力，玩家倾向远程 |
| `player_base_damage_ranged` | 15 | 5-80 | 远程更强势 | 远程刮痧，玩家倾向近战 |
| `invincibility_duration` | 0.2s | 0.05-1.0s | 更宽容，连击伤害降低 | 更紧张，容易被连续命中击杀 |
| `hit_flash_duration` | 0.1s | 0.05-0.3s | 受击反馈更明显 | 反馈更快消失 |
| `player_death_linger` | 3.0s | 1.0-5.0s | 更多时间观察战场 | 更快进入结算 |
| `enemy_death_linger` | 0.3s | 0.1-1.0s | 死亡特效更明显 | 敌人消失更快 |
| `damage_min_value` | 1 | 1-5 | 保证最小伤害 | —（不建议低于1） |

## Visual/Audio Requirements

| 事件 | 视觉反馈 | 音效反馈 | 优先级 |
|------|---------|---------|--------|
| 玩家受击 | 闪烁白色 0.1s + 屏幕轻微震动 | 受击音效（低沉钝击） | 高 |
| 玩家造成近战伤害 | 飘字伤害数字 + 敌人闪烁红色 0.1s | 近战命中音效（清脆切割） | 高 |
| 玩家造成远程伤害 | 飘字伤害数字 + 敌人闪烁红色 0.1s | 子弹命中音效 | 高 |
| 玩家死亡 | 尸体留在场上 3s + 倒计时 + 屏幕变暗 | 死亡音效（沉重） | 高 |
| 敌人死亡 | 短暂闪烁后消失 0.3s | 敌人死亡音效（短促） | 高 |
| 治疗 | 绿色粒子效果 + HP 条绿色填充动画 | 治疗音效（柔和上升音） | 中 |
| 无敌帧激活 | 玩家模型半透明闪烁 | 无 | 低 |

## UI Requirements

| 信息 | 显示位置 | 更新频率 | 触发条件 |
|------|---------|---------|---------|
| 玩家当前 HP | 屏幕左上角血条 | 实时（每帧） | HP 变化时 |
| 玩家当前 HP 数值 | 血条旁数字（如 73/100） | 实时 | HP 变化时 |
| 伤害飘字 | 受击实体上方，向上飘 1s 后消失 | 每次受击 | `take_damage()` 调用 |
| 死亡倒计时 | 屏幕中央大字（如 "3...2...1..."） | 每秒 | 玩家进入 DYING 状态 |

## Open Questions

| 问题 | 负责人 | 截止日期 | 解决方案 |
|------|--------|---------|---------|
| 近战/远程基础伤害比例（25:15）是否合理？ | user | 原型阶段 | 需要 `/prototype core-combat` 验证 |
| 是否需要暴击系统（随机倍率伤害）？ | user | MVP 后 | 当前不做，如需要后续加入 |
| 敌人是否应该有不同的 HP 层级（如精英怪 3 倍 HP）？ | user | 设计敌人 AI 时 | 暂定需要，具体数值在敌人 AI GDD 中定义 |
| 受击无敌帧 0.2s 是否足够？ | user | playtest 后 | 可能需要根据波次节奏调整 |

## Acceptance Criteria

- [ ] 玩家 `current_hp` 初始值等于 `max_hp`，`is_invincible` 为 false
- [ ] 调用 `take_damage(25, "melee", source)` 后，`current_hp` 减少 25，实体闪烁 0.1s，飘字显示 "25"
- [ ] `current_hp` 归零后立即进入 DYING（不可受击/治疗），3 秒倒计时结束后触发 `on_death` 信号并进入结算
- [ ] 受击后 0.2s 无敌期间再次调用 `take_damage()`，伤害被忽略，不触发闪烁/飘字
- [ ] 调用 `heal(30)` 且 `current_hp` 为 80、`max_hp` 为 100 时，`current_hp` 变为 100（不是 110）
- [ ] 满血时调用 `heal(10)`，`current_hp` 不变，不触发任何视觉反馈
- [ ] 伤害公式 `base=10, additive=+5, multiplicative=×2.0` 输出 `final_damage = 30`（`ceil(30.0) = 30`）
- [ ] 伤害公式 `base=1, additive=-5, multiplicative=×0.1` 输出 `final_damage = 1`（`max(1, ceil(-0.4)) = 1`，最小值保底）
- [ ] 敌人死亡后 0.3s 内从场景移除，不再接受碰撞检测
- [ ] 同一帧内两次 `take_damage()` 调用按顺序结算，不会漏掉或合并
