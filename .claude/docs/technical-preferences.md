# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript (primary), C++ via GDExtension (performance-critical)
- **Rendering**: Forward+ (default), 2D-optimized pipeline
- **Physics**: Godot Physics (default, includes Jolt option)

## Naming Conventions

- **Classes**: PascalCase (e.g., `PlayerController`, `EnemyMelee`)
- **Variables/Functions**: snake_case (e.g., `move_speed`, `take_damage()`)
- **Signals**: snake_case past tense (e.g., `health_changed`, `enemy_died`)
- **Files**: snake_case matching class (e.g., `player_controller.gd`, `enemy_melee.tscn`)
- **Scenes**: PascalCase matching root node (e.g., `PlayerController.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`, `BASE_DAMAGE`)

## Performance Budgets

- **Target Framerate**: 60fps
- **Frame Budget**: 16.6ms
- **Draw Calls**: < 200 (2D minimalist art should stay well under 50)
- **Memory Ceiling**: 512MB

## Testing

- **Framework**: GUT (Godot Unit Testing)
- **Minimum Coverage**: 60% on gameplay systems
- **Required Tests**: Balance formulas, combat mechanics, wave spawning logic

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

- [ADR-0001: Project Node Architecture](../docs/architecture/adr-0001-project-node-architecture.md) — 最小 Autoload + 信号总线 + 单场景
