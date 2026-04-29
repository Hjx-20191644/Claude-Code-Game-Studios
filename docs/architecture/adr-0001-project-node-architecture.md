# ADR-0001: Project Node Architecture

## Status
Accepted

## Date
2026-04-28

## Context

### Problem Statement
猎场是一款 2D 竞技场生存 Roguelite，MVP 阶段只有一个竞技场地图。需要确定 Godot 4.6 项目中场景树的组织方式、全局状态的访问策略、以及 14 个 MVP 系统之间的通信机制。这是所有后续开发的基础架构决策。

### Constraints
- 单人独立开发，架构必须简单易懂
- 第一次使用 Godot 4.6，避免过度设计
- MVP 只有一个竞技场，不需要场景切换
- 目标 60fps / 16.6ms 帧预算，架构不能引入性能瓶颈
- GDScript 为主，不引入 C++ 复杂度

### Requirements
- 14 个 MVP 系统必须能在场景树中清晰定位
- 系统间通信必须明确，避免隐藏依赖
- 全局状态（游戏配置、升级数据）需要跨场景访问
- 必须可单元测试（GUT 框架）
- 新增系统时不需要大规模重构

## Decision

采用**最小 Autoload + 信号总线 + 单场景**架构：

### 1. Autoload 单例（仅 2 个）

| Autoload | 职责 | 访问方式 |
|----------|------|----------|
| `EventBus` | 全局信号总线，系统间解耦通信 | `EventBus.signal_name` |
| `GameConfig` | 游戏配置常量、平衡数据加载 | `GameConfig.get_value()` |

所有其他系统（WaveManager、CombatSystem 等）作为场景子节点存在，不使用 Autoload。

### 2. 单场景结构

```
Main (Node)                          # 项目主场景，运行时不切换
├── Arena (Node2D)                   # 竞技场容器
│   ├── Player (CharacterBody2D)     # 玩家角色
│   ├── Enemies (Node2D)             # 敌人容器，动态生成
│   └── Effects (Node2D)             # 视觉特效容器
├── Systems (Node)                   # 游戏系统节点
│   ├── CombatSystem (Node)          # 伤害计算、命中判定
│   ├── WaveManager (Node)           # 波次生成、难度递增
│   ├── UpgradeManager (Node)        # 局内升级逻辑
│   ├── ScoreManager (Node)          # 分数和统计
│   └── SpawnManager (Node)          # 敌人生成管理
├── HUD (CanvasLayer)                # 游戏内 UI
│   ├── HealthBar
│   ├── WaveInfo
│   ├── ScoreDisplay
│   └── UpgradePanel
└── UI (CanvasLayer)                 # 覆盖层 UI
    ├── PauseMenu
    └── UpgradeSelection
```

### 3. 通信规则

| 通信场景 | 机制 | 示例 |
|----------|------|------|
| 跨系统松耦合 | EventBus 信号 | `CombatSystem → EventBus.enemy_killed → ScoreManager` |
| 父子节点紧耦合 | 直接引用 + 方法调用 | `Main.get_wave_manager().start_wave()` |
| UI ← 数据 | EventBus 信号 | `ScoreManager → EventBus.score_changed → HUD` |
| 配置数据读取 | GameConfig | `GameConfig.get_weapon_data("sword")` |
| 同层系统协作 | EventBus 信号 | `WaveManager → EventBus.wave_completed → UpgradeManager` |

### 4. EventBus 信号定义（MVP）

```gdscript
# event_bus.gd — Autoload
extends Node

# 生命/伤害
signal damage_dealt(source: Node, target: Node, amount: float, damage_type: String)
signal damage_taken(target: Node, amount: float, damage_type: String)
signal enemy_killed(enemy: Node, position: Vector2)
signal player_died

# 波次
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal wave_enemy_count_changed(remaining: int)

# 升级
signal upgrade_offered(upgrades: Array)
signal upgrade_selected(upgrade: Dictionary)
signal upgrade_applied(upgrade: Dictionary)

# 闪避
signal dodge_started
signal dodge_cooldown_changed(remaining: float)

# 分数
signal score_changed(new_score: int)
signal stats_updated

# 玩家状态
signal health_changed(new_health: float, max_health: float)
signal weapon_changed(weapon_data: Dictionary)
```

