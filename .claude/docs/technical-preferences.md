# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript (primary), C++ via GDExtension (performance-critical)
- **Rendering**: Forward+ (default), 2D-optimized pipeline
- **Physics**: Godot Physics (default, includes Jolt option)

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: [TO BE CONFIGURED — e.g., PC, Console, Mobile, Web]
- **Input Methods**: [TO BE CONFIGURED — e.g., Keyboard/Mouse, Gamepad, Touch, Mixed]
- **Primary Input**: [TO BE CONFIGURED — the dominant input for this game]
- **Gamepad Support**: [TO BE CONFIGURED — Full / Partial / None]
- **Touch Support**: [TO BE CONFIGURED — Full / Partial / None]
- **Platform Notes**: [TO BE CONFIGURED — any platform-specific UX constraints]

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

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist
- **Shader Specialist**: godot-shader-specialist
- **UI Specialist**: godot-gdscript-specialist
- **Additional Specialists**: gameplay-programmer, ai-programmer, engine-programmer
- **Routing Notes**: Use godot-specialist for engine-specific API questions and scene architecture

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (primary language) | godot-gdscript-specialist |
| Shader / material files | godot-shader-specialist |
| UI / screen files | godot-gdscript-specialist |
| Scene / prefab / level files | godot-specialist |
| Native extension / plugin files | godot-gdextension-specialist |
| General architecture review | technical-director |
