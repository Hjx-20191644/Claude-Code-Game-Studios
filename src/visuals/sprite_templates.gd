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
	PA.fill_rect(img, 6, 0, 2, 3, O)
	PA.fill_rect(img, 16, 0, 2, 3, O)
	PA.outlined_rect(img, 8, 2, 8, 6, M, O)
	PA.fill_rect(img, 10, 4, 4, 1, O)
	PA.outlined_rect(img, 7, 8, 10, 7, B, O)
	PA.fill_rect(img, 10, 10, 4, 2, S)
	PA.outlined_rect(img, 2, 8, 4, 7, M, O)
	PA.outlined_rect(img, 18, 8, 4, 7, M, O)
	PA.fill_rect(img, 1, 14, 2, 2, O)
	PA.fill_rect(img, 21, 14, 2, 2, O)
	PA.outlined_rect(img, 5, 15, 5, 8, S, O)
	PA.outlined_rect(img, 14, 15, 5, 8, S, O)
	PA.fill_rect(img, 3, 22, 4, 2, O)
	PA.fill_rect(img, 17, 22, 4, 2, O)


static func enemy_ranged_sprite(img: Image) -> void:
	PA.outlined_rect(img, 9, 1, 6, 5, M, O)
	PA.fill_rect(img, 10, 3, 2, 1, H)
	PA.outlined_rect(img, 9, 6, 6, 9, B, O)
	PA.outlined_rect(img, 15, 8, 8, 3, M, O)
	PA.fill_rect(img, 22, 8, 2, 3, O)
	PA.outlined_rect(img, 6, 7, 2, 7, S, O)
	PA.outlined_rect(img, 8, 15, 3, 8, S, O)
	PA.outlined_rect(img, 13, 15, 3, 8, S, O)
	PA.fill_rect(img, 7, 22, 5, 2, O)
	PA.fill_rect(img, 12, 22, 5, 2, O)


static func enemy_charger_sprite(img: Image) -> void:
	PA.outlined_rect(img, 7, 0, 10, 6, M, O)
	PA.fill_rect(img, 9, 2, 6, 2, H)
	PA.outlined_rect(img, 5, 6, 14, 4, B, O)
	PA.fill_rect(img, 8, 7, 8, 2, H)
	PA.outlined_rect(img, 8, 9, 8, 8, M, O)
	PA.fill_rect(img, 6, 10, 3, 6, M)
	PA.outlined_rect(img, 4, 9, 3, 7, M, O)
	PA.outlined_rect(img, 17, 9, 3, 7, M, O)
	PA.fill_rect(img, 3, 14, 2, 3, O)
	PA.fill_rect(img, 19, 14, 2, 3, O)
	PA.outlined_rect(img, 7, 16, 4, 7, S, O)
	PA.outlined_rect(img, 13, 16, 4, 7, S, O)
	PA.fill_rect(img, 6, 22, 6, 2, O)
	PA.fill_rect(img, 12, 22, 6, 2, O)


static func enemy_exploder_sprite(img: Image) -> void:
	PA.fill_rect(img, 3, 2, 18, 2, O)
	PA.fill_rect(img, 1, 4, 2, 12, O)
	PA.fill_rect(img, 21, 4, 2, 12, O)
	PA.fill_rect(img, 2, 4, 20, 12, M)
	PA.fill_rect(img, 6, 6, 12, 8, H)
	PA.fill_rect(img, 3, 16, 18, 2, O)
	PA.fill_rect(img, 11, 0, 2, 3, O)
	PA.fill_rect(img, 11, 0, 2, 1, H)
	PA.outlined_rect(img, 5, 17, 3, 5, S, O)
	PA.outlined_rect(img, 16, 17, 3, 5, S, O)
	PA.fill_rect(img, 4, 22, 5, 2, O)
	PA.fill_rect(img, 15, 22, 5, 2, O)


static func enemy_tank_sprite(img: Image) -> void:
	PA.fill_rect(img, 10, 0, 4, 4, O)
	PA.fill_rect(img, 34, 0, 4, 4, O)
	PA.outlined_rect(img, 14, 2, 20, 8, M, O)
	PA.fill_rect(img, 20, 4, 8, 2, H)
	PA.outlined_rect(img, 6, 10, 36, 6, B, O)
	PA.fill_rect(img, 12, 12, 24, 2, H)
	PA.outlined_rect(img, 5, 16, 18, 22, M, O)
	PA.fill_rect(img, 8, 19, 12, 16, H)
	PA.outlined_rect(img, 14, 16, 20, 14, B, O)
	PA.fill_rect(img, 18, 19, 12, 6, H)
	PA.outlined_rect(img, 0, 16, 6, 10, M, O)
	PA.outlined_rect(img, 42, 16, 6, 10, M, O)
	PA.fill_rect(img, 0, 25, 6, 3, O)
	PA.fill_rect(img, 42, 25, 6, 3, O)
	PA.outlined_rect(img, 12, 30, 8, 14, S, O)
	PA.outlined_rect(img, 28, 30, 8, 14, S, O)
	PA.fill_rect(img, 10, 43, 12, 3, O)
	PA.fill_rect(img, 26, 43, 12, 3, O)
	PA.fill_rect(img, 10, 46, 28, 2, O)


static func enemy_boss_sprite(img: Image) -> void:
	PA.fill_rect(img, 30, 0, 2, 6, O)
	PA.fill_rect(img, 40, 0, 2, 6, O)
	PA.fill_rect(img, 35, 2, 2, 4, O)
	PA.outlined_rect(img, 28, 4, 16, 6, M, O)
	PA.fill_rect(img, 30, 6, 12, 2, H)
	PA.outlined_rect(img, 26, 10, 20, 10, M, O)
	PA.fill_rect(img, 30, 14, 4, 2, H)
	PA.fill_rect(img, 38, 14, 4, 2, H)
	PA.outlined_rect(img, 16, 20, 40, 8, S, O)
	PA.fill_rect(img, 20, 22, 32, 4, H)
	PA.fill_rect(img, 14, 20, 4, 8, O)
	PA.fill_rect(img, 54, 20, 4, 8, O)
	PA.outlined_rect(img, 24, 28, 24, 16, B, O)
	PA.fill_rect(img, 30, 31, 12, 4, H)
	PA.fill_rect(img, 32, 36, 8, 6, M)
	PA.outlined_rect(img, 10, 28, 8, 16, M, O)
	PA.outlined_rect(img, 54, 28, 8, 16, M, O)
	PA.fill_rect(img, 8, 43, 12, 4, O)
	PA.fill_rect(img, 52, 43, 12, 4, O)
	PA.outlined_rect(img, 24, 44, 24, 4, O, O)
	PA.fill_rect(img, 28, 45, 16, 2, H)
	PA.outlined_rect(img, 22, 48, 8, 16, S, O)
	PA.outlined_rect(img, 42, 48, 8, 16, S, O)
	PA.outlined_rect(img, 20, 62, 10, 6, M, O)
	PA.outlined_rect(img, 42, 62, 10, 6, M, O)
	PA.fill_rect(img, 18, 68, 14, 4, O)
	PA.fill_rect(img, 40, 68, 14, 4, O)


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
