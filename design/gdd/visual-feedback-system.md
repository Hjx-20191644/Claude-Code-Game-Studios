# 视觉反馈系统 (Visual Feedback System)

> **Status**: Approved
> **Author**: user + agents
> **Last Updated**: 2026-04-27
> **Implements Pillar**: 操作感即玩法

## Overview

视觉反馈系统是游戏"手感"的来源——命中时的屏幕震动、闪避时的残影、受伤时的红色闪烁、击杀时的粒子爆发。它监听战斗和伤害事件，在正确的时刻触发正确的视觉特效，让每一次操作都有可感知的回应。本系统不修改任何游戏逻辑（伤害数值由生命/伤害系统决定，无敌帧由闪避系统决定），它只做一件事：**让发生的事被看见**。

## Player Fantasy

你一刀砍中敌人——刀口处迸出一小团白色粒子，手感扎实。你闪避滑开——角色拖出半透明残影，无敌帧的那一瞬间你觉得自己真的"穿过"了攻击。敌人打中你——角色闪红，屏幕微微一震加边缘红晕，你知道疼了。最后一下击杀——敌人碎成几个方块四散飞出，有瞬间膨胀再消散的满足感。每一帧画面都在回应你的操作。

## Detailed Design

### 1. 反馈事件总览

| 事件 | 触发信号 | 视觉效果 | 来源系统 |
|------|---------|---------|---------|
| 玩家近战命中 | `damage_dealt` + 近战 | 命中点白色粒子爆发 | 混合战斗/生命伤害 |
| 玩家远程命中 | `damage_dealt` + 远程 | 命中点橙色粒子爆发 | 混合战斗/生命伤害 |
| 玩家受伤 | `damage_taken` | 角色闪红 + 屏幕震动 + 边缘红晕 | 生命/伤害 |
| 玩家闪避 | `dodge_started` | 角色残影拖尾 | 闪避 |
| 敌人击杀 | `enemy_killed` | 敌人死亡爆散粒子 | 生命/伤害 |
| 玩家死亡 | `player_died` | 屏幕灰化 + 缓慢缩放 | 生命/伤害 |

### 2. 各效果详细规格

**近战命中粒子**：
- 位置：命中点（敌人位置偏移）
- 粒子数：5-8 个白色小方块
- 方向：从命中点向外辐射
- 生命周期：0.3s 淡出
- 速度：50-150 px/s 随机

**远程命中粒子**：
- 位置：命中点
- 粒子数：4-6 个橙色小方块
- 方向：沿弹道方向散射
- 生命周期：0.2s 淡出
- 速度：80-120 px/s

**角色受伤闪红**：
- 角色 sprite 短暂叠加红色（modulate = Color.RED）
- 持续 0.1s 后恢复
- 使用 Tween 实现

**屏幕震动（仅受伤时）**：
- 类型：Camera2D `shake` 偏移
- 强度：4px 随机偏移
- 时长：0.15s
- 衰减：线性衰减到 0

**边缘红晕（仅受伤时）**：
- 屏幕四边半透明红色渐晕
- 强度：alpha 0.3
- 持续：0.3s 淡出
- 使用 CanvasLayer + ColorRect 实现

**闪避残影**：
- 类型：角色 sprite 的半透明副本
- 透明度：alpha 0.4
- 数量：闪避路径上每 3 帧留一个残影
- 生命周期：0.3s 淡出
- 颜色：略带蓝色偏移（区别于正常角色）

**敌人死亡爆散**：
- 位置：敌人位置
- 粒子数：8-12 个方块，颜色取敌人颜色
- 方向：向四周爆散
- 生命周期：0.5s，先膨胀再缩小消失
- 速度：100-250 px/s 随机

**玩家死亡**：
- 屏幕逐渐灰化（0.5s 内 saturation → 0）
- Camera2D 缓慢缩放（0.5s 内 zoom 1.0 → 1.2）
- 时间减速（0.5s 内 time_scale 1.0 → 0.3），持续 1s 后完全停止

### 3. 实现方式

- 粒子效果：Godot GPUParticles2D 或 CPUParticles2D（MVP 用 CPUParticles2D，数量少性能足够）
- 屏幕震动：Camera2D offset 偏移 + Tween
- 角色闪红：Sprite2D modulate + Tween
- 边缘红晕：CanvasLayer + ColorRect + Shader 或渐变 Texture
- 残影：动态创建 Sprite2D 副本 + Tween 淡出
- 死亡效果：WorldEnvironment 色彩调整 + Camera2D zoom + Engine.time_scale

