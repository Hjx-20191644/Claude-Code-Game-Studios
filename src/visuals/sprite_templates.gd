extends RefCounted

## Pixel art shape templates. No class_name — use preload to access.

const PA = preload("res://src/visuals/pixel_art.gd")

const O = PA.OUTLINE
const S = PA.SHADOW
const M = PA.MIDTONE
const H = PA.HIGHLIGHT
const B = PA.BASE
const T = PA.TRANSPARENT

const FLESH = PA.MATERIAL_FLESH
const METAL = PA.MATERIAL_METAL
const CLOTH = PA.MATERIAL_CLOTH
const ENERGY = PA.MATERIAL_ENERGY


# ═══════════════════════════════════════════════════════════════════════
# PLAYER SPRITES
# ═══════════════════════════════════════════════════════════════════════

static func player_sprite(img: Image, mat: Dictionary = FLESH) -> void:
	# Brotato-style potato body — 48x48 canvas, round with facial features
	# Body core — wider belly, rounded
	PA.fill_rect(img, 6, 14, 36, 24, mat.MIDTONE)
	PA.fill_rect(img, 10, 10, 28, 8, mat.MIDTONE)
	PA.fill_rect(img, 10, 34, 28, 8, mat.MIDTONE)
	PA.fill_rect(img, 14, 8, 20, 4, mat.MIDTONE)
	PA.fill_rect(img, 14, 38, 20, 4, mat.MIDTONE)
	# Side shadow for roundness
	PA.fill_rect(img, 6, 16, 4, 18, mat.MID_SHADOW)
	PA.fill_rect(img, 38, 16, 4, 18, mat.MID_SHADOW)
	# Bottom shadow
	PA.fill_rect(img, 10, 40, 28, 2, mat.SHADOW)
	# Outline body
	PA.draw_h_line(img, 10, 7, 28, mat.OUTLINE)
	PA.draw_h_line(img, 14, 5, 20, mat.OUTLINE)
	PA.draw_h_line(img, 8, 9, 4, mat.OUTLINE); PA.draw_h_line(img, 36, 9, 4, mat.OUTLINE)
	PA.draw_v_line(img, 6, 10, 30, mat.OUTLINE); PA.draw_v_line(img, 40, 10, 30, mat.OUTLINE)
	PA.draw_h_line(img, 8, 39, 4, mat.OUTLINE); PA.draw_h_line(img, 36, 39, 4, mat.OUTLINE)
	PA.draw_h_line(img, 10, 41, 28, mat.OUTLINE)
	# Forehead highlight
	PA.fill_rect(img, 16, 10, 16, 4, mat.MID_HIGHLIGHT)
	PA.fill_rect(img, 18, 8, 12, 2, mat.HIGHLIGHT)
	# Eyes — white sclera + dark pupil + bright glint
	PA.fill_rect(img, 18, 20, 4, 3, mat.BASE)
	PA.fill_rect(img, 26, 20, 4, 3, mat.BASE)
	PA.draw_pixel(img, 19, 21, mat.OUTLINE); PA.draw_pixel(img, 20, 21, mat.OUTLINE)
	PA.draw_pixel(img, 27, 21, mat.OUTLINE); PA.draw_pixel(img, 28, 21, mat.OUTLINE)
	PA.draw_pixel(img, 18, 20, mat.BRIGHT); PA.draw_pixel(img, 26, 20, mat.BRIGHT)
	# Eyebrow ridges
	PA.draw_h_line(img, 17, 19, 6, mat.SHADOW); PA.draw_h_line(img, 25, 19, 6, mat.SHADOW)
	# Mouth — curved smile
	PA.draw_pixel(img, 20, 30, mat.OUTLINE); PA.draw_pixel(img, 22, 32, mat.OUTLINE)
	PA.draw_pixel(img, 24, 32, mat.OUTLINE); PA.draw_pixel(img, 26, 30, mat.OUTLINE)
	PA.draw_pixel(img, 21, 31, mat.MIDTONE); PA.draw_pixel(img, 25, 31, mat.MIDTONE)
	# Collar detail
	PA.draw_h_line(img, 14, 27, 20, mat.MID_SHADOW)
	PA.draw_pixel(img, 13, 28, mat.SHADOW); PA.draw_pixel(img, 34, 28, mat.SHADOW)
	# Belt line
	PA.draw_h_line(img, 14, 37, 20, mat.MID_SHADOW)
	PA.draw_pixel(img, 24, 37, mat.HIGHLIGHT)
	# Navel dot
	PA.draw_pixel(img, 24, 33, mat.MID_HIGHLIGHT)


static func player_sprite_idle_breath_in(img: Image, mat: Dictionary = FLESH) -> void:
	player_sprite(img, mat)
	# Expand chest — extra highlight on sides
	PA.fill_rect(img, 15, 25, 3, 4, mat.MID_HIGHLIGHT)
	PA.fill_rect(img, 30, 25, 3, 4, mat.MID_HIGHLIGHT)
	# Raise shoulders slightly
	PA.draw_pixel(img, 8, 13, mat.MIDTONE); PA.draw_pixel(img, 38, 13, mat.MIDTONE)


static func player_sprite_idle_breath_out(img: Image, mat: Dictionary = FLESH) -> void:
	player_sprite(img, mat)
	# Compress chest — shadow on sides
	PA.fill_rect(img, 14, 26, 3, 3, mat.MID_SHADOW)
	PA.fill_rect(img, 31, 26, 3, 3, mat.MID_SHADOW)
	# Lower shoulders
	PA.fill_rect(img, 7, 17, 3, 2, mat.SHADOW)
	PA.fill_rect(img, 38, 17, 3, 2, mat.SHADOW)


static func arm_stick_sprite(img: Image, mat: Dictionary = FLESH) -> void:
	# 4x16 arm with shoulder bulb + upper/lower segments + hand
	# Shoulder bulb
	PA.fill_rect(img, 0, 0, 4, 3, mat.MIDTONE)
	PA.draw_pixel(img, 1, 0, mat.HIGHLIGHT)
	PA.draw_pixel(img, 0, 1, mat.OUTLINE); PA.draw_pixel(img, 3, 1, mat.OUTLINE)
	# Upper arm
	PA.fill_rect(img, 1, 3, 2, 5, mat.MIDTONE)
	PA.draw_v_line(img, 1, 3, 5, mat.HIGHLIGHT)
	PA.draw_v_line(img, 2, 3, 5, mat.MID_SHADOW)
	# Elbow
	PA.draw_h_line(img, 1, 8, 2, mat.OUTLINE)
	# Lower arm
	PA.fill_rect(img, 1, 9, 2, 4, mat.MIDTONE)
	PA.draw_v_line(img, 1, 9, 4, mat.HIGHLIGHT)
	PA.draw_v_line(img, 2, 9, 4, mat.MID_SHADOW)
	# Hand
	PA.fill_rect(img, 0, 13, 4, 3, mat.MIDTONE)
	PA.draw_pixel(img, 1, 14, mat.HIGHLIGHT)
	PA.draw_h_line(img, 0, 13, 4, mat.OUTLINE)
	PA.draw_h_line(img, 0, 15, 4, mat.OUTLINE)
	PA.draw_v_line(img, 0, 13, 3, mat.OUTLINE)
	PA.draw_v_line(img, 3, 13, 3, mat.OUTLINE)


