extends RefCounted

## Pixel art shape templates. No class_name — use preload to access.

const PA = preload("res://src/visuals/pixel_art.gd")

const O = PA.OUTLINE
const S = PA.SHADOW
const M = PA.MIDTONE
const H = PA.HIGHLIGHT
const B = PA.BASE
const T = PA.TRANSPARENT


static func player_sprite(img: Image) -> void:
	# Brotato-style potato body — round, no limbs (limbs are separate sprites)
	PA.fill_rect(img, 3, 6, 18, 12, M)
	PA.fill_rect(img, 5, 4, 14, 4, M)
	PA.fill_rect(img, 5, 16, 14, 4, M)
	PA.fill_rect(img, 7, 3, 10, 2, M)
	PA.fill_rect(img, 7, 18, 10, 2, M)
	PA.draw_h_line(img, 5, 3, 14, O)
	PA.draw_h_line(img, 7, 2, 10, O)
	PA.draw_h_line(img, 4, 4, 2, O); PA.draw_h_line(img, 18, 4, 2, O)
	PA.draw_v_line(img, 3, 5, 14, O); PA.draw_v_line(img, 20, 5, 14, O)
	PA.draw_h_line(img, 4, 19, 2, O); PA.draw_h_line(img, 18, 19, 2, O)
	PA.draw_h_line(img, 5, 20, 14, O)
	PA.fill_rect(img, 8, 5, 8, 3, H)
	# Eyes
	PA.draw_pixel(img, 9, 10, B); PA.draw_pixel(img, 10, 10, B)
	PA.draw_pixel(img, 13, 10, B); PA.draw_pixel(img, 14, 10, B)
	PA.draw_pixel(img, 9, 11, O); PA.draw_pixel(img, 10, 11, O)
	PA.draw_pixel(img, 13, 11, O); PA.draw_pixel(img, 14, 11, O)
	# Mouth
	PA.draw_pixel(img, 10, 15, O); PA.draw_pixel(img, 11, 16, O)
	PA.draw_pixel(img, 12, 16, O); PA.draw_pixel(img, 13, 15, O)


static func arm_stick_sprite(img: Image) -> void:
	# 2×8 thin stick arm — 1px dark + 1px highlight
	PA.draw_v_line(img, 0, 0, 8, O)
	PA.draw_v_line(img, 1, 0, 8, H)
	# tiny hand
	PA.draw_pixel(img, 0, 0, H)


static func leg_stick_sprite(img: Image) -> void:
	# 2×8 thin stick leg — 1px dark + 1px highlight
	PA.draw_v_line(img, 0, 0, 8, O)
	PA.draw_v_line(img, 1, 0, 8, H)
	# tiny foot
	PA.draw_pixel(img, 0, 7, H)
	PA.draw_pixel(img, 1, 7, H)


static func enemy_melee_sprite(img: Image) -> void:
	# Cthulhu-style alien — tentacled face, hunched body, claw arms
	# Body: asymmetric lump
	PA.fill_rect(img, 5, 4, 14, 10, M)
	PA.fill_rect(img, 4, 6, 2, 6, M); PA.fill_rect(img, 18, 5, 2, 7, M)
	PA.fill_rect(img, 7, 3, 10, 3, M)
	PA.fill_rect(img, 8, 14, 8, 4, S)
	# Outline body
	PA.draw_h_line(img, 8, 2, 8, O)
	PA.draw_h_line(img, 5, 3, 2, O); PA.draw_h_line(img, 15, 2, 2, O)
	PA.draw_v_line(img, 3, 4, 8, O); PA.draw_v_line(img, 20, 4, 8, O)
	PA.draw_h_line(img, 4, 13, 16, O)
	PA.draw_h_line(img, 5, 14, 14, O)
	PA.draw_v_line(img, 5, 14, 4, O); PA.draw_v_line(img, 18, 14, 4, O)
	PA.draw_h_line(img, 6, 18, 12, O)
	# Tentacles around mouth
	PA.draw_v_line(img, 9, 13, 3, O); PA.draw_v_line(img, 14, 13, 3, O)
	PA.draw_pixel(img, 8, 14, O); PA.draw_pixel(img, 15, 14, O)
	PA.draw_v_line(img, 8, 15, 2, O); PA.draw_v_line(img, 15, 15, 2, O)
	# Eyes — 3 small glowing eyes
	PA.fill_rect(img, 8, 6, 2, 2, B)
	PA.fill_rect(img, 11, 5, 2, 2, B)
	PA.fill_rect(img, 14, 6, 2, 2, B)
	PA.draw_pixel(img, 8, 6, O); PA.draw_pixel(img, 11, 5, O); PA.draw_pixel(img, 14, 6, O)
	# Claw arms
	PA.draw_v_line(img, 2, 7, 6, O); PA.draw_v_line(img, 21, 6, 7, O)
	PA.draw_pixel(img, 1, 7, O); PA.draw_pixel(img, 22, 6, O)
	PA.draw_h_line(img, 0, 9, 3, O); PA.draw_h_line(img, 21, 8, 3, O)
	# Legs
	PA.draw_v_line(img, 9, 18, 5, O); PA.draw_v_line(img, 15, 18, 5, O)
	PA.draw_pixel(img, 8, 22, O); PA.draw_pixel(img, 16, 22, O)