### 4. 信号监听

| 信号 | 来源 | 处理 |
|------|------|------|
| `damage_dealt` | `amount: float, hit_position: Vector2, attack_type: String` | 生命/伤害系统 | 在 hit_position 生成命中粒子（近战=白色，远程=橙色） |
| `damage_taken` | `amount: float, position: Vector2` | 生命/伤害系统 | 角色闪红 + 屏幕震动 + 边缘红晕 |
| `dodge_started` | （无参数） | 闪避系统 | 开始生成残影 |
| `enemy_killed` | `kill_type: String, position: Vector2, enemy_color: Color` | 生命/伤害系统 | 在 position 生成死亡爆散 |
| `player_died` | （无参数） | 生命/伤害系统 | 触发死亡效果序列 |

## Formulas

### 屏幕震动

```
# 每帧偏移（震动期间）
offset_x = randf_range(-shake_intensity, shake_intensity) * decay_factor
offset_y = randf_range(-shake_intensity, shake_intensity) * decay_factor

# 衰减因子
decay_factor = 1.0 - (elapsed_time / shake_duration)

# 默认值
shake_intensity = 4.0    # px
shake_duration = 0.15    # 秒
```

### 粒子速度

```
# 命中粒子
speed = randf_range(particle_speed_min, particle_speed_max)
direction = Vector2(randf(), randf()).normalized()

# 死亡爆散
speed = randf_range(100, 250)
direction = Vector2(cos(angle), sin(angle))  # angle 均匀 0-2π
```

### 变量表

| 变量 | 类型 | 范围 | 来源 | 说明 |
|------|------|------|------|------|
| `shake_intensity` | float | 1-10 px | 调参旋钮 | 屏幕震动强度 |
| `shake_duration` | float | 0.05-0.3 s | 调参旋钮 | 震动持续时间 |
| `afterimage_alpha` | float | 0.1-0.6 | 调参旋钮 | 闪避残影透明度 |
| `afterimage_lifetime` | float | 0.1-0.5 s | 调参旋钮 | 残影存续时长 |
| `hit_flash_duration` | float | 0.05-0.2 s | 调参旋钮 | 受伤闪红时长 |
| `vignette_alpha` | float | 0.1-0.5 | 调参旋钮 | 边缘红晕最大强度 |

## Edge Cases

| 场景 | 预期行为 | 理由 |
|------|---------|------|
| 同一帧多次受伤 | 震动和闪红不叠加，重置计时器重新播放 | 避免连续受伤时震动/闪红效果失控 |
| 连续快速闪避 | 每次闪避独立生成残影，旧残影自然淡出 | 残影互不干扰，各自生命周期独立 |
| 大量敌人同帧被击杀 | 所有爆散粒子同时生成 | MVP 不做合并优化，数量上限由性能保证 |
| 游戏暂停（升级窗口） | 暂停期间不处理新信号，进行中的特效冻结 | 暂停时视觉静止 |
| 玩家死亡后仍收到信号 | 忽略，死亡效果序列执行后不再响应 | 死亡后特效锁定 |
| Camera2D 不存在 | 屏幕震动跳过，其他效果正常 | 防御性处理，不因缺 Camera 崩溃 |
| 残影在角色被删除后 | 残影独立生命周期，不依赖角色存在 | 残影是独立节点，角色消失后自然淡出 |

## Dependencies

| 依赖系统 | 方向 | 依赖内容 | 状态 |
|---------|------|---------|------|
| 生命/伤害系统 | 上游 → 本系统 | 发出 `damage_dealt`、`damage_taken`、`enemy_killed`、`player_died` 信号 | GDD 已通过 ✅ |
| 混合战斗系统 | 上游 → 本系统 | 通过 `damage_dealt` 信号区分近战/远程攻击类型 | GDD 已通过 ✅ |
| 闪避系统 | 上流 → 本系统 | 发出 `dodge_started` 信号 | GDD 已通过 ✅ |
| Camera2D | 运行时依赖 | 屏幕震动需要场景中存在 Camera2D 节点 | 场景配置 |

**本系统无下游依赖**——视觉反馈是纯表现层，不影响任何游戏逻辑。

**信号需求说明**：本系统需要生命/伤害系统的信号携带更多参数（`hit_position`、`attack_type`、`enemy_color`），需在实现时与生命/伤害系统对齐信号签名。

## Tuning Knobs