static func leg_stick_sprite(img: Image, mat: Dictionary = FLESH) -> void:
	# 4x16 leg with thigh/shin segments + boot foot
	# Thigh
	PA.fill_rect(img, 0, 0, 3, 7, mat.MIDTONE)
	PA.draw_v_line(img, 1, 0, 7, mat.MID_HIGHLIGHT)
	PA.draw_v_line(img, 0, 0, 7, mat.OUTLINE); PA.draw_v_line(img, 2, 0, 7, mat.OUTLINE)
	PA.draw_h_line(img, 0, 7, 3, mat.OUTLINE)  # knee
	# Shin
	PA.fill_rect(img, 1, 8, 2, 5, mat.MIDTONE)
	PA.draw_v_line(img, 1, 8, 5, mat.HIGHLIGHT)
	PA.draw_v_line(img, 0, 8, 5, mat.OUTLINE); PA.draw_v_line(img, 2, 8, 5, mat.OUTLINE)
	# Boot foot
	PA.fill_rect(img, 0, 13, 4, 3, mat.MID_SHADOW)
	PA.draw_pixel(img, 1, 14, mat.HIGHLIGHT)
	PA.draw_h_line(img, 0, 13, 4, mat.OUTLINE)
	PA.draw_h_line(img, 0, 15, 4, mat.OUTLINE)
	PA.draw_v_line(img, 0, 13, 3, mat.OUTLINE)
	PA.draw_v_line(img, 3, 13, 3, mat.OUTLINE)


# ═══════════════════════════════════════════════════════════════════════
# WEAPON SPRITES
# ═══════════════════════════════════════════════════════════════════════

static func sword_sprite(img: Image, mat: Dictionary = METAL) -> void:
	# 16x32 blade with fuller, crossguard, wrapped grip, pommel
	# Blade — tapering from guard to tip
	PA.fill_rect(img, 6, 0, 4, 2, mat.HIGHLIGHT)     # tip
	PA.fill_rect(img, 5, 2, 6, 18, mat.MIDTONE)       # blade body
	PA.fill_rect(img, 7, 2, 2, 18, mat.HIGHLIGHT)     # center fuller
	PA.fill_rect(img, 5, 2, 2, 18, mat.MID_SHADOW)    # left bevel
	PA.fill_rect(img, 9, 2, 2, 18, mat.MID_SHADOW)    # right bevel
	# Blade outline
	PA.draw_v_line(img, 5, 0, 20, mat.OUTLINE)
	PA.draw_v_line(img, 10, 0, 20, mat.OUTLINE)
	PA.draw_h_line(img, 6, 0, 4, mat.OUTLINE)
	PA.draw_h_line(img, 5, 2, 6, mat.OUTLINE)
	# Tip sharpening
	PA.draw_h_line(img, 6, 1, 4, mat.BRIGHT)
	# Crossguard
	PA.fill_rect(img, 2, 20, 12, 3, mat.MID_SHADOW)
	PA.draw_h_line(img, 2, 20, 12, mat.OUTLINE)
	PA.draw_h_line(img, 2, 22, 12, mat.OUTLINE)
	PA.draw_v_line(img, 2, 20, 3, mat.OUTLINE); PA.draw_v_line(img, 13, 20, 3, mat.OUTLINE)
	PA.fill_rect(img, 4, 20, 8, 1, mat.HIGHLIGHT)    # guard top edge
	# Grip — wrapped texture
	PA.fill_rect(img, 5, 23, 6, 7, mat.MIDTONE)
	PA.draw_v_line(img, 5, 23, 7, mat.OUTLINE); PA.draw_v_line(img, 10, 23, 7, mat.OUTLINE)
	PA.draw_h_line(img, 5, 25, 6, mat.MID_SHADOW)     # wrap lines
	PA.draw_h_line(img, 5, 27, 6, mat.MID_SHADOW)
	# Pommel
	PA.fill_rect(img, 4, 30, 8, 2, mat.MIDTONE)
	PA.draw_h_line(img, 4, 30, 8, mat.OUTLINE)
	PA.draw_h_line(img, 4, 31, 8, mat.OUTLINE)
	PA.draw_v_line(img, 4, 30, 2, mat.OUTLINE); PA.draw_v_line(img, 11, 30, 2, mat.OUTLINE)
	PA.draw_pixel(img, 8, 30, mat.BRIGHT)


static func gun_sprite(img: Image, mat: Dictionary = METAL) -> void:
	# 24x16 pistol with textured grip, slide detail, barrel, sight
	# Slide / receiver body
	PA.fill_rect(img, 2, 2, 18, 5, mat.MIDTONE)
	PA.fill_rect(img, 4, 1, 14, 2, mat.MID_HIGHLIGHT)
	PA.fill_rect(img, 2, 6, 18, 2, mat.MID_SHADOW)
	# Slide outline
	PA.draw_h_line(img, 4, 0, 14, mat.OUTLINE)
	PA.draw_v_line(img, 2, 1, 7, mat.OUTLINE); PA.draw_v_line(img, 19, 1, 7, mat.OUTLINE)
	PA.draw_h_line(img, 2, 8, 18, mat.OUTLINE)
	# Ejection port
	PA.fill_rect(img, 8, 4, 5, 2, PA.DEEP_SHADOW)
	PA.draw_pixel(img, 9, 5, mat.HIGHLIGHT)
	# Barrel
	PA.fill_rect(img, 18, 3, 6, 3, mat.MIDTONE)
	PA.draw_h_line(img, 18, 3, 6, mat.OUTLINE)
	PA.draw_h_line(img, 18, 5, 6, mat.OUTLINE)
	PA.draw_v_line(img, 23, 3, 3, mat.OUTLINE)
	PA.fill_rect(img, 20, 3, 3, 1, mat.HIGHLIGHT)   # barrel top highlight
	# Muzzle tip
	PA.draw_v_line(img, 23, 3, 3, mat.BRIGHT)
	# Trigger guard
	PA.draw_v_line(img, 4, 8, 3, mat.OUTLINE)
	PA.draw_h_line(img, 4, 10, 4, mat.OUTLINE)
	# Trigger
	PA.draw_pixel(img, 6, 8, mat.OUTLINE)
	PA.draw_pixel(img, 6, 9, mat.MIDTONE)
	# Grip
	PA.fill_rect(img, 2, 8, 6, 8, mat.MID_SHADOW)
	PA.fill_rect(img, 3, 9, 4, 6, mat.MIDTONE)
	PA.draw_v_line(img, 2, 8, 8, mat.OUTLINE); PA.draw_v_line(img, 7, 8, 8, mat.OUTLINE)
	PA.draw_h_line(img, 2, 15, 6, mat.OUTLINE)
	# Grip texturing
	PA.draw_h_line(img, 3, 10, 4, mat.MID_SHADOW)
	PA.draw_h_line(img, 3, 12, 4, mat.MID_SHADOW)
	PA.draw_h_line(img, 3, 14, 4, mat.MID_SHADOW)
	# Rear sight
	PA.draw_pixel(img, 14, 0, mat.OUTLINE)
	PA.draw_pixel(img, 15, 0, mat.OUTLINE)


