# Session State — 2026-05-15

<!-- STATUS -->
Epic: Sprint 4 新内容
Task: 全部实现完成，Parse error 已修复，待用户运行测试
<!-- /STATUS -->

## Sprint 4: 5/5 ✅

### S4-01~03: 3 种新敌人
- 冲锋者: 追踪→蓄力→冲刺→硬直，击退抗性 50%，红色
- 自爆者: 高速追踪→<40px闪烁预警→AoE 80px/25伤害，死亡爆炸
- 重装兵: 正面180°减伤50%，2x体积，慢速

### S4-04: 6 个新升级
- 伤害光环/击杀爆炸/荆棘护甲/攻击加速/生命回复/弹药扩容

### S4-05: 波次配置
- 10波默认配置，新敌人按波次递增加入

## 修改文件清单 (12个)
src/gameplay/enemy.gd, spawn_manager.gd, wave_manager.gd, player.gd, combat_system.gd
src/effects/vfx_manager.gd, src/core/event_bus.gd, wave_config.gd, wave_data.gd
assets/data/enemies/{charger,exploder,tank}.tres
assets/data/upgrades/{damage_aura,kill_explosion,thorn_reflect,attack_speed_up,hp_regen,max_ammo_up}.tres
assets/data/wave_config.tres

## Bug 修复
- enemy.gd:123 — source: Node 无 global_position，加 Node2D cast
- enemy.gd:430 — kill_dmg 类型无法推断，显式声明 :float
