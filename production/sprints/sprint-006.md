# Sprint 6 — 2026-06-17 起

## Sprint Goal
闭环：让游戏有"赢"的终点，激活已设计的 20 波节奏，补齐引导与生涯统计——把当前无限试炼变成完整的输赢 roguelite 闭环。

## Capacity
- Total days: 14
- Buffer (20%): 3 days
- Available: 11 days (~8-10 sessions)

## Architecture Context
- 沿用 EventBus 信号 + Autoload 通信模式（EventBus / GameConfig / Locale / MetaProgress）
- 复用 GameOverUI 的视觉模式构建 VictoryUI
- wave_config.tres 是数据真相；wave_data.gd create_default() 是设计真相——本 sprint 让两者一致

## 已决策项
- **决策 A**：删除 `max_ammo` 死代码（不重新启用装弹）——当前无限弹药手感已定，回退不划算
- **决策 B**：胜利后可选"继续无尽挑战"——保留高分追求

## Tasks

### Must Have（闭环核心）

| ID | Task | Est. Sessions | Dependencies | Acceptance Criteria |
|----|------|---------------|-------------|-------------------|
| S6-01 | 修复波次配置至 20 波 | 1 | — | `wave_config.tres` 包含完整 20 波（含 11-13 DPS 门槛、14 E 类引入、20 最终 Boss）；`_fixup_wave_data()` 在 `waves.size() < 20` 时回退到 `create_default()`；wave 9/11-13/14/20 在游戏中可验证出现 |
| S6-02 | 胜利条件 + VictoryUI | 1.5 | S6-01 | EventBus 新增 `run_won(stats, shards_earned)`；wave 20 Boss 死亡触发胜利；新增 `victory_ui.gd`（仿 game_over_ui）显示通关结算 + 通关碎片奖励；提供"继续无尽挑战"与"返回主菜单"按钮；MetaProgress 记录通关 |
| S6-03 | 生涯统计面板 | 1 | — | 主菜单新增 "Statistics" 按钮；新建 `statistics_ui.gd` 展示 `lifetime_stats`（总击杀/总死亡/最高波/总碎片/解锁进度%）；"返回"按钮回主菜单 |

### Should Have（引导与清理）

| ID | Task | Est. Sessions | Dependencies | Acceptance Criteria |
|----|------|---------------|-------------|-------------------|
| S6-04 | 首次引导控制提示 | 1 | — | 首局开始时叠加控制提示（WASD 移动/LMB 右手/RMB 左手/Space 闪避/ESC 暂停）；5s 自动淡出或玩家首次操作后立即消失；可通过 settings 标记"已看过"避免重复 |
| S6-05 | 清理 max_ammo 死代码 | 1 | — | 删除 `WeaponData.max_ammo` 字段及校验；删除 weapon_select_ui 中弹药列；删除 `combat_hud.gd` 弹药注释；移除 locale 中 ammo 键；所有 .tres 武器文件移除 max_ammo 行 |
| S6-06 | 设置键位重绑 | 1.5 | — | settings_ui 新增键位重绑区（移动/攻击/闪避/暂停）；settings_manager 持久化自定义键位到 settings.cfg；启动时应用覆盖 InputMap |

### Nice to Have（技术债）

| ID | Task | Est. Sessions | Dependencies | Acceptance Criteria |
|----|------|---------------|-------------|-------------------|
| S6-07 | 重构 enemy.gd (917 行/10 FSM) | 2-3 | — | 拆分为 EnemyBase + 每类型策略脚本，或状态机基类；测试全部通过 |
| S6-08 | 解耦硬编码节点路径 | 0.5 | — | `player.gd:10` `/root/Main/Systems/InputBuffer` 改用 group/signal；`_file_id()` 改用 resource_path 推导 |

## EventBus 新增信号

```gdscript
signal run_won(stats: RunStats, shards_earned: int)
```

## 影响文件清单

- `assets/data/wave_config.tres`（重写为 20 波）
- `src/core/wave_data.gd`（_fixup_wave_data 强化）
- `src/gameplay/wave_manager.gd`（新增 WON 状态 + 胜利触发）
- `src/core/event_bus.gd`（新增 run_won）
- `src/ui/victory_ui.gd`（新增）+ `scenes/main.tscn`（挂载）
- `src/ui/statistics_ui.gd`（新增）+ `scenes/main_menu.tscn`（挂载 + 按钮）
- `src/ui/main_menu.gd`（新增 Statistics 按钮）
- `src/ui/tutorial_overlay.gd`（新增）+ 挂载到 main.tscn
- `src/core/weapon_data.gd`（删除 max_ammo）
- `src/ui/weapon_select_ui.gd`（删除弹药列）
- `src/ui/settings_ui.gd` + `src/gameplay/settings_manager.gd`（键位重绑）
- `src/core/locale.gd`（新增 victory/tutorial/statistics 键，删除 ammo）
- `assets/data/weapons/*.tres`（移除 max_ammo 行）

## Definition of Done
- [ ] 完整 20 波在游戏中可走通，wave 20 Boss 死亡触发胜利结算
- [ ] 胜利后可选继续无尽或返回主菜单
- [ ] 主菜单可查看生涯统计
- [ ] 首局有控制提示
- [ ] max_ammo 死代码全部清除
- [ ] 设置支持键位重绑
- [ ] 所有 GUT 测试保持通过
- [ ] 新增信号在 EventBus 中定义