# ═══════════════════════════════════════════════════════════════════════
# ENEMY SPRITES
# ═══════════════════════════════════════════════════════════════════════

static func enemy_melee_sprite(img: Image, mat: Dictionary = FLESH) -> void:
	# Cthulhu-style alien — 48x48, tentacled face, 3 eyes, claw arms
	# Body — asymmetric lump
	PA.fill_rect(img, 10, 8, 28, 20, mat.MIDTONE)
	PA.fill_rect(img, 8, 12, 4, 12, mat.MIDTONE); PA.fill_rect(img, 36, 10, 4, 14, mat.MIDTONE)
	PA.fill_rect(img, 14, 6, 20, 6, mat.MIDTONE)
	PA.fill_rect(img, 16, 28, 16, 8, mat.MID_SHADOW)
	# Shadow underbelly
	PA.fill_rect(img, 12, 24, 24, 4, mat.SHADOW)
	# Outline body
	PA.draw_h_line(img, 16, 4, 16, mat.OUTLINE)
	PA.draw_h_line(img, 10, 5, 4, mat.OUTLINE); PA.draw_h_line(img, 30, 4, 4, mat.OUTLINE)
	PA.draw_v_line(img, 6, 6, 16, mat.OUTLINE); PA.draw_v_line(img, 40, 6, 16, mat.OUTLINE)
	PA.draw_h_line(img, 8, 26, 32, mat.OUTLINE)
	PA.draw_h_line(img, 10, 28, 28, mat.OUTLINE)
	PA.draw_v_line(img, 10, 28, 8, mat.OUTLINE); PA.draw_v_line(img, 36, 28, 8, mat.OUTLINE)
	PA.draw_h_line(img, 12, 36, 24, mat.OUTLINE)
	# Tentacles around mouth
	PA.draw_v_line(img, 18, 26, 6, mat.OUTLINE); PA.draw_v_line(img, 28, 26, 6, mat.OUTLINE)
	PA.draw_pixel(img, 16, 28, mat.OUTLINE); PA.draw_pixel(img, 30, 28, mat.OUTLINE)
	PA.draw_v_line(img, 16, 29, 3, mat.OUTLINE); PA.draw_v_line(img, 30, 29, 3, mat.OUTLINE)
	PA.draw_pixel(img, 20, 26, mat.OUTLINE); PA.draw_pixel(img, 26, 26, mat.OUTLINE)
	PA.draw_pixel(img, 22, 27, mat.MIDTONE)   # tentacle highlight
	PA.draw_pixel(img, 24, 27, mat.MIDTONE)
	# Eyes — 3 small glowing eyes with white+dark+glint
	PA.fill_rect(img, 16, 12, 4, 4, mat.BASE)
	PA.fill_rect(img, 22, 10, 4, 4, mat.BASE)
	PA.fill_rect(img, 28, 12, 4, 4, mat.BASE)
	PA.draw_pixel(img, 17, 13, mat.OUTLINE); PA.draw_pixel(img, 23, 11, mat.OUTLINE)
	PA.draw_pixel(img, 29, 13, mat.OUTLINE)
	PA.draw_pixel(img, 16, 12, mat.BRIGHT); PA.draw_pixel(img, 22, 10, mat.BRIGHT)
	PA.draw_pixel(img, 28, 12, mat.BRIGHT)   # glints
	# Eye outline sockets
	PA.draw_h_line(img, 16, 16, 4, mat.OUTLINE); PA.draw_h_line(img, 22, 14, 4, mat.OUTLINE)
	PA.draw_h_line(img, 28, 16, 4, mat.OUTLINE)
	# Claw arms
	PA.draw_v_line(img, 4, 14, 12, mat.OUTLINE); PA.draw_v_line(img, 42, 12, 14, mat.OUTLINE)
	PA.draw_pixel(img, 2, 14, mat.OUTLINE); PA.draw_pixel(img, 44, 12, mat.OUTLINE)
	PA.draw_h_line(img, 0, 18, 6, mat.OUTLINE); PA.draw_h_line(img, 42, 16, 6, mat.OUTLINE)
	PA.draw_pixel(img, 1, 19, mat.HIGHLIGHT); PA.draw_pixel(img, 43, 17, mat.HIGHLIGHT)
	# Legs
	PA.draw_v_line(img, 18, 36, 10, mat.OUTLINE); PA.draw_v_line(img, 30, 36, 10, mat.OUTLINE)
	PA.draw_pixel(img, 16, 44, mat.OUTLINE); PA.draw_pixel(img, 32, 44, mat.OUTLINE)


static func enemy_melee_sprite_blink(img: Image, mat: Dictionary = FLESH) -> void:
	enemy_melee_sprite(img, mat)
	# Close all 3 eyes — overwrite white with MIDTONE
	PA.fill_rect(img, 16, 12, 4, 4, mat.MIDTONE)
	PA.fill_rect(img, 22, 10, 4, 4, mat.MIDTONE)
	PA.fill_rect(img, 28, 12, 4, 4, mat.MIDTONE)
	PA.fill_rect(img, 17, 13, 2, 1, mat.OUTLINE)  # closed slit line
	PA.fill_rect(img, 23, 11, 2, 1, mat.OUTLINE)
	PA.fill_rect(img, 29, 13, 2, 1, mat.OUTLINE)