static func enemy_ranged_sprite(img: Image) -> void:
	# Alien spitter — elongated head, projectile gland, thin body
	# Head (elongated back)
	PA.fill_rect(img, 3, 2, 18, 8, M)
	PA.fill_rect(img, 1, 4, 4, 4, M)
	PA.fill_rect(img, 5, 1, 14, 3, M)
	# Outline head
	PA.draw_h_line(img, 6, 0, 12, O)
	PA.draw_h_line(img, 3, 1, 4, O); PA.draw_h_line(img, 15, 1, 4, O)
	PA.draw_v_line(img, 2, 2, 6, O)
	PA.draw_h_line(img, 1, 8, 20, O)
	PA.draw_v_line(img, 1, 4, 4, O)
	# Eyes — single large eye
	PA.fill_rect(img, 8, 4, 4, 3, B)
	PA.draw_pixel(img, 9, 5, O); PA.draw_pixel(img, 11, 5, O)
	# Spitting tube
	PA.draw_v_line(img, 19, 3, 5, O)
	PA.draw_h_line(img, 20, 4, 3, O)
	PA.draw_pixel(img, 22, 5, H)
	# Body
	PA.fill_rect(img, 6, 9, 10, 8, S)
	PA.fill_rect(img, 8, 10, 6, 6, M)
	PA.draw_h_line(img, 7, 17, 8, O)
	PA.draw_v_line(img, 5, 9, 8, O); PA.draw_v_line(img, 17, 9, 8, O)
	# Thin legs
	PA.draw_v_line(img, 8, 17, 6, O); PA.draw_v_line(img, 14, 17, 6, O)
	PA.draw_pixel(img, 7, 22, O); PA.draw_pixel(img, 15, 22, O)
	# Arms
	PA.draw_v_line(img, 5, 10, 5, O); PA.draw_v_line(img, 17, 10, 5, O)


static func enemy_charger_sprite(img: Image) -> void:
	# Streamlined predator — pointed head, lean body, forward posture
	# Pointed snout
	PA.fill_rect(img, 0, 8, 4, 4, O)
	PA.draw_h_line(img, 3, 7, 3, O); PA.draw_h_line(img, 3, 12, 3, O)
	PA.draw_pixel(img, 0, 9, M); PA.draw_pixel(img, 0, 10, H)
	# Head
	PA.fill_rect(img, 3, 4, 10, 10, M)
	PA.draw_h_line(img, 4, 3, 8, O)
	PA.draw_v_line(img, 3, 4, 10, O); PA.draw_v_line(img, 13, 4, 10, O)
	# Eyes — angled, aggressive
	PA.fill_rect(img, 6, 6, 2, 2, B); PA.fill_rect(img, 10, 6, 2, 2, B)
	PA.draw_pixel(img, 5, 6, O); PA.draw_pixel(img, 7, 7, O)
	PA.draw_pixel(img, 11, 6, O); PA.draw_pixel(img, 13, 7, O)
	# Body
	PA.fill_rect(img, 6, 14, 8, 6, S)
	PA.fill_rect(img, 7, 13, 6, 2, M)
	PA.draw_h_line(img, 5, 20, 10, O)
	PA.draw_v_line(img, 5, 14, 6, O); PA.draw_v_line(img, 15, 14, 6, O)
	# Legs — running pose
	PA.draw_v_line(img, 8, 20, 3, O); PA.draw_h_line(img, 7, 22, 3, O)
	PA.draw_v_line(img, 14, 20, 3, O); PA.draw_h_line(img, 13, 22, 3, O)
	# Dorsal fins
	PA.draw_v_line(img, 12, 3, 3, O); PA.draw_pixel(img, 11, 4, O)


