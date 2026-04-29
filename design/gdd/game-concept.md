# Game Concept: 猎场 (Hunting Ground)

*Created: 2026-04-22*
*Status: Draft*

---

## Elevator Pitch

> 竞技场生存动作游戏——一人对抗潮水般涌来的敌人，靠混合战斗（近战+远程）和波次间升级极限存活。每一局都是一次完整的"成长-死亡-再挑战"循环，局外解锁让你每次倒下都变得更强。

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | 动作生存 / Roguelite / 波次竞技场 |
| **Platform** | PC (Steam) |
| **Target Audience** | 中核动作玩家，喜欢挑战和 Roguelite 循环 |
| **Player Count** | 单人 |
| **Session Length** | 15-45 分钟 |
| **Monetization** | 无（个人项目） |
| **Estimated Scope** | 小（几周，独狼新手） |
| **Comparable Titles** | Vampire Survivors, Brotato, Risk of Rain 2, Hades |

---

## Core Fantasy

你是一名孤独的战士，被困在一座无尽的竞技场中。四面八方涌来的敌人想要你的命，但你有一把近战武器、一把远程武器，以及不断进化的战斗本能。每一波战斗都更凶险，但你也在每次波次间变得更强。倒下不是终点——你带回的碎片让你在下一次挑战中走得更远。

核心体验：**在绝望中掌控局面，在死亡中积累经验，在重复中突破极限。**

---

## Unique Hook

像 *Vampire Survivors* 一样上瘾，**AND ALSO** 拥有近战+远程的混合战斗深度和波次间三选一升级的策略感。不是"站桩等怪来"，而是主动选择战斗节奏——近战收割、远程压制、灵活切换。

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Challenge** | 1 (核心) | 递增的波次难度，要求持续精进操作 |
| **Sensation** | 2 | 命中反馈、屏幕震动、音效、粒子特效 |
| **Expression** | 3 | 升级组合的 build 多样性 |
| **Discovery** | 4 | 解锁新内容、发现升级组合的协同效应 |
| **Fantasy** | 5 | 孤胆英雄的生存幻想 |
| **Narrative** | N/A | 不做叙事 |
| **Fellowship** | N/A | 单人游戏 |
| **Submission** | N/A | 游戏是紧张的，不追求放松 |

### Key Dynamics

- 玩家在近战和远程之间动态切换，根据敌人类型和局势调整策略
- 升级选择会自然形成不同的 build 流派（近战流、远程流、闪避流等）
- 玩家在高压下做出风险-收益判断（冲上去近战更危险但伤害更高）
- 局外解锁驱动"再来一局"的循环

### Core Mechanics

1. **混合战斗系统** — 近战高伤害高风险 + 远程安全但弹药有限，自由切换
2. **波次系统** — 敌人按波次涌来，难度递增
3. **局内升级** — 每 3-5 波后三选一强化
4. **局外解锁** — 死亡后获得碎片，永久解锁新武器/能力/加成
5. **闪避系统** — 带无敌帧的闪避，操作核心

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** | 升级三选一、战斗风格自由选择、build 多样性 | Core |
| **Competence** | 清晰的波次进度、死亡后解锁、技术提升可见 | Core |
| **Relatedness** | 无社交系统 | Minimal |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** — 突破最高波次记录、解锁全部内容
- [x] **Killers/Competitors** — 挑战极限、追求无伤/高分
- [ ] **Explorers** — 有限的探索元素（主要聚焦战斗）
- [ ] **Socializers** — 无社交

### Flow State Design

- **Onboarding curve**: 前 3 波敌人极少、移动缓慢，让玩家熟悉近战/远程/闪避三种操作
- **Difficulty scaling**: 每波增加敌人数量、速度、引入新敌人类型
- **Feedback clarity**: 清晰的波次计数、分数、死亡原因、解锁进度
- **Recovery from failure**: 死亡后 3 秒即可重新开始，失败成本低但有收获（碎片）