static func enemy_ranged_sprite(img: Image, mat: Dictionary = FLESH) -> void:
	# Alien spitter — 48x48, elongated head, projectile gland, thin body
	# Head (elongated back)
	PA.fill_rect(img, 6, 4, 36, 16, mat.MIDTONE)
	PA.fill_rect(img, 2, 8, 8, 8, mat.MIDTONE)
	PA.fill_rect(img, 10, 2, 28, 6, mat.MIDTONE)
	# Head shading — brighter top
	PA.fill_rect(img, 12, 4, 24, 4, mat.MID_HIGHLIGHT)
	PA.fill_rect(img, 6, 14, 32, 4, mat.MID_SHADOW)
	# Outline head
	PA.draw_h_line(img, 12, 0, 24, mat.OUTLINE)
	PA.draw_h_line(img, 6, 1, 8, mat.OUTLINE); PA.draw_h_line(img, 30, 1, 8, mat.OUTLINE)
	PA.draw_v_line(img, 4, 2, 12, mat.OUTLINE)
	PA.draw_h_line(img, 2, 16, 40, mat.OUTLINE)
	PA.draw_v_line(img, 2, 8, 8, mat.OUTLINE)
	# Eye — single large eye with glow
	PA.fill_rect(img, 16, 8, 8, 6, mat.BASE)
	PA.draw_pixel(img, 18, 10, mat.OUTLINE); PA.draw_pixel(img, 22, 10, mat.OUTLINE)
	PA.draw_pixel(img, 17, 9, mat.BRIGHT); PA.draw_pixel(img, 21, 9, mat.BRIGHT)
	PA.draw_h_line(img, 16, 14, 8, mat.OUTLINE)
	# Spitting tube
	PA.draw_v_line(img, 38, 6, 10, mat.OUTLINE)
	PA.draw_h_line(img, 40, 8, 6, mat.OUTLINE)
	PA.draw_pixel(img, 44, 10, mat.BRIGHT)
	PA.draw_pixel(img, 42, 9, mat.HIGHLIGHT)
	# Projectile gland
	PA.fill_rect(img, 30, 4, 6, 4, mat.MID_SHADOW)
	PA.draw_pixel(img, 32, 5, mat.BRIGHT)
	# Body
	PA.fill_rect(img, 12, 18, 20, 16, mat.MID_SHADOW)
	PA.fill_rect(img, 16, 20, 12, 12, mat.MIDTONE)
	# Ribbed segments
	PA.draw_h_line(img, 14, 22, 16, mat.MID_SHADOW)
	PA.draw_h_line(img, 14, 26, 16, mat.MID_SHADOW)
	PA.draw_h_line(img, 14, 30, 16, mat.MID_SHADOW)
	# Body outline
	PA.draw_h_line(img, 14, 17, 18, mat.OUTLINE)
	PA.draw_v_line(img, 10, 18, 16, mat.OUTLINE); PA.draw_v_line(img, 34, 18, 16, mat.OUTLINE)
	PA.draw_h_line(img, 12, 34, 22, mat.OUTLINE)
	# Arms
	PA.draw_v_line(img, 10, 20, 10, mat.OUTLINE); PA.draw_v_line(img, 34, 20, 10, mat.OUTLINE)
	PA.draw_pixel(img, 11, 29, mat.HIGHLIGHT); PA.draw_pixel(img, 33, 29, mat.HIGHLIGHT)
	# Thin legs
	PA.draw_v_line(img, 16, 34, 12, mat.OUTLINE); PA.draw_v_line(img, 28, 34, 12, mat.OUTLINE)
	PA.draw_pixel(img, 14, 44, mat.OUTLINE); PA.draw_pixel(img, 30, 44, mat.OUTLINE)


static func enemy_ranged_sprite_blink(img: Image, mat: Dictionary = FLESH) -> void:
	enemy_ranged_sprite(img, mat)
	PA.fill_rect(img, 16, 8, 8, 6, mat.MIDTONE)
	PA.draw_h_line(img, 16, 10, 8, mat.OUTLINE)  # closed slit


static func enemy_charger_sprite(img: Image, mat: Dictionary = FLESH) -> void:
	# Streamlined predator — 48x48, pointed snout, dorsal fins, running pose
	# Pointed snout
	PA.fill_rect(img, 0, 16, 8, 8, mat.OUTLINE)
	PA.draw_h_line(img, 6, 14, 6, mat.OUTLINE); PA.draw_h_line(img, 6, 24, 6, mat.OUTLINE)
	PA.draw_pixel(img, 0, 18, mat.MIDTONE); PA.draw_pixel(img, 0, 20, mat.MID_HIGHLIGHT)
	# Teeth on snout
	PA.draw_pixel(img, 3, 16, mat.HIGHLIGHT); PA.draw_pixel(img, 5, 16, mat.HIGHLIGHT)
	# Head
	PA.fill_rect(img, 6, 8, 20, 20, mat.MIDTONE)
	PA.fill_rect(img, 8, 6, 16, 4, mat.MID_HIGHLIGHT)
	PA.fill_rect(img, 6, 20, 20, 6, mat.MID_SHADOW)
	# Head outline
	PA.draw_h_line(img, 8, 4, 16, mat.OUTLINE)
	PA.draw_v_line(img, 6, 5, 20, mat.OUTLINE); PA.draw_v_line(img, 26, 5, 20, mat.OUTLINE)
	PA.draw_h_line(img, 6, 28, 20, mat.OUTLINE)
	# Eyes — slitted, aggressive
	PA.fill_rect(img, 12, 12, 4, 4, mat.BASE); PA.fill_rect(img, 20, 12, 4, 4, mat.BASE)
	PA.draw_pixel(img, 10, 12, mat.OUTLINE); PA.draw_pixel(img, 14, 14, mat.OUTLINE)
	PA.draw_pixel(img, 22, 12, mat.OUTLINE); PA.draw_pixel(img, 26, 14, mat.OUTLINE)
	PA.draw_pixel(img, 12, 13, mat.BRIGHT); PA.draw_pixel(img, 20, 13, mat.BRIGHT)
	# Angry brow ridges
	PA.draw_h_line(img, 10, 11, 4, mat.SHADOW); PA.draw_h_line(img, 22, 11, 4, mat.SHADOW)
	# Body
	PA.fill_rect(img, 12, 28, 12, 12, mat.MID_SHADOW)
	PA.fill_rect(img, 14, 26, 8, 4, mat.MIDTONE)
	PA.draw_h_line(img, 10, 40, 20, mat.OUTLINE)
	PA.draw_v_line(img, 10, 28, 12, mat.OUTLINE); PA.draw_v_line(img, 30, 28, 12, mat.OUTLINE)
	# Spine highlight
	PA.draw_v_line(img, 22, 28, 10, mat.MID_HIGHLIGHT)
	# Dorsal fins
	PA.draw_v_line(img, 22, 6, 6, mat.OUTLINE); PA.draw_pixel(img, 20, 8, mat.OUTLINE)
	PA.draw_v_line(img, 26, 4, 5, mat.OUTLINE); PA.draw_pixel(img, 24, 5, mat.OUTLINE)
	PA.draw_pixel(img, 24, 6, mat.HIGHLIGHT); PA.draw_pixel(img, 27, 4, mat.HIGHLIGHT)
	# Legs — running pose
	PA.draw_v_line(img, 16, 40, 6, mat.OUTLINE); PA.draw_h_line(img, 14, 44, 6, mat.OUTLINE)
	PA.draw_v_line(img, 28, 40, 6, mat.OUTLINE); PA.draw_h_line(img, 26, 44, 6, mat.OUTLINE)
	PA.draw_pixel(img, 17, 43, mat.HIGHLIGHT); PA.draw_pixel(img, 29, 43, mat.HIGHLIGHT)