### Key Interfaces

```gdscript
# GameConfig — Autoload
# 从 Resource 文件加载所有平衡数据
func get_weapon_data(weapon_id: String) -> Dictionary
func get_upgrade_data(upgrade_id: String) -> Dictionary
func get_wave_config(wave_number: int) -> Dictionary
func get_enemy_data(enemy_id: String) -> Dictionary
```

## Alternatives Considered

### Alternative 1: Autoload 多单例
- **Description**: GameManager、WaveManager、UpgradePool 等全部设为 Autoload，任意位置直接访问
- **Pros**: 代码最简单，不需要传递引用，新手最直觉
- **Cons**: 隐藏依赖——任何脚本都能调用任何系统；无法单元测试（全局状态污染）；系统越多越混乱
- **Rejection Reason**: 14 个 MVP 系统全做 Autoload 会导致意大利面条式耦合，违背 coding-standards 的"依赖注入优于单例"原则

### Alternative 2: Owner 引用直接调用
- **Description**: Main 场景拥有所有系统，系统通过 `get_parent().get_node()` 直接调用
- **Pros**: 零间接层，性能最优；调用链清晰可追踪
- **Cons**: 强耦合——改节点路径就全崩；每个系统都要知道其他系统的路径；难以单独测试
- **Rejection Reason**: 耦合度过高，不符合"系统可独立测试"的需求；路径硬编码脆弱

## Consequences

### Positive
- 系统间依赖显式化——通过 EventBus 信号连接，连接关系在 `_ready()` 中声明
- 最少全局状态——仅 2 个 Autoload，减少意外耦合
- 可测试——系统节点可脱离主场景独立实例化和测试
- 单场景避免跨场景状态传递问题——MVP 阶段最简方案
- 新增系统只需：挂载到 Systems 节点 + 连接 EventBus 信号

### Negative
- EventBus 信号连接分散在各系统 `_ready()` 中，需要文档追踪依赖关系
- 单场景模式下，主菜单和结算画面需要用 UI 层模拟而非场景切换
- GameConfig 作为 Autoload 意味着配置数据不能按场景隔离

### Risks
- **信号爆炸风险**: 14 个系统可能产生过多信号。缓解：信号按领域分组（战斗/波次/升级/玩家状态），保持总数 < 20
- **单场景膨胀**: MVP 后增加主菜单/结算等可能需要重构为多场景。缓解：v1.0 阶段再引入场景管理器，当前架构不阻塞
- **EventBus 调试困难**: 信号触发链不直观。缓解：开发期 EventBus 记录所有 emit 和 connect 日志

## Performance Implications
- **CPU**: EventBus 信号分发为 O(n) 连接数，14 个系统的信号量级无性能影响
- **Memory**: 2 个 Autoload 常驻内存，约 < 1MB；系统节点随主场景加载
- **Load Time**: 单场景一次性加载，无运行时场景切换开销
- **Network**: 不适用（MVP 单机）

## Migration Plan
此为项目初始架构决策，无需迁移。实现顺序：

1. 创建 `event_bus.gd` 和 `game_config.gd`，注册为 Autoload
2. 创建 `Main.tscn` 主场景，搭建节点骨架
3. 各系统按依赖顺序（Foundation → Core → Feature → Presentation）逐个实现
4. 每个系统在 `_ready()` 中声明所需的 EventBus 信号连接

## Validation Criteria
- [ ] 所有 MVP 系统可在不修改其他系统的前提下独立实例化
- [ ] EventBus 信号数量 ≤ 20（MVP 阶段）
- [ ] 任意系统可脱离主场景进行 GUT 单元测试
- [ ] 无系统直接引用其他系统节点路径（仅通过 EventBus 或 owner 接口）
- [ ] 主场景运行帧时间 < 0.5ms（不含渲染和物理）

## Related Decisions
- GDD 信号签名定义：各系统 design/gdd/*.md 中的 Dependencies 章节
- 技术偏好：`.claude/docs/technical-preferences.md`
- 引擎版本：`docs/engine-reference/godot/VERSION.md`
