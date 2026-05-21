extends RefCounted
class_name PixelTheme

## Pixel-art UI theme helpers.
## Generates StyleBoxFlat with no rounded corners, 1px solid borders, flat colors.

const UI_BG: Color = Color(0.06, 0.06, 0.10)
const UI_PANEL: Color = Color(0.10, 0.10, 0.16)
const UI_BORDER: Color = Color(0.30, 0.30, 0.40)
const UI_TEXT: Color = Color(0.90, 0.90, 0.95)
const UI_ACCENT: Color = Color(0.30, 0.70, 1.00)
const UI_DANGER: Color = Color(1.00, 0.30, 0.30)
const UI_SUCCESS: Color = Color(0.50, 0.90, 0.50)
const UI_GOLD: Color = Color(1.00, 0.84, 0.00)
const UI_DIM: Color = Color(0.50, 0.50, 0.55)


static func panel_flat(color: Color = UI_PANEL, border: Color = UI_BORDER) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_color = border
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	return sb


static func panel_inset(color: Color = UI_PANEL, border: Color = UI_BORDER, inset: int = 4) -> StyleBoxFlat:
	var sb := panel_flat(color, border)
	sb.content_margin_left = inset
	sb.content_margin_right = inset
	sb.content_margin_top = inset
	sb.content_margin_bottom = inset
	return sb


static func button_normal(bg: Color = Color(0.15, 0.15, 0.25), border: Color = UI_BORDER) -> StyleBoxFlat:
	return panel_inset(bg, border, 6)


static func button_hover(bg: Color = Color(0.20, 0.25, 0.40)) -> StyleBoxFlat:
	return panel_inset(bg, Color(0.50, 0.50, 0.65), 6)


static func button_pressed(bg: Color = Color(0.08, 0.08, 0.15)) -> StyleBoxFlat:
	return panel_inset(bg, Color(0.25, 0.25, 0.35), 6)


static func card(border_color: Color = UI_BORDER) -> StyleBoxFlat:
	return panel_inset(Color(0.08, 0.08, 0.14), border_color, 8)


static func tag_chip(bg_color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_width_left = 0
	sb.border_width_right = 0
	sb.border_width_top = 0
	sb.border_width_bottom = 0
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	return sb


static func set_label(label: Label, font_size: int = 16, color: Color = UI_TEXT) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)


static func set_button(button: Button, font_size: int = 16) -> void:
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", UI_TEXT)
	button.add_theme_color_override("font_hover_color", UI_TEXT)
	button.add_theme_color_override("font_pressed_color", UI_ACCENT)
	button.add_theme_stylebox_override("normal", button_normal())
	button.add_theme_stylebox_override("hover", button_hover())
	button.add_theme_stylebox_override("pressed", button_pressed())