static func enemy_charger_sprite_blink(img: Image, mat: Dictionary = FLESH) -> void:
	enemy_charger_sprite(img, mat)
	PA.fill_rect(img, 12, 12, 4, 4, mat.MIDTONE)
	PA.fill_rect(img, 20, 12, 4, 4, mat.MIDTONE)
	PA.draw_h_line(img, 12, 13, 4, mat.OUTLINE)
	PA.draw_h_line(img, 20, 13, 4, mat.OUTLINE)


static func enemy_exploder_sprite(img: Image, mat: Dictionary = FLESH) -> void:
	# Bloated pustule alien — 48x48, round, veiny, about to burst
	# Main body — very round
	PA.fill_rect(img, 8, 8, 32, 28, mat.MIDTONE)
	PA.fill_rect(img, 14, 4, 20, 8, mat.MIDTONE)
	PA.fill_rect(img, 12, 36, 24, 6, mat.MIDTONE)
	PA.fill_rect(img, 18, 2, 12, 4, mat.MIDTONE)
	PA.fill_rect(img, 20, 40, 8, 4, mat.MID_SHADOW)
	# Highlight — taut skin
	PA.fill_rect(img, 18, 6, 12, 2, mat.MID_HIGHLIGHT)
	PA.fill_rect(img, 10, 18, 28, 4, mat.MID_HIGHLIGHT)
	PA.fill_rect(img, 14, 12, 4, 8, mat.HIGHLIGHT)
	# Outline
	PA.draw_h_line(img, 20, 0, 8, mat.OUTLINE)
	PA.draw_h_line(img, 10, 1, 12, mat.OUTLINE); PA.draw_h_line(img, 30, 1, 4, mat.OUTLINE)
	PA.draw_h_line(img, 6, 2, 8, mat.OUTLINE); PA.draw_h_line(img, 34, 2, 8, mat.OUTLINE)
	PA.draw_v_line(img, 4, 3, 28, mat.OUTLINE); PA.draw_v_line(img, 42, 3, 28, mat.OUTLINE)
	PA.draw_h_line(img, 8, 34, 8, mat.OUTLINE); PA.draw_h_line(img, 32, 34, 8, mat.OUTLINE)
	PA.draw_h_line(img, 12, 36, 24, mat.OUTLINE)
	PA.draw_h_line(img, 16, 38, 16, mat.OUTLINE)
	PA.draw_h_line(img, 20, 40, 8, mat.OUTLINE)
	# Fuse
	PA.draw_v_line(img, 24, 0, 6, mat.OUTLINE)
	PA.draw_pixel(img, 22, 0, mat.BRIGHT)  # spark
	PA.draw_pixel(img, 24, 1, mat.HIGHLIGHT)
	# Eyes — crazed, different sizes
	PA.fill_rect(img, 16, 14, 6, 6, mat.BASE)
	PA.fill_rect(img, 26, 12, 4, 5, mat.BASE)
	PA.draw_pixel(img, 18, 16, mat.OUTLINE); PA.draw_pixel(img, 28, 14, mat.OUTLINE)
	PA.draw_pixel(img, 17, 15, mat.BRIGHT); PA.draw_pixel(img, 27, 13, mat.BRIGHT)
	PA.draw_h_line(img, 16, 20, 6, mat.OUTLINE); PA.draw_h_line(img, 26, 17, 4, mat.OUTLINE)
	# Mouth — gasping maw
	PA.fill_rect(img, 18, 26, 10, 6, mat.OUTLINE)
	PA.fill_rect(img, 20, 26, 6, 2, mat.HIGHLIGHT)
	PA.draw_pixel(img, 22, 28, mat.BASE); PA.draw_pixel(img, 24, 28, mat.BASE)
	# Veins
	PA.draw_v_line(img, 8, 16, 6, mat.OUTLINE); PA.draw_v_line(img, 38, 18, 6, mat.OUTLINE)
	PA.draw_pixel(img, 10, 20, mat.OUTLINE); PA.draw_pixel(img, 36, 22, mat.OUTLINE)
	PA.draw_pixel(img, 6, 23, mat.MID_SHADOW); PA.draw_pixel(img, 40, 24, mat.MID_SHADOW)
	# Tiny legs
	PA.draw_v_line(img, 16, 40, 6, mat.OUTLINE); PA.draw_v_line(img, 30, 40, 6, mat.OUTLINE)
	PA.draw_pixel(img, 14, 44, mat.OUTLINE); PA.draw_pixel(img, 32, 44, mat.OUTLINE)


static func enemy_exploder_sprite_blink(img: Image, mat: Dictionary = FLESH) -> void:
	enemy_exploder_sprite(img, mat)
	PA.fill_rect(img, 16, 14, 6, 6, mat.MIDTONE)
	PA.fill_rect(img, 26, 12, 4, 5, mat.MIDTONE)
	PA.draw_h_line(img, 16, 16, 6, mat.OUTLINE)
	PA.draw_h_line(img, 26, 14, 4, mat.OUTLINE)


