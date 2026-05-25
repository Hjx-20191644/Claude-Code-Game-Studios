extends RefCounted

## Procedural pixel art sprite generation. No class_name — use preload to access.
## Generates grayscale sprite textures that receive color at runtime via self_modulate.

# ── Grayscale level values ────────────────────────────────────────────
const G_DEEP_SHADOW: float = 0.02
const G_OUTLINE: float = 0.05
const G_SHADOW: float = 0.15
const G_MID_SHADOW: float = 0.30
const G_MIDTONE: float = 0.55
const G_MID_HIGHLIGHT: float = 0.72
const G_HIGHLIGHT: float = 0.88
const G_BRIGHT: float = 0.96
const G_BASE: float = 1.00

# ── Backward-compatible aliases ───────────────────────────────────────
const OUTLINE: Color = Color(G_OUTLINE, G_OUTLINE, G_OUTLINE)
const SHADOW: Color = Color(G_SHADOW, G_SHADOW, G_SHADOW)
const MIDTONE: Color = Color(G_MIDTONE, G_MIDTONE, G_MIDTONE)
const HIGHLIGHT: Color = Color(G_HIGHLIGHT, G_HIGHLIGHT, G_HIGHLIGHT)
const BASE: Color = Color.WHITE
const TRANSPARENT: Color = Color(0, 0, 0, 0)

# ── New single-Color convenience aliases ──────────────────────────────
const DEEP_SHADOW: Color = Color(G_DEEP_SHADOW, G_DEEP_SHADOW, G_DEEP_SHADOW)
const MID_SHADOW: Color = Color(G_MID_SHADOW, G_MID_SHADOW, G_MID_SHADOW)
const MID_HIGHLIGHT: Color = Color(G_MID_HIGHLIGHT, G_MID_HIGHLIGHT, G_MID_HIGHLIGHT)
const BRIGHT: Color = Color(G_BRIGHT, G_BRIGHT, G_BRIGHT)

# ── Material presets ──────────────────────────────────────────────────
const MATERIAL_METAL: Dictionary = {
	"DEEP_SHADOW": Color(0.01, 0.01, 0.01),
	"OUTLINE": Color(0.04, 0.04, 0.04),
	"SHADOW": Color(0.10, 0.10, 0.10),
	"MID_SHADOW": Color(0.22, 0.22, 0.22),
	"MIDTONE": Color(0.45, 0.45, 0.45),
	"MID_HIGHLIGHT": Color(0.72, 0.72, 0.72),
	"HIGHLIGHT": Color(0.92, 0.92, 0.92),
	"BRIGHT": Color(1.00, 1.00, 1.00),
	"BASE": Color.WHITE,
}
const MATERIAL_FLESH: Dictionary = {
	"DEEP_SHADOW": Color(0.03, 0.03, 0.03),
	"OUTLINE": Color(0.06, 0.06, 0.06),
	"SHADOW": Color(0.18, 0.18, 0.18),
	"MID_SHADOW": Color(0.33, 0.33, 0.33),
	"MIDTONE": Color(0.55, 0.55, 0.55),
	"MID_HIGHLIGHT": Color(0.68, 0.68, 0.68),
	"HIGHLIGHT": Color(0.82, 0.82, 0.82),
	"BRIGHT": Color(0.94, 0.94, 0.94),
	"BASE": Color.WHITE,
}
const MATERIAL_CLOTH: Dictionary = {
	"DEEP_SHADOW": Color(0.04, 0.04, 0.04),
	"OUTLINE": Color(0.07, 0.07, 0.07),
	"SHADOW": Color(0.20, 0.20, 0.20),
	"MID_SHADOW": Color(0.38, 0.38, 0.38),
	"MIDTONE": Color(0.58, 0.58, 0.58),
	"MID_HIGHLIGHT": Color(0.68, 0.68, 0.68),
	"HIGHLIGHT": Color(0.78, 0.78, 0.78),
	"BRIGHT": Color(0.90, 0.90, 0.90),
	"BASE": Color.WHITE,
}
const MATERIAL_ENERGY: Dictionary = {
	"DEEP_SHADOW": Color(0.05, 0.05, 0.05),
	"OUTLINE": Color(0.08, 0.08, 0.08),
	"SHADOW": Color(0.20, 0.20, 0.20),
	"MID_SHADOW": Color(0.40, 0.40, 0.40),
	"MIDTONE": Color(0.60, 0.60, 0.60),
	"MID_HIGHLIGHT": Color(0.80, 0.80, 0.80),
	"HIGHLIGHT": Color(0.95, 0.95, 0.95),
	"BRIGHT": Color(1.00, 1.00, 1.00),
	"BASE": Color.WHITE,
}

static var _cache: Dictionary = {}


static func generate_sprite(width: int, height: int, draw_func: Callable, extra_args: Array = []) -> ImageTexture:
	var key := "%s_%dx%d" % [draw_func.get_method(), width, height]
	if extra_args.size() > 0:
		key += "_" + "_".join(PackedStringArray(extra_args.map(func(a): return str(a))))
	if _cache.has(key):
		return _cache[key]

	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)
	draw_func.callv([image] + extra_args)

	var tex := ImageTexture.create_from_image(image)
	_cache[key] = tex
	return tex


static func generate_animated_frames(draw_funcs: Array, width: int, height: int, extra_args: Array = []) -> Array[ImageTexture]:
	var frames: Array[ImageTexture] = []
	frames.resize(draw_funcs.size())
	for i in draw_funcs.size():
		frames[i] = generate_sprite(width, height, draw_funcs[i], extra_args)
	return frames


# ── Low-level drawing primitives ──────────────────────────────────────

static func draw_pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
		image.set_pixel(x, y, color)


static func fill_rect(image: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for py in range(maxi(0, y), mini(image.get_height(), y + h)):
		for px in range(maxi(0, x), mini(image.get_width(), x + w)):
			image.set_pixel(px, py, color)


static func draw_h_line(image: Image, x: int, y: int, length: int, color: Color) -> void:
	for px in range(maxi(0, x), mini(image.get_width(), x + length)):
		draw_pixel(image, px, y, color)


static func draw_v_line(image: Image, x: int, y: int, length: int, color: Color) -> void:
	for py in range(maxi(0, y), mini(image.get_height(), y + length)):
		draw_pixel(image, x, py, color)


static func outlined_rect(image: Image, x: int, y: int, w: int, h: int, fill: Color, outline: Color = OUTLINE) -> void:
	fill_rect(image, x, y, w, h, fill)
	draw_h_line(image, x, y, w, outline)
	draw_h_line(image, x, y + h - 1, w, outline)
	draw_v_line(image, x, y, h, outline)
	draw_v_line(image, x + w - 1, y, h, outline)
