# Sprint 4 — 2026-05-15 to 2026-05-29

## Sprint Goal
扩充敌人种类和升级池深度，从 2 种敌人 → 5 种、9 个升级 → 15 个，增加战术多样性和构筑深度。

## Capacity
- Total days: 14
- Buffer (20%): 3 days
- Available: 11 days (~8 sessions)

## Tasks

### Must Have (敌人扩充)
| ID | Task | Owner | Est. Sessions | Dependencies | Acceptance Criteria |
|----|------|-------|---------------|-------------|-------------------|
| S4-01 | 冲锋者敌人：周期性锁定冲刺 + 冲刺后硬直 + 击退抗性 | ai-programmer + gameplay-programmer | 2 | — | 每 3-5s 锁定玩家方向冲刺；冲刺速度 500px/s；冲刺后硬直 0.8s；击退距离减半；有独特视觉 |
| S4-02 | 自爆者敌人：接近自爆 + 死亡爆炸 + AoE 伤害 | gameplay-programmer | 2 | — | 高速追踪玩家；距离 < 40px 自爆；死亡时爆炸；爆炸半径 80px；爆炸伤害 25；有闪烁预警 |
| S4-03 | 重装兵敌人：高HP + 正面减伤50% + 慢速 | gameplay-programmer | 1.5 | — | HP 3x 普通近战；正面 180° 减伤 50%；移速 80px/s；体积 2x；背面正常受伤 |

### Should Have (升级扩充)
| ID | Task | Owner | Est. Sessions | Dependencies | Acceptance Criteria |
|----|------|-------|---------------|-------------|-------------------|
| S4-04 | 新升级 x6：伤害光环/击杀爆炸/荆棘护甲/攻击加速/生命回复/弹药扩容 | gameplay-programmer | 1.5 | — | 6 个 .tres 文件可加载；draw_upgrades 可抽到新卡；效果正确应用 |

### Nice to Have
| ID | Task | Owner | Est. Sessions | Dependencies | Acceptance Criteria |
|----|------|-------|---------------|-------------|-------------------|
| S4-05 | 波次配置更新：新敌人加入波次生成表 + 难度曲线调整 | systems-designer | 1 | S4-01~S4-03 | 波 3+ 出冲锋者；波 5+ 出自爆者；波 8+ 出重装兵；精英变体正常 |

## New Enemies Detail

### Charger (冲锋者)
- HP: 60, Speed: 150, Contact: 20, Knockback Resist: 50%
- AI: track → lock_direction → charge(500px/s, 0.5s) → stun(0.8s) → repeat
- Visual: 红色调，冲刺时拉长

### Exploder (自爆者)
- HP: 20, Speed: 250, Contact: 0 (no contact damage)
- AI: rush toward player → explode at < 40px or on death
- Explosion: radius 80px, damage 25, 0.3s blink warning
- Visual: 橙色闪烁

### Tank (重装兵)
- HP: 90, Speed: 80, Contact: 25
- Front shield: 180° arc, 50% damage reduction
- Visual: 灰色大尺寸，正面有护盾标记

## New Upgrades Detail

| Upgrade | Target Stat | Modifier | Value | Rarity | Max Stacks |
|---------|-------------|----------|-------|--------|------------|
| 伤害光环 | damage_aura | ADD_ABSOLUTE | 5 | UNCOMMON | 5 |
| 击杀爆炸 | kill_explosion | ADD_ABSOLUTE | 1 | RARE | 3 |
| 荆棘护甲 | thorn_reflect | ADD_PERCENT | 0.15 | UNCOMMON | 3 |
| 攻击加速 | attack_speed | ADD_PERCENT | -0.10 | COMMON | 5 |
| 生命回复 | hp_regen | ADD_ABSOLUTE | 2 | UNCOMMON | 5 |
| 弹药扩容 | max_ammo | ADD_ABSOLUTE | 3 | COMMON | 3 |

## Dependencies on External Factors
- 无外部依赖

## Definition of Done for this Sprint
- [x] 所有 Must Have 任务完成（S4-01 到 S4-03）
- [x] 3 种新敌人各有不同的行为模式和视觉区分
- [x] 6 个新升级全部生效
- [x] 波次配置包含所有 5 种敌人
- [x] 所有 GUT 测试保持通过 (26/26 passed)
- [ ] 60fps 稳定（同屏 30 敌人含新类型）— 需手动 gameplay 测试