static func enemy_tank_sprite(img: Image, mat: Dictionary = METAL) -> void:
	# Hulking eldritch brute — 96x96, massive body, carapace plates, heavy arms
	# Body core
	PA.fill_rect(img, 20, 12, 56, 44, mat.MIDTONE)
	PA.fill_rect(img, 28, 8, 40, 8, mat.MIDTONE)
	PA.fill_rect(img, 16, 20, 8, 28, mat.MIDTONE); PA.fill_rect(img, 72, 20, 8, 28, mat.MIDTONE)
	# Shadow underbelly
	PA.fill_rect(img, 24, 44, 48, 8, mat.SHADOW)
	# Outline body
	PA.draw_h_line(img, 30, 6, 36, mat.OUTLINE)
	PA.draw_h_line(img, 22, 7, 8, mat.OUTLINE); PA.draw_h_line(img, 66, 7, 8, mat.OUTLINE)
	PA.draw_h_line(img, 18, 8, 8, mat.OUTLINE); PA.draw_h_line(img, 70, 8, 8, mat.OUTLINE)
	PA.draw_v_line(img, 16, 9, 36, mat.OUTLINE); PA.draw_v_line(img, 80, 9, 36, mat.OUTLINE)
	PA.draw_h_line(img, 18, 48, 6, mat.OUTLINE); PA.draw_h_line(img, 72, 48, 6, mat.OUTLINE)
	PA.draw_h_line(img, 22, 50, 52, mat.OUTLINE)
	# Carapace plates
	PA.draw_h_line(img, 24, 16, 48, mat.MID_SHADOW)
	PA.draw_h_line(img, 26, 22, 44, mat.MID_SHADOW)
	PA.draw_h_line(img, 24, 32, 48, mat.MID_SHADOW)
	PA.draw_h_line(img, 28, 18, 40, mat.HIGHLIGHT)
	PA.draw_h_line(img, 28, 28, 40, mat.HIGHLIGHT)
	PA.draw_h_line(img, 26, 38, 44, mat.HIGHLIGHT)
	# Eyes — tiny, recessed with glow
	PA.fill_rect(img, 32, 18, 8, 6, mat.BASE)
	PA.fill_rect(img, 56, 18, 8, 6, mat.BASE)
	PA.draw_pixel(img, 34, 20, mat.OUTLINE); PA.draw_pixel(img, 58, 20, mat.OUTLINE)
	PA.draw_pixel(img, 33, 19, mat.BRIGHT); PA.draw_pixel(img, 57, 19, mat.BRIGHT)
	PA.fill_rect(img, 30, 17, 12, 8, mat.SHADOW)   # eye socket shadow (partial overlay)
	PA.fill_rect(img, 54, 17, 12, 8, mat.SHADOW)
	PA.fill_rect(img, 32, 18, 8, 6, mat.BASE)       # re-draw eyes over shadow
	PA.fill_rect(img, 56, 18, 8, 6, mat.BASE)
	PA.draw_pixel(img, 34, 20, mat.OUTLINE); PA.draw_pixel(img, 58, 20, mat.OUTLINE)
	PA.draw_pixel(img, 33, 19, mat.BRIGHT); PA.draw_pixel(img, 57, 19, mat.BRIGHT)
	# Mouth — mandibles
	PA.draw_v_line(img, 44, 36, 8, mat.OUTLINE); PA.draw_v_line(img, 52, 36, 8, mat.OUTLINE)
	PA.draw_h_line(img, 38, 42, 20, mat.OUTLINE)
	PA.draw_pixel(img, 40, 38, mat.OUTLINE); PA.draw_pixel(img, 56, 38, mat.OUTLINE)
	PA.draw_pixel(img, 46, 40, mat.HIGHLIGHT); PA.draw_pixel(img, 50, 40, mat.HIGHLIGHT)
	# Heavy arms
	PA.fill_rect(img, 4, 24, 12, 16, mat.MID_SHADOW); PA.fill_rect(img, 80, 24, 12, 16, mat.MID_SHADOW)
	PA.draw_v_line(img, 2, 26, 12, mat.OUTLINE); PA.draw_v_line(img, 94, 26, 12, mat.OUTLINE)
	PA.draw_h_line(img, 0, 36, 6, mat.OUTLINE); PA.draw_h_line(img, 90, 36, 6, mat.OUTLINE)
	PA.draw_pixel(img, 2, 38, mat.HIGHLIGHT); PA.draw_pixel(img, 92, 38, mat.HIGHLIGHT)
	PA.draw_v_line(img, 16, 26, 8, mat.OUTLINE); PA.draw_v_line(img, 80, 26, 8, mat.OUTLINE)
	PA.fill_rect(img, 4, 26, 10, 12, mat.MIDTONE)
	PA.fill_rect(img, 82, 26, 10, 12, mat.MIDTONE)
	# Shoulder armor
	PA.fill_rect(img, 2, 20, 16, 6, mat.MID_SHADOW)
	PA.fill_rect(img, 78, 20, 16, 6, mat.MID_SHADOW)
	PA.draw_h_line(img, 2, 22, 16, mat.HIGHLIGHT)
	PA.draw_h_line(img, 78, 22, 16, mat.HIGHLIGHT)
	# Legs — thick pillars
	PA.fill_rect(img, 28, 56, 12, 24, mat.MID_SHADOW); PA.fill_rect(img, 56, 56, 12, 24, mat.MID_SHADOW)
	PA.draw_v_line(img, 26, 58, 20, mat.OUTLINE); PA.draw_v_line(img, 70, 58, 20, mat.OUTLINE)
	PA.draw_v_line(img, 40, 58, 20, mat.OUTLINE); PA.draw_v_line(img, 56, 58, 20, mat.OUTLINE)
	PA.fill_rect(img, 24, 76, 16, 8, mat.OUTLINE); PA.fill_rect(img, 56, 76, 16, 8, mat.OUTLINE)
	PA.draw_h_line(img, 20, 84, 56, mat.OUTLINE)


static func enemy_tank_sprite_blink(img: Image, mat: Dictionary = METAL) -> void:
	enemy_tank_sprite(img, mat)
	# Close eyes — cover glow
	PA.fill_rect(img, 32, 18, 8, 6, mat.MID_SHADOW)
	PA.fill_rect(img, 56, 18, 8, 6, mat.MID_SHADOW)
	PA.draw_h_line(img, 32, 20, 8, mat.OUTLINE)
	PA.draw_h_line(img, 56, 20, 8, mat.OUTLINE)