static func enemy_exploder_sprite(img: Image) -> void:
	# Bloated pustule alien — round, veiny, about to burst
	# Main body — very round
	PA.fill_rect(img, 4, 4, 16, 14, M)
	PA.fill_rect(img, 7, 2, 10, 4, M)
	PA.fill_rect(img, 6, 18, 12, 3, M)
	PA.fill_rect(img, 9, 1, 6, 2, M)
	PA.fill_rect(img, 10, 20, 4, 2, S)
	# Outline
	PA.draw_h_line(img, 10, 0, 4, O)
	PA.draw_h_line(img, 5, 1, 6, O); PA.draw_h_line(img, 15, 1, 2, O)
	PA.draw_h_line(img, 3, 2, 4, O); PA.draw_h_line(img, 17, 2, 4, O)
	PA.draw_v_line(img, 2, 3, 14, O); PA.draw_v_line(img, 21, 3, 14, O)
	PA.draw_h_line(img, 4, 17, 4, O); PA.draw_h_line(img, 16, 17, 4, O)
	PA.draw_h_line(img, 6, 18, 12, O)
	PA.draw_h_line(img, 8, 19, 8, O)
	PA.draw_h_line(img, 10, 20, 4, O)
	# Fuse
	PA.draw_v_line(img, 12, 0, 3, O)
	PA.draw_pixel(img, 11, 0, H)  # spark
	# Eyes — crazed, different sizes
	PA.fill_rect(img, 8, 7, 3, 3, B)
	PA.fill_rect(img, 13, 6, 2, 3, B)
	PA.draw_pixel(img, 9, 8, O); PA.draw_pixel(img, 14, 7, O)
	# Mouth — gasping
	PA.fill_rect(img, 9, 13, 5, 3, O)
	PA.draw_pixel(img, 10, 13, H)
	# Veins
	PA.draw_v_line(img, 5, 7, 3, O); PA.draw_v_line(img, 19, 8, 3, O)
	PA.draw_pixel(img, 6, 10, O); PA.draw_pixel(img, 18, 11, O)
	# Tiny legs
	PA.draw_v_line(img, 8, 20, 3, O); PA.draw_v_line(img, 15, 20, 3, O)
	PA.draw_pixel(img, 7, 22, O); PA.draw_pixel(img, 16, 22, O)


