# Sprint 3 — 2026-05-26 to 2026-06-08

## Sprint Goal
�打磨核心体验 → 扩充内容深度 → 搭建 v1.0 基础，把 MVP 从"可玩"推进到"像个游戏"

## Capacity
- Total days: 14
- Buffer (20%): 3 days
- Available: 11 days (~12-16 sessions)

## Tasks

### Must Have (打磨体验)
| ID | Task | Owner | Est. Sessions | Dependencies | Acceptance Criteria |
|----|------|-------|---------------|-------------|-------------------|
| S3-01 | 主菜单场景：开始游戏 / 退出按钮 + 游戏标题 | ui-programmer | 2 | — | 启动显示主菜单；点击"开始游戏"切换到战斗场景；点击"退出"关闭程序 |
| S3-02 | 音效系统：VfxManager 挂载音效播放（命中/击杀/波次/升级） | audio-director + gameplay-programmer | 2 | S2-07 | 近战命中音效、敌人死亡音效、波次开始音效、升级窗口打开音效均可播放；音量可调 |
| S3-03 | 远程敌人 AI：保持距离射击 + 玩家逼近时后撤 | ai-programmer | 3 | S2-08, S1-08 | 远程敌人距离 > shoot_range 逼近、≤ shoot_range 射击、< evade_range 后撤；射击间隔 1.5s |
| S3-04 | 波次难度曲线：敌人 HP/数量/速度随波次递增公式 | systems-designer | 2 | S2-03 | 每波 melee HP +10%、远程 HP +5%；波 6+ 每波额外 +1 近战；移速递增上限 200 |

### Should Have (�容扩充)
| ID | Task | Owner | Est. Sessions | Dependencies | Acceptance Criteria |
|----|------|-------|---------------|-------------|-------------------|
| S3-05 | 新武器：双匕首（极速低伤）+ 霰弹枪（散射多弹） | gameplay-programmer | 2 | S1-05 | 双匕首 0.15s 冷却 8 伤害 60° 扇形；霰弹枪 3 弹散射 15° |
| S3-06 | 精英敌人：每 5 波出现 1 个高 HP 大型敌人（2x 体积/5x HP/2x 伤害） | gameplay-programmer | 2 | S2-02, S3-04 | 精英敌人有独特颜色 / 大小；击杀 +500 分；死亡爆散粒子更大 |
| S3-07 | 升级池扩充：暴击率 / 吸血 / 移速叠加 / 拾取范围（至少 4 个新升级） | gameplay-programmer | 1 | S2-01 | 新 UpgradeData .tres 文件正确加载；draw_upgrades 可抽到新卡 |

### Nice to Have（v1.0 基础）
| ID | Task | Owner | Est. Sessions | Dependencies | Acceptance Criteria |
|----|------|-------|---------------|-------------|-------------------|
| S3-08 | 排行榜：本地 JSON 存储历史最佳 10 局 | gameplay-programmer | 2 | S2-05 | 死亡后自动保存记录；主菜单可查看排行榜；按分数降序 |
| S3-09 | 设置界面：音量滑块 + 窗口模式切换 | ui-programmer | 1 | S3-02 | 主音量 / SFX 音量滑块；全屏 / 窗口下拉；设置持久化到 config 文件 |
| S3-10 | Windows 打包：导出模板 + 一键 .exe 构建 | devops-engineer | 1 | — | `godot --headless --export-release "Windows"` 成功生成 .exe；双击可运行 |

## Dependencies on External Factors
- S3-02 音效需要获取或制作 .ogg 音效文件（可先用免费音效库临时素材）
- S3-10 Windows 打包需要 Godot 导出模板（Editor → Manage Export Templates）

## Definition of Done for this Sprint
- [ ] 所有 Must Have 任务完成（S3-01 到 S3-04）
- [ ] 从主菜单开始 → 战斗 → 死亡 → 排行榜，完整流程可走通
- [ ] 远程敌人和近战敌人行为有明显差异
- [ ] 波次难度递增可感知（后期波次明显更难）
- [ ] 所有 GUT 测试保持通过
- [ ] 60fps 稳定（同屏 20 敌人）
