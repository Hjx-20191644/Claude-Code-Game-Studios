# MVP Milestone

## Goal
验证"混合战斗+波次+升级"核心循环是否好玩可重复

## Scope
14 个 MVP 系统全部实现并通过验收标准

## Systems (by dependency order)
1. 输入系统 (Foundation)
2. 生命/伤害系统 (Foundation)
3. 玩家移动系统 (Foundation)
4. 混合战斗系统 (Core)
5. 武器系统 (Core)
6. 闪避系统 (Core)
7. 敌人 AI 系统 (Core)
8. 敌人生成系统 (Core)
9. 升级池/数据系统 (Foundation)
10. 波次系统 (Feature)
11. 局内升级系统 (Feature)
12. 分数/统计系统 (Core)
13. 战斗 HUD (Presentation)
14. 视觉反馈系统 (Presentation)

## Target Date
2026-05-26 (4 weeks from 2026-04-28)

## Success Criteria
- [ ] 玩家可以完整进行一场游戏：从第1波到第5波，选择升级，死亡或通关
- [ ] 核心循环"战斗→波次结束→升级→下一波"可重复体验
- [ ] 所有 14 个系统的 GDD 验收标准通过
- [ ] 60fps 稳定运行，无 S1/S2 bug
