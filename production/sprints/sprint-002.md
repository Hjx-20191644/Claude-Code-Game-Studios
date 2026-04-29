# Sprint 2 -- 2026-05-12 to 2026-05-25

## Sprint Goal
实现完整核心游戏循环：生成敌人 → 战斗清场 → 波次结束 → 三选一升级 → 下一波（可重复体验 5 波）

## Capacity
- Total days: 14
- Buffer (20%): 3 days
- Available: 11 days (~14-18 sessions)

## Tasks

### Must Have (Critical Path)
| ID | Task | Owner | Est. Sessions | Dependencies | Acceptance Criteria |
|----|------|-------|---------------|-------------|-------------------|
| S2-01 | 升级池/数据系统：UpgradeData Resource + UpgradePool 逻辑 + 抽卡/选择/稀有度 | gameplay-programmer | 2 | 无上游依赖（Foundation） | draw_upgrades() 返回 N 张不重复卡；acquire_upgrade() 发出 upgrade_acquired 信号；稀有度按权重随机；同一池不会重复抽到已满级的卡 |
| S2-02 | 敌人生成系统：SpawnManager + 生成位置计算 + 波次数量 + spawn_min_distance | gameplay-programmer | 2 | S1-08 (敌人) | spawn_enemies(type, count) 在合法位置生成敌人；spawn_min_distance≥200px；arena_rect 边界修正；生成完发出 wave_spawn_complete 信号 |
| S2-03 | 波次系统：WaveManager 状态机 + 波次配置 + 难度递增 + 波次间暂停 + upgrade_interval | gameplay-programmer | 3 | S2-02 | 5 波递增（敌人数量/速度/HP 递增）；每波清完自动下一波；每 3 波触发升级窗口；波次间 2s 暂停；wave_started/wave_completed 信号 |
| S2-04 | 局内升级系统：UpgradeManager + 升级窗口暂停 + 3 选 1 UI + 超时自动选 | gameplay-programmer + ui-programmer | 3 | S2-01, S2-03 | 波次系统触发→游戏暂停→显示 3 张升级卡→玩家选择/超时→应用效果→恢复；卡片显示名称/描述/稀有度色；30s 超时自动随机选 |
| S2-05 | 分数/统计系统：ScoreManager + 击杀/波次/伤害统计 + score_changed/kill_count_changed 信号 | gameplay-programmer | 1 | S1-03 (life/dmg) | 近战击杀 +100 分；远程击杀 +150 分；接收 enemy_killed 信号更新击杀数；get_stats() 返回完整统计 |

### Should Have
| ID | Task | Owner | Est. Sessions | Dependencies | Acceptance Criteria |
|----|------|-------|---------------|-------------|-------------------|
| S2-06 | 战斗 HUD：头顶血条 + 分数左上角 + 波次提示 + 弹药显示 + 闪避冷却 | ui-programmer | 2 | S2-05, S1-06, S1-07 | HP 条平滑过渡 0.2s；波次大字提示 2s 消失；弹药图标随射击减少/回复填充；闪避冷却圈充能动画 |
| S2-07 | 视觉反馈系统：伤害数字飘字 + 敌人闪烁 + 闪避残影 + 屏幕震动（仅远程） | technical-artist | 2 | S1-06, S1-07 | 伤害数字上飘+淡出 0.5s；敌人受击红色闪烁 0.1s；闪避 3 帧半透明残影；远程命中无震屏（GDD 确认） |

### Nice to Have
| ID | Task | Owner | Est. Sessions | Dependencies | Acceptance Criteria |
|----|------|-------|---------------|-------------|-------------------|
| S2-08 | 敌人 AI 升级：近战包抄行为（侧移+冲刺） | gameplay-programmer | 2 | S2-02 | 近战敌人两段式包抄：侧移 100px → 加速冲刺；冲刺后重新评估距离 |
| S2-09 | 游戏暂停菜单：Esc 暂停 + 继续/退出 | ui-programmer | 1 | — | Esc 暂停游戏；显示暂停菜单；继续按钮恢复；退出按钮返回主菜单 |

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|-------------|
| N/A (Sprint 1 100% complete) | — | — |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 波次-升级-生成三系统接口不一致 | MEDIUM | HIGH | 先对齐 EventBus 信号签名（升级窗口请求/完成、生成完成），参考 GDD 双向依赖表 |
| 升级 UI 实现复杂（暂停+动画+选择） | MEDIUM | MEDIUM | 先做功能（暂停+三按钮），后做动画（卡片滑入） |
| 波次难度曲线不合理（过难/过易） | MEDIUM | MEDIUM | 默认参数保守起步，playtest 后调整 |
| HUD 元素过多遮挡战场 | LOW | MEDIUM | 严格遵守 GDD 布局：血条头顶+分数左上角+波次居中，不做额外元素 |

## Dependencies on External Factors
- 无外部依赖
- 竞技场 rect 硬编码为 Arena 节点区域（1000×600，中心 640,360），待竞技场系统创建后改为动态读取

## Definition of Done for this Sprint
- [ ] 所有 Must Have 任务完成（S2-01 到 S2-05）
- [ ] 玩家可从 Wave 1 玩到 Wave 5，中间经历升级选择，最终死亡或通关
- [ ] 核心循环"战斗→清场→波次升级→下一波"可重复体验
- [ ] EventBus 新增信号签名与 GDD 一致
- [ ] 代码遵循 technical-preferences.md 命名规范
- [ ] 60fps 稳定，帧时间 < 16.6ms（10 个同屏敌人）
- [ ] 无 S1 或 S2 bug

## Sprint Notes
- Sprint 1 超额完成（9/9 + 全部 Should Have），Sprint 2 目标是完成核心循环
- 升级池系统是 Foundation 层且无上游依赖，优先实现（为其他系统解锁升级监听）
- 波次-生成-升级三系统存在双向依赖，实现顺序：升级池 → 生成 → 波次 → 局内升级
- 分数系统可并行（仅依赖生命/伤害系统的 enemy_killed 信号，该信号已存在）
- HUD 和视觉反馈是 Should Have，若 Must Have 进度紧张可推迟到 Sprint 3
- arena_rect 使用硬编码值（ARENA_WIDTH/HEIGHT 已定义在 GameConfig），后期动态化
