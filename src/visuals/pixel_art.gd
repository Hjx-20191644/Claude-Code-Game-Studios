extends RefCounted

## Procedural pixel art sprite generation. No class_name — use preload to access.
## Generates grayscale sprite textures that receive color at runtime via self_modulate.

const OUTLINE: Color = Color(0.05, 0.05, 0.05)
const SHADOW: Color = Color(0.25, 0.25, 0.25)
const MIDTONE: Color = Color(0.55, 0.55, 0.55)
const HIGHLIGHT: Color = Color(0.85, 0.85, 0.85)
const BASE: Color = Color.WHITE
const TRANSPARENT: Color = Color(0, 0, 0, 0)

static var _cache: Dictionary = {}


static func generate_sprite(width: int, height: int, draw_func: Callable) -> ImageTexture:
	var key := "%s_%dx%d" % [draw_func.get_method(), width, height]
	if _cache.has(key):
		return _cache[key]

	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)
	draw_func.call(image)

	var tex := ImageTexture.create_from_image(image)
	_cache[key] = tex
	return tex


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
