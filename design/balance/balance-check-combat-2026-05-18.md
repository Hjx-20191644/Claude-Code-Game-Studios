# Balance Check: Combat — Weapons, Enemies, Waves

> **Date**: 2026-05-18
> **Domain**: Combat + Progression
> **Verdict**: HEALTHY (after P0/P1/P2 fixes)

## Data Sources
- `assets/data/weapons/*.tres` (11 weapons)
- `assets/data/enemies/*.tres` (5 enemy types)
- `assets/data/upgrades/*.tres` (15 upgrades)
- `assets/data/wave_config.tres`
- `src/core/game_config.gd`
- `src/core/wave_data.gd`

## Issues Found & Fixed

### P0 — Critical
| Issue | Fix | Effect |
|-------|-----|--------|
| SMG DPS 133 (2.7x baseline) | dmg 8→6, bullets 2→1 | DPS → 50 |
| Greatsword strictly dominates Longsword | Longsword dmg 15→20 | DPS → 40, now distinct |

### P1 — High
| Issue | Fix | Effect |
|-------|-----|--------|
| Spear DPS 20, too low | dmg 12→18, arc 30°→45° | DPS → 30, better usability |
| Fists risk/reward broken | dmg 5→7 | DPS → 70, highest melee reward |

### P2 — Medium
| Issue | Fix | Effect |
|-------|-----|--------|
| Shotgun DPS 117 (3-pellet) | dmg 35→30 | DPS → 100, still top burst |
| Wave 5=6 identical, Wave 8<7 | W6 melee+1, W8 melee+1/ranged+1 | Smooth curve |

## Final Weapon DPS Ladder

| Type | Weapon | DPS | Range | Identity |
|------|--------|-----|-------|----------|
| Melee | Fists | 70 | 48px | Max risk, max reward |
| Melee | Dual Daggers | 53 | 64px | Fast strikes |
| Melee | Greatsword | 50 | 80px/120° | Wide AOE clear |
| Melee | Longsword | 40 | 70px/90° | Balanced all-rounder |
| Melee | Spear | 30 | 100px/45° | Safe poking |
| Melee | Warhammer | 29 | 65px | KB 2.5x control |
| Ranged | Shotgun | 100* | 350px | Close-range burst (*3 pellets) |
| Ranged | Pistol | 50 | 400px | Reliable standard |
| Ranged | Crossbow | 50 | 400px | Pierce 3 |
| Ranged | SMG | 50 | 250px | 25-mag rapid fire |
| Ranged | Rifle | 42 | 600px | No-scatter sniper |
| Ranged | Grenade | 32 | 180px | AoE 80px |

## Wave Progression

| Wave | Enemies | Total HP | New Enemy | Upgrade |
|------|---------|----------|-----------|---------|
| 1 | 3 | 90 | — | — |
| 2 | 5 | 140 | Ranged | Yes |
| 3 | 7 | 220 | Charger | — |
| 4 | 8 | 240 | Exploder | Yes |
| 5 | 10 | 290 | — | — |
| 6 | 11 | 320 | — | Yes |
| 7 | 11 | 420 | Tank | — |
| 8 | 15 | 450 | — | Yes |
| 9 | 13 | 470 | — | — |
| 10 | 16 | 470 | — | Yes |
| 11+ | ∞ | +melee2/+ranged1/loop | — | (11-1)%2==0 |

## Remaining Concerns
- No playtest data to validate feel — all analysis is spreadsheet-level
- Upgrade stacking (atk speed ×5 + dmg ×5 = 4x DPS) may trivialize late waves if player high-rolls
- 60fps with 30+ enemies needs in-game testing
