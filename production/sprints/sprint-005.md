# Sprint 5 — 2026-05-18 to 2026-06-01

## Sprint Goal
实现"死亡→赚碎片→解锁→更强→再挑战"的局外 meta-progression 循环，让每次死亡都有意义。

## Capacity
- Total days: 14
- Buffer (20%): 3 days
- Available: 11 days (~8-10 sessions)

## Architecture Context
- ADR-0001 允许 v1.0 引入场景管理器（MVP 单场景→v1.0 多场景）
- 新增 1 个 Autoload: MetaProgress（持久化碎片+解锁状态）
- 遵循现有通信模式：EventBus 信号 + 节点引用

## Tasks

### Must Have (核心循环)

| ID | Task | Owner | Est. Sessions | Dependencies | Acceptance Criteria |
|----|------|-------|---------------|-------------|-------------------|
| S5-01 | MetaProgress Autoload + 持久化框架 | gameplay-programmer | 1.5 | — | `MetaProgress` 注册为 Autoload；`user://profile.json` 读写正确；`add_shards(n)` 累加+持久化；`is_unlocked(id)` 查询；`purchase(id, cost)` 购买+扣碎片 | ✅ Done |
| S5-02 | 碎片掉落 + 战斗中收集 | gameplay-programmer | 1.5 | S5-01 | 击杀敌人掉碎片（近战=3, 远程=4, 冲锋者=8, 自爆者=5, 重装兵=12, 精英2x）；碎片自动吸向玩家（拾取范围100px）；战斗 HUD 显示当前碎片数 | ✅ Done |
| S5-03 | 解锁树数据 + UnlockTreeManager | gameplay-programmer | 2 | S5-01 | 8 个 `MetaUnlockData.tres` 定义；`UnlockTreeManager` 加载+验证解锁条件；`purchase(id)` 扣碎片+标记解锁+发出 `item_unlocked` 信号；持久化到 profile.json | ✅ Done |
| S5-04 | 结算界面：统计+碎片+返回菜单 | gameplay-programmer + ui-programmer | 2 | S5-02, S5-01 | 死亡后展示：波次/击杀/分数/碎片收入；碎片累加动画 0.5s；"继续"按钮→返回主菜单；EventBus 新增 `run_completed(stats, shards_earned)` | ✅ Done |

### Should Have (主菜单 + 解锁 UI)

| ID | Task | Owner | Est. Sessions | Dependencies | Acceptance Criteria |
|----|------|-------|---------------|-------------|-------------------|
| S5-05 | 主菜单扩展 + 解锁树面板 | ui-programmer | 2 | S5-03 | 主菜单显示当前碎片数；"Meta Upgrades"按钮打开解锁面板；节点以树形/网格排列；已解锁显示✅；可解锁显示碎片价格；不可解锁灰显+显示前置条件 | ✅ Done |
| S5-06 | Meta-unlock 效果应用到游戏内 | gameplay-programmer | 1.5 | S5-03 | 解锁"新武器"→武器选择界面可选；解锁"起始生命+" → 每局开始+HP；解锁"起始碎片+" → 每局开始自动获得碎片；解锁"弹药恢复+" → 弹药回复加速 | ✅ Done |

### Nice to Have

| ID | Task | Owner | Est. Sessions | Dependencies | Acceptance Criteria |
|----|------|-------|---------------|-------------|-------------------|
| S5-07 | 生涯统计面板 | ui-programmer | 1 | S5-01 | 总击杀/总死亡/最高波次/总碎片/解锁进度百分比；主菜单"Statistics"按钮；数据来自 MetaProgress |
| S5-08 | 解锁特效 + 音效反馈 | technical-artist | 1 | S5-05 | 购买解锁时粒子爆发+音效；首次解锁时大提示文字 |

## MetaUnlock 内容设计 (8 个解锁节点)

```
                ┌──────────────┐
                │ 起始生命+25   │ ← 100 碎片，无前置
                └──┬───────┬───┘
        ┌──────────┘       └──────────┐
        ▼                              ▼
┌──────────────┐              ┌──────────────┐
│ 弹药恢复+30% │              │ 闪避冷却-0.3s│
│   150 碎片   │              │   150 碎片   │
└──────┬───────┘              └──────┬───────┘
       │                             │
       ▼                             ▼
┌──────────────┐              ┌──────────────┐
│ 解锁：长剑    │              │ 解锁：弩      │
│   200 碎片   │              │   200 碎片   │
└──────────────┘              └──────┬───────┘
                                    │
       ┌────────────────────────────┘
       ▼
┌──────────────┐       ┌──────────────┐
│ 解锁：步枪    │       │ 起始碎片+10   │
│   300 碎片   │       │   300 碎片   │
└──────────────┘       └──────────────┘
```

## EventBus 新增信号

```gdscript
# 碎片
signal shard_collected(amount: int, total: int)
signal shards_changed(new_total: int)

# 解锁
signal item_unlocked(unlock_id: String)
signal item_purchase_failed(unlock_id: String, reason: String)

# 流程
signal run_completed(stats: RunStats, shards_earned: int)
signal profile_loaded
```

## Dependencies on External Factors
- 无外部依赖

## Definition of Done for this Sprint
- [ ] 死亡→结算→主菜单→再开始的完整流程可走通
- [ ] 碎片在战斗中获得、死亡后累加、用于解锁
- [ ] 8 个解锁节点全部可购买+持久化
- [ ] Meta-unlock 效果在下一局正确应用
- [ ] 所有 GUT 测试保持通过
- [ ] 新增信号在 EventBus 中定义