static func enemy_tank_sprite(img: Image) -> void:
	# Hulking eldritch brute — massive body, thick carapace, heavy arms
	# Body core
	PA.fill_rect(img, 10, 6, 28, 22, M)
	PA.fill_rect(img, 14, 4, 20, 4, M)
	PA.fill_rect(img, 8, 10, 4, 14, M); PA.fill_rect(img, 36, 10, 4, 14, M)
	# Outline body
	PA.draw_h_line(img, 15, 3, 18, O); PA.draw_h_line(img, 11, 4, 4, O); PA.draw_h_line(img, 33, 4, 4, O)
	PA.draw_h_line(img, 9, 5, 4, O); PA.draw_h_line(img, 35, 5, 4, O)
	PA.draw_v_line(img, 8, 6, 18, O); PA.draw_v_line(img, 40, 6, 18, O)
	PA.draw_h_line(img, 10, 28, 28, O)
	# Carapace plates
	PA.draw_h_line(img, 12, 8, 24, S); PA.draw_h_line(img, 12, 16, 24, S)
	PA.draw_h_line(img, 14, 12, 20, H)
	# Eyes — tiny, recessed
	PA.fill_rect(img, 16, 9, 4, 3, B)
	PA.fill_rect(img, 28, 9, 4, 3, B)
	PA.draw_pixel(img, 17, 10, O); PA.draw_pixel(img, 29, 10, O)
	# Mouth — mandibles
	PA.draw_v_line(img, 22, 18, 4, O); PA.draw_v_line(img, 26, 18, 4, O)
	PA.draw_h_line(img, 19, 21, 10, O)
	PA.draw_pixel(img, 20, 19, O); PA.draw_pixel(img, 28, 19, O)
	# Heavy arms
	PA.fill_rect(img, 2, 12, 6, 8, S); PA.fill_rect(img, 40, 12, 6, 8, S)
	PA.draw_v_line(img, 1, 13, 6, O); PA.draw_v_line(img, 47, 13, 6, O)
	PA.draw_h_line(img, 0, 18, 3, O); PA.draw_h_line(img, 45, 18, 3, O)
	PA.draw_pixel(img, 1, 19, H); PA.draw_pixel(img, 46, 19, H)
	# Legs — thick pillars
	PA.fill_rect(img, 14, 28, 6, 12, S); PA.fill_rect(img, 28, 28, 6, 12, S)
	PA.draw_v_line(img, 13, 29, 10, O); PA.draw_v_line(img, 35, 29, 10, O)
	PA.draw_v_line(img, 20, 29, 10, O); PA.draw_v_line(img, 28, 29, 10, O)
	PA.fill_rect(img, 12, 38, 10, 4, O); PA.fill_rect(img, 26, 38, 10, 4, O)
	PA.draw_h_line(img, 10, 42, 28, O)


static func enemy_boss_sprite(img: Image) -> void:
	# Eldritch horror — massive asymmetrical body, crown of eyes, tentacles
	# Crown/horns
	PA.fill_rect(img, 20, 0, 8, 6, O)
	PA.fill_rect(img, 44, 0, 8, 6, O)
	PA.fill_rect(img, 32, 0, 8, 4, O)
	PA.fill_rect(img, 30, 2, 12, 2, H)
	PA.draw_v_line(img, 24, 3, 5, O); PA.draw_v_line(img, 48, 3, 5, O)
	# Crown eyes
	PA.fill_rect(img, 26, 1, 3, 3, B); PA.fill_rect(img, 43, 1, 3, 3, B)
	PA.draw_pixel(img, 27, 2, O); PA.draw_pixel(img, 44, 2, O)
	# Head
	PA.fill_rect(img, 18, 6, 36, 16, M)
	PA.fill_rect(img, 22, 4, 28, 4, M)
	PA.draw_h_line(img, 23, 3, 26, O)
	PA.draw_v_line(img, 17, 4, 16, O); PA.draw_v_line(img, 54, 4, 16, O)
	PA.draw_h_line(img, 18, 22, 36, O)
	# Main eyes — three large eyes
	PA.fill_rect(img, 22, 9, 5, 4, B)
	PA.fill_rect(img, 34, 8, 5, 5, B)
	PA.fill_rect(img, 46, 9, 5, 4, B)
	PA.draw_pixel(img, 24, 10, O); PA.draw_pixel(img, 36, 10, O); PA.draw_pixel(img, 48, 10, O)
	# Mouth — gaping maw
	PA.fill_rect(img, 26, 18, 20, 6, O)
	PA.fill_rect(img, 28, 18, 16, 2, H)
	PA.draw_pixel(img, 30, 20, B); PA.draw_pixel(img, 34, 20, B)
	PA.draw_pixel(img, 38, 20, B); PA.draw_pixel(img, 42, 20, B)
	# Body — massive torso
	PA.fill_rect(img, 12, 24, 48, 24, S)
	PA.fill_rect(img, 16, 23, 40, 4, M)
	PA.draw_h_line(img, 13, 24, 46, O)
	PA.draw_v_line(img, 11, 25, 22, O); PA.draw_v_line(img, 60, 25, 22, O)
	PA.draw_h_line(img, 14, 48, 44, O)
	# Body highlights
	PA.fill_rect(img, 18, 27, 14, 16, M)
	PA.fill_rect(img, 40, 27, 14, 16, M)
	PA.fill_rect(img, 28, 30, 16, 12, H)
	# Tentacles — bottom
	for i in range(4):
		var bx := 18 + i * 9
		PA.draw_v_line(img, bx, 48, 8, O)
		PA.draw_pixel(img, bx + 1, 50, O)
		PA.draw_pixel(img, bx - 1, 52, O) if i % 2 == 0 else PA.draw_pixel(img, bx + 2, 52, O)
	# Arms — massive claws
	PA.fill_rect(img, 2, 26, 10, 14, S); PA.fill_rect(img, 60, 26, 10, 14, S)
	PA.draw_v_line(img, 1, 27, 12, O); PA.draw_v_line(img, 71, 27, 12, O)
	PA.draw_h_line(img, 0, 33, 4, O); PA.draw_h_line(img, 68, 33, 4, O)
	PA.draw_pixel(img, 0, 38, O); PA.draw_pixel(img, 72, 38, O)
	PA.draw_v_line(img, 12, 28, 4, O); PA.draw_v_line(img, 60, 28, 4, O)
	# Legs — thick
	PA.fill_rect(img, 22, 56, 10, 12, S); PA.fill_rect(img, 40, 56, 10, 12, S)
	PA.draw_v_line(img, 21, 57, 10, O); PA.draw_v_line(img, 50, 57, 10, O)
	PA.draw_v_line(img, 32, 57, 10, O); PA.draw_v_line(img, 40, 57, 10, O)
	PA.fill_rect(img, 20, 67, 14, 4, O); PA.fill_rect(img, 38, 67, 14, 4, O)


