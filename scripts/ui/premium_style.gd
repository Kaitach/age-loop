class_name PremiumStyle
extends RefCounted

const GOLD := Color(0.92, 0.68, 0.24, 1.0)
const GOLD_BRIGHT := Color(1.0, 0.86, 0.46, 1.0)
const BLUE := Color(0.055, 0.12, 0.23, 0.98)
const BLUE_HOVER := Color(0.10, 0.25, 0.42, 1.0)
const BLUE_PRESSED := Color(0.025, 0.06, 0.13, 1.0)
const GREEN := Color(0.08, 0.30, 0.23, 0.98)
const GREEN_HOVER := Color(0.12, 0.48, 0.34, 1.0)
const BROWN := Color(0.18, 0.12, 0.08, 0.98)
const BROWN_HOVER := Color(0.34, 0.22, 0.12, 1.0)

static func style_button(button: Button, variant: String = "blue") -> void:
	var colors := _button_colors(variant)
	for entry in [["normal", colors[0]], ["hover", colors[1]], ["pressed", colors[2]], ["focus", colors[1]]]:
		var style := StyleBoxFlat.new()
		style.bg_color = entry[1]
		style.border_color = GOLD_BRIGHT if entry[0] == "hover" else GOLD
		style.set_border_width_all(1 if entry[0] != "hover" else 2)
		style.set_corner_radius_all(14)
		style.shadow_color = Color(0.0, 0.01, 0.03, 0.58)
		style.shadow_size = 10 if entry[0] != "pressed" else 4
		style.content_margin_left = 22.0
		style.content_margin_right = 22.0
		style.content_margin_top = 13.0
		style.content_margin_bottom = 13.0
		button.add_theme_stylebox_override(entry[0], style)
	button.add_theme_color_override("font_color", Color(0.98, 0.96, 0.9, 1))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.86, 0.5, 1))
	button.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04, 0.85))
	button.add_theme_constant_override("outline_size", 3)
	button.add_theme_constant_override("h_separation", 20)

static func load_icon(path: String, size: int = 64) -> Texture2D:
	var texture := load(path) as Texture2D
	if texture == null or size <= 0:
		return texture
	var image := texture.get_image()
	if image == null or image.is_empty():
		return texture
	image.resize(size, size, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)

static func style_panel(panel: PanelContainer, accent: Color = GOLD) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.04, 0.07, 0.94)
	style.border_color = Color(accent, 0.82)
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0.0, 0.01, 0.02, 0.72)
	style.shadow_size = 16
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 24.0
	style.content_margin_bottom = 24.0
	panel.add_theme_stylebox_override("panel", style)

static func style_title(label: Label, size: int = 72) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.39, 1))
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.05, 0.96))
	label.add_theme_constant_override("outline_size", 7)

static func _button_colors(variant: String) -> Array[Color]:
	match variant:
		"green": return [GREEN, GREEN_HOVER, Color(0.07, 0.22, 0.09, 1)]
		"brown": return [BROWN, BROWN_HOVER, Color(0.1, 0.06, 0.03, 1)]
		"gold": return [Color(0.34, 0.2, 0.06, 0.98), Color(0.52, 0.32, 0.08, 1), Color(0.22, 0.12, 0.03, 1)]
		_: return [BLUE, BLUE_HOVER, BLUE_PRESSED]