---

## Core Loop

### Moment-to-Moment (30 秒)

玩家在竞技场中不断移动、切换武器、攻击敌人、闪避伤害。近战贴身输出高风险高回报，远程保持距离但弹药有限。每一秒都在做判断：靠近还是拉开？砍还是射？闪避还是硬扛？

### Short-Term (5-15 分钟)

连续 3-5 波战斗后出现升级窗口——从随机 3 个强化中选择 1 个。选择后立即进入下一组波次，验证升级效果。这个"战斗-升级-再战斗"的循环制造"再来一波"的冲动。

### Session-Level (30-60 分钟)

从第 1 波开始战斗，难度逐渐攀升，直到某波倒下。结算画面显示：最高波次、击杀数、获得碎片、解锁内容。碎片用于局外商店永久强化。自然停止点：解锁了一个重要内容，或刷新了记录。

### Long-Term Progression

- **局外解锁树**: 用碎片解锁新武器、新角色被动、起始加成
- **技术成长**: 玩家对敌人行为的理解和操作精进
- **目标**: 解锁全部内容 + 挑战最高波次记录

### Retention Hooks

- **Curiosity**: 未解锁的内容、未知的升级组合
- **Investment**: 已投入时间积累的解锁进度
- **Mastery**: 突破自己的最高波次记录、尝试不同 build

---

## Game Pillars

### Pillar 1: 每一秒都在做选择

玩家在任意时刻都面临至少两个有意义的选择：靠近还是远离？近战还是远程？闪避还是输出？没有"最优解"，只有情境判断。

*Design test*: 如果某个升级让玩家无脑选同一个方案，砍掉它。

### Pillar 2: 死亡有意义

每次死亡都带来局外成长——解锁新内容或永久变强。玩家倒下时的感觉不是"浪费时间"，而是"又攒了一点，下次更强"。

*Design test*: 如果连续玩三局都没有任何永久收获，说明局外系统失败了。

### Pillar 3: 操作感即玩法

美术和叙事可以极简，但手感不能妥协。近战命中要有反馈，远程射击要有弹道感，闪避要有无敌帧的爽感。

*Design test*: 如果把特效和音效关掉后操作变得无聊，说明手感依赖包装而非机制本身。

### Pillar 4: 小而深

游戏只有一个竞技场、一套核心机制，但这套机制要挖到足够深。通过敌人组合、波次编排和升级组合创造变化，而不是堆内容量。

*Design test*: 如果某个功能需要大量美术资产或关卡才能体现价值，不做。

### Anti-Pillars (What This Game Is NOT)

- **NOT 多人模式**: 独狼开发，几周时间，网络同步会吃掉所有时间
- **NOT 复杂叙事**: 核心循环是战斗，叙事会分散开发精力
- **NOT 开放世界**: 一个竞技场就够了，范围管控是项目存活的关键
- **NOT 自动战斗**: 玩家的操作输入是核心体验，挂机玩法会毁掉它

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| **Vampire Survivors** | "再来一局"的成瘾循环、波次压力感 | 我们做主动战斗（非自动攻击），操作深度更高 | 验证了波次生存玩法的市场 |
| **Brotato** | 波次间升级的三选一节奏、极简美术 | 我们做近战+远程混合，不只是远程 | 验证了极简美术也能好玩 |
| **Hades** | 局外解锁驱动循环、死亡即进步 | 我们不做叙事和关卡，纯竞技场 | 验证了 Roguelite 死亡循环的吸引力 |
| **Risk of Rain 2** | 升级叠加的爽感、build 多样性 | 我们做 2D 极简版，缩小体量 | 验证了升级组合的长期吸引力 |

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 18-35 |
| **Gaming experience** | 中核（有游戏经验，但非硬核） |
| **Time availability** | 工作日晚间 30-60 分钟碎片时间 |
| **Platform preference** | PC (Steam) |
| **Current games they play** | Hades, Vampire Survivors, Brotato, Dead Cells |
| **What they're looking for** | 操作感强、有成长反馈、随时能停的动作游戏 |
| **What would turn them away** | 太难没有成长、手感差、内容重复无变化 |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot 4.6 — 2D 性能优秀，GDScript 新手友好，内置碰撞和粒子系统 |
| **Key Technical Challenges** | 手感调优（命中判定、反馈 timing）、敌人 AI（追踪、包抄） |
| **Art Style** | 极简 2D 几何 — 方块、圆、三角 + 高对比色 |
| **Art Pipeline Complexity** | 低 — Godot 内置 Shape2D + 粒子即可，无需外部美术 |
| **Audio Needs** | 基础 — 命中音效、升级音效、BGM（可用免费素材） |
| **Networking** | 无（纯单人） |
| **Content Volume** | 1 个竞技场、5-10 种敌人、10-15 种升级、3-5 种武器 |
| **Procedural Systems** | 升级池随机抽取、敌人波次随机组合 |