static func bullet_sprite(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var cx := w / 2
	var cy := h / 2
	for y in h:
		for x in w:
			var dx := absi(x - cx)
			var dy := absi(y - cy)
			if dx + dy <= 3:
				var c := H
				if dx + dy >= 3:
					c = O
				elif dx + dy >= 2:
					c = M
				PA.draw_pixel(img, x, y, c)


static func sword_sprite(img: Image) -> void:
	# 8x16 blade — grey handle, white blade
	PA.outlined_rect(img, 3, 2, 2, 4, M, O)
	PA.outlined_rect(img, 3, 0, 2, 3, H, O)
	PA.draw_pixel(img, 4, 5, H)


static func gun_sprite(img: Image) -> void:
	# 12x8 pistol — dark body + bright barrel
	PA.outlined_rect(img, 2, 2, 8, 4, M, O)
	PA.fill_rect(img, 9, 3, 3, 2, H)
	PA.draw_pixel(img, 6, 1, O)


static func slash_arc_sprite(img: Image) -> void:
	# 48x48 fan arc — diagonal sweep with bright edge
	var w := img.get_width()
	var h := img.get_height()
	var cx := w / 2
	var cy := h / 2
	for y in h:
		for x in w:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(float(dx * dx + dy * dy))
			if dist < 10 or dist > 24:
				continue
			var angle := atan2(float(-dy), float(dx))
			if angle < -1.2 or angle > 1.2:
				continue
			var c := M
			if dist > 22:
				c = H
			elif dist < 12:
				c = S
			PA.draw_pixel(img, x, y, c)


static func muzzle_flash_sprite(img: Image) -> void:
	# 10x10 star burst — cross + diagonals
	var w := img.get_width()
	var h := img.get_height()
	var cx := w / 2
	var cy := h / 2
	PA.draw_h_line(img, cx - 3, cy, 7, H)
	PA.draw_v_line(img, cx, cy - 3, 7, H)
	PA.draw_pixel(img, cx - 2, cy - 2, H)
	PA.draw_pixel(img, cx + 2, cy - 2, H)
	PA.draw_pixel(img, cx - 2, cy + 2, H)
	PA.draw_pixel(img, cx + 2, cy + 2, H)
	PA.draw_h_line(img, cx - 1, cy, 3, B)


static func shard_sprite(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		var half_w := (h - absi(y * 2 - h + 1)) / 2
		for x in w:
			var cx := w / 2
			if absi(x - cx) <= half_w and half_w > 0:
				var edge_dist := absi(x - cx)
				var c := H
				if edge_dist >= half_w - 1:
					c = O
				elif edge_dist >= half_w - 2:
					c = M
				PA.draw_pixel(img, x, y, c)
