# Systems Index: 猎场 (Hunting Ground)

> **Status**: Approved
> **Created**: 2026-04-22
> **Last Updated**: 2026-04-23
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

猎场是一款竞技场生存 Roguelite，核心循环由混合战斗（近战+远程）、波次生存、局内升级和局外解锁组成。本游戏需要 21 个系统来支撑完整的体验——从底层的输入和移动、到核心的战斗和 AI、到上层的升级 UI 和元进度系统。设计顺序遵循"依赖优先"原则：没有基础的移动和伤害系统，战斗就无法运行；没有战斗，波次就没有意义；没有波次，升级就没有触发条件。

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | 输入系统 | Core | MVP | Approved | design/gdd/input-system.md | — |
| 2 | 玩家移动系统 (inferred) | Core | MVP | Approved | design/gdd/player-movement-system.md | 输入系统 |
| 3 | 生命/伤害系统 (inferred) | Core | MVP | Approved | design/gdd/health-damage-system.md | — |
| 4 | 混合战斗系统 | Gameplay | MVP | Approved | design/gdd/mixed-combat-system.md | 生命/伤害, 玩家移动, 输入 |
| 5 | 武器系统 (inferred) | Gameplay | MVP | Approved | design/gdd/weapon-system.md | 混合战斗, 生命/伤害 |
| 6 | 闪避系统 | Gameplay | MVP | Approved | design/gdd/dodge-system.md | 输入, 玩家移动, 生命/伤害 |
| 7 | 敌人 AI 系统 (inferred) | Gameplay | MVP | Approved | design/gdd/enemy-ai-system.md | 玩家移动, 生命/伤害 |
| 8 | 敌人生成系统 (inferred) | Gameplay | MVP | Approved | design/gdd/enemy-spawn-system.md | 敌人 AI |
| 9 | 波次系统 | Gameplay | MVP | Approved | design/gdd/wave-system.md | 敌人生成, 分数/统计 |
| 10 | 升级池/数据系统 (inferred) | Economy | MVP | Approved | design/gdd/upgrade-pool-system.md | — |
| 11 | 局内升级 | Progression | MVP | Approved | design/gdd/in-run-upgrade-system.md | 波次, 升级池 |
| 12 | 分数/统计系统 (inferred) | Meta | MVP | Approved | design/gdd/score-stats-system.md | 生命/伤害, 混合战斗 |
| 13 | 战斗 HUD (inferred) | UI | MVP | Approved | design/gdd/combat-hud.md | 混合战斗, 武器, 波次 |
| 14 | 视觉反馈系统 (inferred) | Audio/Visual | MVP | Approved | design/gdd/visual-feedback-system.md | 混合战斗, 闪避, 生命/伤害 |
| 15 | 碎片/货币系统 (inferred) | Economy | v1.0 | Not Started | — | 分数/统计 |
| 16 | 解锁树系统 (inferred) | Progression | v1.0 | Not Started | — | 碎片/货币 |
| 17 | 局外解锁 | Progression | v1.0 | Not Started | — | 解锁树, 碎片/货币 |
| 18 | 结算/局外界面 (inferred) | UI | v1.0 | Not Started | — | 碎片/货币, 解锁树, 分数/统计 |
| 19 | 游戏状态管理 (inferred) | Core | v1.0 | Not Started | — | 波次, 局内升级, 结算/局外 |
| 20 | 音效系统 (inferred) | Audio | v1.0 | Not Started | — | 混合战斗, 局内升级, 波次 |
| 21 | 升级选择界面（完善版）(inferred) | UI | 完整版 | Not Started | — | 局内升级, 升级池 |

**标注说明**: (inferred) = 隐式系统，概念文档未直接提及但开发必需。

---

## Categories

| Category | Description | Systems |
|----------|-------------|---------|
| **Core** | 基础系统，所有其他系统依赖 | 输入系统, 玩家移动系统, 生命/伤害系统, 游戏状态管理 |
| **Gameplay** | 核心玩法和乐趣来源 | 混合战斗, 武器系统, 闪避系统, 敌人 AI, 敌人生成, 波次系统 |
| **Progression** | 玩家成长系统 | 局内升级, 解锁树系统, 局外解锁 |
| **Economy** | 资源和数据系统 | 升级池/数据系统, 碎片/货币系统 |
| **UI** | 玩家界面显示 | 战斗 HUD, 结算/局外界面, 升级选择界面 |
| **Audio/Visual** | 反馈和表现层 | 视觉反馈系统, 音效系统 |
| **Meta** | 元系统和统计 | 分数/统计系统 |

---

## Priority Tiers

| Tier | Definition | Target Milestone | System Count |
|------|------------|------------------|--------------|
| **MVP** | 核心循环运行必需。验证"混合战斗+波次+升级"是否好玩 | 第 1-3 周 | 14 |
| **v1.0** | 加入局外解锁，完成"死亡→变强→再挑战"的长期循环 | +2-3 周 | 6 |
| **完整版** | 打磨和内容扩展，更好的 UI、音效、更多武器和敌人 | +4-6 周 | 1 |

---

## Dependency Map

### Foundation Layer（零依赖）

1. **输入系统** — 所有玩家操作的基础
2. **生命/伤害系统** — 最高瓶颈系统（6 个系统直接依赖）
3. **玩家移动系统** — 依赖输入系统；战斗、闪避、敌人追踪的基础
4. **升级池/数据系统** — 纯数据定义，无运行时依赖