---

## Risks and Open Questions

### Design Risks

- **核心循环无法持续 30+ 分钟** — 如果升级组合不够有趣，玩家 15 分钟后就腻了
- **难度曲线失控** — 太简单无聊，太难劝退新手
- **近战/远程不平衡** — 如果一种武器永远更优，混合战斗就失去了意义

### Technical Risks

- **手感调优困难** — Godot 2D 碰撞和命中判定需要反复调试
- **新手不熟悉 Godot** — 需要额外学习时间

### Market Risks

- **竞技场生存类型已有大量竞品** — 需要足够差异化才能被注意
- **作为新手作品可能缺乏市场竞争力**

### Scope Risks

- **局外解锁系统可能膨胀开发时间** — MVP 阶段不做，验证核心循环后再加
- **敌人种类过多导致美术工作量失控** — 先用几何占位符

### Open Questions

- 近战和远程的伤害比例应该是多少？（需要原型测试）
- 波次间隔多长时间合适？（需要 playtest 验证节奏）
- 升级池应该有多大才不会重复感？（先做 5 种验证）

---

## MVP Definition

**Core hypothesis**: 混合战斗（近战+远程）+ 波次生存 + 波次间三选一升级 的核心循环能在 30 分钟内保持玩家投入。

**Required for MVP**:
1. 1 个竞技场（简单矩形房间）
2. 1 个玩家角色（方块）+ 近战攻击 + 远程射击 + 闪避
3. 2 种敌人（近战冲向玩家 + 远程射击）
4. 波次系统（5 波，难度递增）
5. 局内升级（3-5 种升级，波次间三选一）
6. 基础 UI（血量、波次、分数）

**Explicitly NOT in MVP**:
- 局外解锁系统（核心循环验证后再加）
- 多种武器切换（MVP 只用 1 近 1 远）
- 完整美术（先用几何占位符）
- 音效和音乐（验证玩法后再加）

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 1 竞技场、2 敌人、1 角色 | 核心战斗+波次+升级 | 2-3 周 |
| **v1.0** | 5+ 敌人、10+ 升级 | +局外解锁、基础特效 | +2-3 周 |
| **完整版** | 全武器、全角色变体 | +音效、排行榜、成就 | +4-6 周 |
| **梦想版** | 每日挑战、社区排行榜 | +模组支持 | 有余力再说 |

---

## Next Steps

- [ ] Configure engine: `setup-engine` Godot 4.6
- [ ] Design review: `design-review design/gdd/game-concept.md`
- [ ] Systems mapping: `map-systems` — 拆解系统、规划 GDD 编写顺序
- [ ] Architecture decision: `architecture-decision` — 确定技术架构
- [ ] Core loop prototype: `prototype core-combat` — 验证混合战斗手感
- [ ] Playtest: `playtest-report` — 验证 MVP 假设
- [ ] Sprint planning: `sprint-plan new` — 规划第一个迭代