| 旋钮 | 类型 | 默认值 | 安全范围 | 影响玩法 | 说明 |
|------|------|--------|---------|---------|------|
| `shake_intensity` | float | 4.0 px | 1-10 px | 打击感 | 受伤震屏强度，0=关闭 |
| `shake_duration` | float | 0.15 s | 0.05-0.3 s | 打击感 | 震屏时长 |
| `afterimage_alpha` | float | 0.4 | 0.1-0.6 | 闪避感知 | 残影透明度，越低越淡 |
| `afterimage_lifetime` | float | 0.3 s | 0.1-0.5 s | 闪避感知 | 残影存续时长 |
| `hit_flash_duration` | float | 0.1 s | 0.05-0.2 s | 受伤感知 | 角色闪红时长 |
| `vignette_alpha` | float | 0.3 | 0.1-0.5 | 受伤感知 | 边缘红晕最大强度 |

**配置方式**：所有旋钮定义在 `assets/data/visual_feedback_config.tres`（Resource 文件），运行时加载，支持热重载调参。

**备注**：视觉反馈的调参对"手感"影响极大，建议在原型阶段就频繁调整这些值。

## Visual/Audio Requirements

**视觉**：已在 Detailed Design 中完整定义。补充总体风格约束：
- 所有粒子使用方块几何体，与游戏极简美术风格统一
- 粒子不使用纹理贴图，纯 Color + 小矩形
- 颜色克制：白色（近战命中）、橙色（远程命中）、红色（受伤）、角色色（死亡爆散）、蓝色偏移（残影）
- 特效时间短（0.1-0.5s），快速爆发快速消失，不拖泥带水

**音频**：
- 本系统不直接播放音效——音频反馈由音效系统（v1.0）负责
- MVP 阶段音效可先硬编码在各触发点，后续迁移到音效系统统一管理
- 本系统可预留音效触发钩子（如 `play_hit_sound()` 占位），待音效系统上线后替换

## UI Requirements

**MVP 阶段：本系统无专属 UI**。

本系统的所有输出都是游戏世界中的视觉效果（粒子、震动、闪烁），不是传统 UI 元素。边缘红晕使用 CanvasLayer 叠加在游戏画面之上，但不属于可交互 UI。

## Acceptance Criteria

| 编号 | 标准 | 验证方式 |
|------|------|---------|
| AC-1 | 近战命中敌人生成白色粒子爆发 | 手动验证：近战攻击敌人，观察命中点粒子 |
| AC-2 | 远程命中敌人生成橙色粒子爆发 | 手动验证：远程攻击敌人，观察命中点粒子 |
| AC-3 | 玩家受伤时角色闪红 0.1s | 手动验证：被敌人攻击，观察角色颜色变化 |
| AC-4 | 玩家受伤时屏幕震动 0.15s | 手动验证：被敌人攻击，观察画面抖动 |
| AC-5 | 玩家受伤时边缘红晕 0.3s | 手动验证：被敌人攻击，观察屏幕边缘 |
| AC-6 | 闪避时生成蓝色残影并 0.3s 淡出 | 手动验证：闪避操作，观察残影 |
| AC-7 | 敌人击杀时生成方块爆散粒子 | 手动验证：击杀敌人，观察爆散效果 |
| AC-8 | 玩家死亡时屏幕灰化 + 缩放 + 时间减速 | 手动验证：角色死亡，观察死亡序列 |
| AC-9 | 同帧多次受伤不叠加震动/闪红 | 单元测试：发送两次 damage_taken，断言只触发一次效果 |
| AC-10 | Camera2D 不存在时屏幕震动跳过，其他效果正常 | 单元测试：移除 Camera，发送信号，断言无崩溃 |

## Open Questions

1. **信号参数已对齐**：`damage_dealt`、`damage_taken`、`enemy_killed`、`player_died` 的信号签名已在生命/伤害系统 GDD 中统一定义 ✅
2. **`dodge_started` 信号已补充**：闪避系统 GDD 已新增此信号定义 ✅
3. **粒子池优化**：MVP 每次创建新 CPUParticles2D 节点，大量同时触发时可能产生 GC 压力。后续可引入对象池复用粒子节点。
4. **死亡时间减速 vs 升级窗口暂停**：玩家死亡时的 time_scale 减速可能与升级窗口暂停冲突，需确保死亡序列执行完毕后才触发结算流程。
5. **低血量持续红晕**：HP 低于 25% 时是否持续显示淡红色边缘红晕（非受伤瞬间的强红晕）？增强危机感但增加实现量，MVP 可后置。