static func enemy_boss_sprite(img: Image, mat: Dictionary = FLESH) -> void:
	# Eldritch horror — 144x144, massive asymmetrical body, crown of eyes, tentacles
	# Crown/horns
	PA.fill_rect(img, 40, 0, 16, 12, mat.OUTLINE)
	PA.fill_rect(img, 88, 0, 16, 12, mat.OUTLINE)
	PA.fill_rect(img, 64, 0, 16, 8, mat.OUTLINE)
	PA.fill_rect(img, 60, 4, 24, 4, mat.HIGHLIGHT)
	PA.draw_v_line(img, 48, 6, 10, mat.OUTLINE); PA.draw_v_line(img, 96, 6, 10, mat.OUTLINE)
	PA.draw_pixel(img, 46, 14, mat.OUTLINE); PA.draw_pixel(img, 98, 14, mat.OUTLINE)
	# Crown eyes
	PA.fill_rect(img, 52, 2, 6, 5, mat.BASE); PA.fill_rect(img, 86, 2, 6, 5, mat.BASE)
	PA.draw_pixel(img, 54, 4, mat.OUTLINE); PA.draw_pixel(img, 88, 4, mat.OUTLINE)
	PA.draw_pixel(img, 53, 3, mat.BRIGHT); PA.draw_pixel(img, 87, 3, mat.BRIGHT)
	# Head — massive
	PA.fill_rect(img, 36, 12, 72, 32, mat.MIDTONE)
	PA.fill_rect(img, 44, 8, 56, 8, mat.MIDTONE)
	# Head shading
	PA.fill_rect(img, 40, 20, 64, 16, mat.MID_HIGHLIGHT)
	PA.fill_rect(img, 36, 36, 72, 6, mat.SHADOW)
	# Head outline
	PA.draw_h_line(img, 46, 6, 52, mat.OUTLINE)
	PA.draw_v_line(img, 34, 8, 32, mat.OUTLINE); PA.draw_v_line(img, 108, 8, 32, mat.OUTLINE)
	PA.draw_h_line(img, 36, 44, 72, mat.OUTLINE)
	# Main eyes — three large eyes
	PA.fill_rect(img, 44, 18, 10, 8, mat.BASE)
	PA.fill_rect(img, 68, 16, 10, 10, mat.BASE)    # center eye — largest
	PA.fill_rect(img, 92, 18, 10, 8, mat.BASE)
	PA.draw_pixel(img, 48, 22, mat.OUTLINE); PA.draw_pixel(img, 72, 20, mat.OUTLINE)
	PA.draw_pixel(img, 96, 22, mat.OUTLINE)
	PA.draw_pixel(img, 46, 19, mat.BRIGHT); PA.draw_pixel(img, 70, 17, mat.BRIGHT)
	PA.draw_pixel(img, 94, 19, mat.BRIGHT)
	# Eye glow auras
	PA.draw_pixel(img, 43, 18, mat.HIGHLIGHT); PA.draw_pixel(img, 53, 18, mat.HIGHLIGHT)
	PA.draw_pixel(img, 67, 16, mat.HIGHLIGHT); PA.draw_pixel(img, 77, 16, mat.HIGHLIGHT)
	PA.draw_pixel(img, 91, 18, mat.HIGHLIGHT); PA.draw_pixel(img, 101, 18, mat.HIGHLIGHT)
	# Mouth — gaping maw with teeth
	PA.fill_rect(img, 52, 36, 40, 12, mat.OUTLINE)
	PA.fill_rect(img, 56, 36, 32, 3, mat.HIGHLIGHT)     # upper lip highlight
	PA.draw_pixel(img, 60, 40, mat.BASE); PA.draw_pixel(img, 66, 40, mat.BASE)
	PA.draw_pixel(img, 72, 40, mat.BASE); PA.draw_pixel(img, 78, 40, mat.BASE)
	PA.draw_pixel(img, 84, 40, mat.BASE)
	# Teeth
	for i in range(5):
		var tx := 56 + i * 7
		PA.fill_rect(img, tx, 42, 3, 4, mat.BASE)
		PA.draw_pixel(img, tx + 1, 42, mat.HIGHLIGHT)
	# Tongue — forked
	PA.draw_v_line(img, 68, 40, 6, mat.MID_HIGHLIGHT)
	PA.draw_v_line(img, 72, 40, 6, mat.MID_HIGHLIGHT)
	PA.draw_pixel(img, 66, 44, mat.OUTLINE); PA.draw_pixel(img, 74, 44, mat.OUTLINE)
	# Body — massive torso
	PA.fill_rect(img, 24, 48, 96, 48, mat.MID_SHADOW)
	PA.fill_rect(img, 32, 46, 80, 6, mat.MIDTONE)
	PA.draw_h_line(img, 26, 50, 92, mat.OUTLINE)
	PA.draw_v_line(img, 22, 52, 42, mat.OUTLINE); PA.draw_v_line(img, 120, 52, 42, mat.OUTLINE)
	PA.draw_h_line(img, 28, 96, 88, mat.OUTLINE)
	# Body highlights — center glow
	PA.fill_rect(img, 36, 54, 28, 32, mat.MIDTONE)
	PA.fill_rect(img, 80, 54, 28, 32, mat.MIDTONE)
	PA.fill_rect(img, 56, 60, 32, 22, mat.MID_HIGHLIGHT)
	PA.fill_rect(img, 60, 64, 24, 14, mat.HIGHLIGHT)
	# Rib grooves
	PA.draw_h_line(img, 32, 58, 80, mat.MID_SHADOW)
	PA.draw_h_line(img, 32, 70, 80, mat.MID_SHADOW)
	PA.draw_h_line(img, 32, 82, 80, mat.MID_SHADOW)
	# Tentacles — bottom, 6 tentacles
	for i in range(6):
		var bx := 36 + i * 12
		PA.draw_v_line(img, bx, 96, 16, mat.OUTLINE)
		var sgn := 1 if i % 2 == 0 else -1
		PA.draw_pixel(img, bx + sgn, 100, mat.OUTLINE)
		PA.draw_pixel(img, bx + sgn * 2, 104, mat.OUTLINE)
		PA.draw_pixel(img, bx, 106, mat.MID_HIGHLIGHT)   # sucker highlight
		PA.draw_pixel(img, bx + sgn * 2, 110, mat.MIDTONE)
	# Arms — massive claws
	PA.fill_rect(img, 4, 52, 20, 28, mat.MID_SHADOW); PA.fill_rect(img, 120, 52, 20, 28, mat.MID_SHADOW)
	PA.draw_v_line(img, 2, 54, 24, mat.OUTLINE); PA.draw_v_line(img, 142, 54, 24, mat.OUTLINE)
	PA.draw_h_line(img, 0, 66, 8, mat.OUTLINE); PA.draw_h_line(img, 136, 66, 8, mat.OUTLINE)
	PA.draw_pixel(img, 0, 76, mat.OUTLINE); PA.draw_pixel(img, 144, 76, mat.OUTLINE)
	PA.draw_v_line(img, 24, 56, 8, mat.OUTLINE); PA.draw_v_line(img, 120, 56, 8, mat.OUTLINE)
	# Claw fingers
	for finger in range(3):
		PA.draw_pixel(img, 4 + finger * 2, 68, mat.HIGHLIGHT)
		PA.draw_pixel(img, 136 + finger * 2, 68, mat.HIGHLIGHT)
	# Legs — thick
	PA.fill_rect(img, 44, 112, 20, 24, mat.MID_SHADOW); PA.fill_rect(img, 80, 112, 20, 24, mat.MID_SHADOW)
	PA.draw_v_line(img, 42, 114, 20, mat.OUTLINE); PA.draw_v_line(img, 100, 114, 20, mat.OUTLINE)
	PA.draw_v_line(img, 64, 114, 20, mat.OUTLINE); PA.draw_v_line(img, 80, 114, 20, mat.OUTLINE)
	PA.fill_rect(img, 40, 134, 28, 8, mat.OUTLINE); PA.fill_rect(img, 76, 134, 28, 8, mat.OUTLINE)


