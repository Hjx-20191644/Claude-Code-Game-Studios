# Sprint 1 -- 2026-04-28 to 2026-05-11

## Sprint Goal
搭建项目骨架并实现 Foundation 层三大系统（输入/生命伤害/移动）+ 武器数据层，使玩家能在生产架构下移动、瞄准、受击。

## Capacity
- Total days: 14
- Buffer (20%): 3 days
- Available: 11 days (~14-18 sessions)

## Tasks

### Must Have (Critical Path)
| ID | Task | Owner | Est. Sessions | Dependencies | Acceptance Criteria |
|----|------|-------|---------------|-------------|-------------------|
| S1-01 | 项目骨架：Main场景 + EventBus Autoload + GameConfig Autoload + 目录结构 + 碰撞层配置 | gameplay-programmer | 1 | ADR-0001 | Main.tscn 可运行；EventBus 信号可 emit/connect；碰撞层 Layer 1/2/4/8 生效 |
| S1-02 | 输入系统：InputMap 配置 + 输入缓冲 + move_vector/melee_attack/ranged_attack/dodge 动作映射 | gameplay-programmer | 1 | S1-01 | WASD 生成 move_vector；鼠标左右键触发攻击信号；空格触发 dodge；_input 缓冲不漏帧 |
| S1-03 | 生命/伤害系统：HP管理 + take_damage + heal + 无敌帧 + 4个信号(damage_dealt/damage_taken/enemy_killed/player_died) | gameplay-programmer | 2 | S1-01 | take_damage 扣血+闪烁+无敌帧；heal 不超上限；HP=0 进入 DYING；4 个信号通过 EventBus 发出 |
| S1-04 | 玩家移动系统：CharacterBody2D + WASD 8方向 + 300px/s + 鼠标瞄准朝向 | gameplay-programmer | 1 | S1-02, S1-03 | 移动速度 300px/s；对角归一化；碰撞沿墙滑动；朝向跟随鼠标；死亡停止移动 |
| S1-05 | 武器数据层：WeaponData Resource + 大剑.tres + 手枪.tres | gameplay-programmer | 1 | S1-01 | WeaponData 继承 Resource；@export 参数完整；类型/参数断言通过；.tres 文件可被战斗系统读取 |

### Should Have
| ID | Task | Owner | Est. Sessions | Dependencies | Acceptance Criteria |
|----|------|-------|---------------|-------------|-------------------|
| S1-06 | 混合战斗系统：近战扇形 + 远程弹体 + 冷却 + 弹药 + 击退 | gameplay-programmer | 3 | S1-04, S1-05 | 左键近战 105°/80px 扇形命中；右键远程 600px/s 弹体；独立冷却；弹药10发+回复；近战击退 40px |
| S1-07 | 闪避系统：闪避位移 + 无敌帧 + 冷却 | gameplay-programmer | 1 | S1-04 | 空格闪避 120px/0.2s；无敌帧 0.2s；冷却 2.0s；闪避方向=移动方向/鼠标方向；闪避中可攻击 |

### Nice to Have
| ID | Task | Owner | Est. Sessions | Dependencies | Acceptance Criteria |
|----|------|-------|---------------|-------------|-------------------|
| S1-08 | 基础敌人：追踪AI + 接触伤害 + 击退 + HP | gameplay-programmer | 2 | S1-06 | 敌人追踪玩家；接触伤害+冷却；受击击退 40px；HP=30 两刀死；死亡 0.3s 消失 |
| S1-09 | 输入架构 ADR | lead-programmer | 0.5 | S1-02 | ADR-0002 记录 InputMap + 缓冲机制决策 |

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|-------------|
| N/A (first sprint) | — | — |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 原型代码诱惑直接复制到生产 | MEDIUM | HIGH | 严格遵守"原型代码不迁移"原则，从零重写 |
| EventBus 信号签名与 GDD 不一致 | MEDIUM | MEDIUM | 参考 GDD 依赖章节中的信号定义，对齐参数 |
| 碰撞层配置错误导致角色穿墙/卡住 | LOW | HIGH | 使用原型验证过的 Layer 1/2/4/8 方案 |

## Dependencies on External Factors
- Godot 4.6 已安装在 D:\Program Files (x86)\Godot\
- 无外部依赖

## Definition of Done for this Sprint
- [ ] 所有 Must Have 任务完成（S1-01 到 S1-05）
- [ ] 所有任务通过各自验收标准
- [ ] 无 S1 或 S2 bug
- [ ] 代码遵循 technical-preferences.md 命名规范
- [ ] EventBus 信号签名与 GDD 一致
- [ ] 可运行：玩家能在竞技场中移动、瞄准、受击（不需要敌人）

## Sprint Notes
- 原型核心战斗已验证，生产代码从零重写，不复用原型代码
- 原型发现：近战半径 80px、击退 40px、输入缓冲 _input、碰撞层分离——这些经验直接指导生产实现
- GDD 更新项：近战半径从 60px 调整为 80px（原型验证结果）