### Core Layer（依赖 Foundation）

5. **混合战斗系统** — 依赖: 生命/伤害, 玩家移动, 输入
6. **武器系统** — 依赖: 混合战斗, 生命/伤害
7. **闪避系统** — 依赖: 输入, 玩家移动, 生命/伤害
8. **敌人 AI 系统** — 依赖: 玩家移动, 生命/伤害
9. **敌人生成系统** — 依赖: 敌人 AI
10. **分数/统计系统** — 依赖: 生命/伤害, 混合战斗

### Feature Layer（依赖 Core）

11. **波次系统** — 依赖: 敌人生成, 分数/统计
12. **局内升级** — 依赖: 波次, 升级池

### Presentation Layer（依赖 Feature）

13. **战斗 HUD** — 依赖: 混合战斗, 武器, 波次, 闪避
14. **升级选择界面** — 依赖: 局内升级, 升级池
15. **视觉反馈系统** — 依赖: 混合战斗, 闪避, 生命/伤害
16. **音效系统** — 依赖: 混合战斗, 局内升级, 波次

### Meta Layer（依赖所有层）

17. **碎片/货币系统** — 依赖: 分数/统计
18. **解锁树系统** — 依赖: 碎片/货币
19. **局外解锁** — 依赖: 解锁树, 碎片/货币
20. **结算/局外界面** — 依赖: 碎片/货币, 解锁树, 分数/统计
21. **游戏状态管理** — 依赖: 波次, 局内升级, 结算/局外界面

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | 输入系统 | MVP | Foundation | game-designer | S |
| 2 | 生命/伤害系统 | MVP | Foundation | game-designer, systems-designer | M |
| 3 | 玩家移动系统 | MVP | Foundation | game-designer | S |
| 4 | 混合战斗系统 | MVP | Core | game-designer, gameplay-programmer | L |
| 5 | 武器系统 | MVP | Core | game-designer | S |
| 6 | 闪避系统 | MVP | Core | game-designer | S |
| 7 | 敌人 AI 系统 | MVP | Core | game-designer, ai-programmer | M |
| 8 | 敌人生成系统 | MVP | Core | game-designer | S |
| 9 | 升级池/数据系统 | MVP | Foundation | systems-designer | M |
| 10 | 波次系统 | MVP | Feature | game-designer | M |
| 11 | 局内升级 | MVP | Feature | game-designer | M |
| 12 | 分数/统计系统 | MVP | Core | game-designer | S |
| 13 | 战斗 HUD | MVP | Presentation | game-designer, ui-programmer | S |
| 14 | 视觉反馈系统 | MVP | Presentation | technical-artist | M |
| 15 | 碎片/货币系统 | v1.0 | Meta | systems-designer | S |
| 16 | 解锁树系统 | v1.0 | Meta | systems-designer | M |
| 17 | 局外解锁 | v1.0 | Meta | game-designer | M |
| 18 | 结算/局外界面 | v1.0 | UI | ui-programmer | M |
| 19 | 游戏状态管理 | v1.0 | Core | gameplay-programmer | M |
| 20 | 音效系统 | v1.0 | Audio | sound-designer | M |
| 21 | 升级选择界面（完善版） | 完整版 | UI | ui-programmer | S |

**Effort**: S = 1 session, M = 2-3 sessions, L = 4+ sessions

---

## Circular Dependencies

- **None found.** 依赖关系为干净的单向 5 层结构。

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| 混合战斗系统 | Technical | 手感调优困难——命中判定、反馈 timing 需要反复调试 | 第 1 周就做纯手感原型，不碰其他系统 |
| 生命/伤害系统 | Technical | 最高瓶颈系统——设计不当会导致 6 个系统返工 | 设计后运行 `/design-review`，确保完整性 |
| 敌人 AI 系统 | Technical | 新手不熟悉 Godot 2D AI 行为逻辑 | 使用 Godot Navigation2D + 简单状态机，不追求复杂 AI |
| 波次系统 | Design | 难度曲线失控——太简单无聊，太难劝退 | 内置实时调参工具，开发时可随时调整 |
| 升级池/数据系统 | Design | 升级组合不够有趣，导致重复感 | MVP 只做 3-5 种验证，好玩再扩 |
| 局外解锁 | Scope | 解锁系统可能膨胀开发时间 | MVP 阶段完全跳过，v1.0 再做 |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 21 |
| Design docs started | 14 |
| Design docs reviewed | 14 |
| Design docs approved | 14 |
| MVP systems designed | 14/14 |
| v1.0 systems designed | 0/6 |

---

## Next Steps

- [x] Design MVP systems in order: ~~start with~~ `/design-system 生命/伤害系统` ✓ Approved
- [x] `/design-system 玩家移动系统` ✓ Approved
- [x] `/design-system 输入系统` ✓ Approved
- [x] `/design-system 混合战斗系统` ✓ Approved
- [x] `/design-system 武器系统` ✓ Approved
- [x] `/design-system 闪避系统` ✓ Approved
- [x] `/design-system 敌人AI系统` ✓ Approved
- [x] `/design-system 敌人生成系统` ✓ Approved
- [x] `/design-system 升级池/数据系统` ✓ Approved
- [x] `/design-system 分数/统计系统` ✓ Approved
- [x] `/design-system 波次系统` ✓ Approved
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check pre-production` when MVP systems are designed
- [ ] Prototype highest-risk system: `/prototype core-combat`
- [ ] Plan first sprint: `/sprint-plan new`