static func enemy_boss_sprite_idle_1(img: Image, mat: Dictionary = FLESH) -> void:
	enemy_boss_sprite(img, mat)
	# Tentacles wave left — shift bottom pixels
	PA.draw_pixel(img, 34, 98, mat.OUTLINE); PA.draw_pixel(img, 46, 98, mat.OUTLINE)
	PA.draw_pixel(img, 58, 98, mat.MID_SHADOW)
	PA.draw_pixel(img, 70, 102, mat.OUTLINE)
	# Crown eyes flicker — alternate eyes glow
	PA.draw_pixel(img, 53, 3, mat.BRIGHT); PA.draw_pixel(img, 89, 3, mat.MIDTONE)


static func enemy_boss_sprite_idle_2(img: Image, mat: Dictionary = FLESH) -> void:
	enemy_boss_sprite(img, mat)
	# Tentacles wave right
	PA.draw_pixel(img, 38, 98, mat.MID_SHADOW)
	PA.draw_pixel(img, 50, 102, mat.OUTLINE); PA.draw_pixel(img, 62, 102, mat.OUTLINE)
	PA.draw_pixel(img, 74, 98, mat.OUTLINE)
	# Crown eyes flicker — different eyes
	PA.draw_pixel(img, 53, 3, mat.MIDTONE); PA.draw_pixel(img, 89, 3, mat.BRIGHT)


# ═══════════════════════════════════════════════════════════════════════
# PROJECTILE & EFFECT SPRITES
# ═══════════════════════════════════════════════════════════════════════

static func bullet_sprite(img: Image, mat: Dictionary = ENERGY) -> void:
	# 16x16 radial gradient bullet — bright core, soft glow, sharp edge
	var w := img.get_width()
	var h := img.get_height()
	var cx := w / 2
	var cy := h / 2
	for y in h:
		for x in w:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(float(dx * dx + dy * dy))
			if dist > float(cx):
				continue
			var c: Color
			if dist < 2.0:
				c = mat.BRIGHT
			elif dist < 3.5:
				c = mat.HIGHLIGHT
			elif dist < 5.5:
				c = mat.MID_HIGHLIGHT
			elif dist < 6.5:
				c = mat.MIDTONE
			elif dist < 8.0:
				c = mat.MID_SHADOW
			else:
				c = mat.OUTLINE
			PA.draw_pixel(img, x, y, c)


static func shard_sprite(img: Image, mat: Dictionary = ENERGY) -> void:
	# 16x16 faceted diamond shard — top bright, middle mid, bottom shadow
	var w := img.get_width()
	var h := img.get_height()
	var cx := w / 2
	for y in h:
		var half_w := (h - absi(y * 2 - h + 1)) / 2
		if half_w <= 0:
			continue
		for x in w:
			if absi(x - cx) > half_w:
				continue
			var edge_dist := absi(x - cx)
			var t := float(y) / float(h - 1)
			var c: Color
			if edge_dist >= half_w - 1:
				c = mat.OUTLINE
			elif edge_dist >= half_w - 2:
				c = mat.SHADOW
			elif t < 0.33:
				c = mat.HIGHLIGHT
			elif t < 0.66:
				c = mat.MIDTONE
			else:
				c = mat.MID_HIGHLIGHT if edge_dist < half_w - 3 else mat.MID_SHADOW
			PA.draw_pixel(img, x, y, c)


static func muzzle_flash_sprite(img: Image, mat: Dictionary = ENERGY) -> void:
	# 20x20 star burst — bright core + cross + diagonals + outer glow dots
	var w := img.get_width()
	var h := img.get_height()
	var cx := w / 2
	var cy := h / 2
	# Bright core
	PA.fill_rect(img, cx - 2, cy - 2, 5, 5, mat.BRIGHT)
	PA.fill_rect(img, cx - 1, cy - 1, 3, 3, mat.BASE)
	# Main cross
	PA.draw_h_line(img, cx - 7, cy, 15, mat.HIGHLIGHT)
	PA.draw_v_line(img, cx, cy - 7, 15, mat.HIGHLIGHT)
	PA.draw_h_line(img, cx - 5, cy, 11, mat.BRIGHT)
	PA.draw_v_line(img, cx, cy - 5, 11, mat.BRIGHT)
	# Diagonals (8 rays)
	for sgn_x in [-1, 1]:
		for sgn_y in [-1, 1]:
			for i in range(1, 5):
				PA.draw_pixel(img, cx + i * sgn_x, cy + i * sgn_y, mat.MID_HIGHLIGHT)
			PA.draw_pixel(img, cx + 5 * sgn_x, cy + 5 * sgn_y, mat.MIDTONE)
	# Outer glow dots
	PA.draw_pixel(img, cx - 8, cy, mat.MID_SHADOW)
	PA.draw_pixel(img, cx + 8, cy, mat.MID_SHADOW)
	PA.draw_pixel(img, cx, cy - 8, mat.MID_SHADOW)
	PA.draw_pixel(img, cx, cy + 8, mat.MID_SHADOW)


static func slash_arc_sprite(img: Image, mat: Dictionary = ENERGY) -> void:
	# Fan arc — diagonal sweep, size-adaptive, 5 gradient bands
	var w := img.get_width()
	var h := img.get_height()
	var cx := w / 2
	var cy := h / 2
	var outer_radius := float(cx) * 0.48
	var inner_radius := float(cx) * 0.20
	for y in h:
		for x in w:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(float(dx * dx + dy * dy))
			if dist < inner_radius or dist > outer_radius:
				continue
			var angle := atan2(float(-dy), float(dx))
			if angle < -1.2 or angle > 1.2:
				continue
			var t := (dist - inner_radius) / (outer_radius - inner_radius)
			var c: Color
			if t > 0.85:
				c = mat.BRIGHT
			elif t > 0.65:
				c = mat.HIGHLIGHT
			elif t > 0.40:
				c = mat.MID_HIGHLIGHT
			elif t > 0.20:
				c = mat.MIDTONE
			else:
				c = mat.SHADOW
			PA.draw_pixel(img, x, y, c)
