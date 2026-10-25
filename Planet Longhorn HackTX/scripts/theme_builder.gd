class_name ThemeBuilder
extends RefCounted
## Builds the one shared Theme in code from UIConst. Every screen calls
## `theme = ThemeBuilder.get_theme()` on its root Control.
## Type variations: TitleLabel, SubtitleLabel, HeadingLabel, VersionLabel, DialoguePanel.

static var _cached: Theme


static func get_theme() -> Theme:
	if _cached == null:
		_cached = _build()
	return _cached


static func _build() -> Theme:
	var t := Theme.new()
	t.default_font_size = UIConst.FONT_SIZE_BODY
	t.set_color("font_color", "Label", UIConst.COLOR_TEXT)

	_add_label_variation(t, "TitleLabel", UIConst.FONT_SIZE_TITLE, UIConst.COLOR_TEXT)
	t.set_constant("outline_size", "TitleLabel", UIConst.TITLE_OUTLINE_SIZE)
	t.set_color("font_outline_color", "TitleLabel", UIConst.COLOR_TITLE_GLOW)
	_add_label_variation(t, "SubtitleLabel", UIConst.FONT_SIZE_SUBTITLE, UIConst.COLOR_ACCENT)
	_add_label_variation(t, "HeadingLabel", UIConst.FONT_SIZE_HEADING, UIConst.COLOR_ACCENT)
	_add_label_variation(t, "VersionLabel", UIConst.FONT_SIZE_VERSION, UIConst.COLOR_TEXT_DIM)

	_style_button(t, "Button")
	_style_button(t, "CheckButton")
	_style_slider(t)

	t.set_stylebox("panel", "PanelContainer", _box(
			UIConst.COLOR_PANEL_FILL, UIConst.COLOR_PANEL_BORDER, UIConst.BORDER_WIDTH,
			UIConst.PANEL_PADDING, UIConst.COLOR_PANEL_BORDER))
	t.set_stylebox("background", "ProgressBar", _box(UIConst.COLOR_SLIDER_TRACK, UIConst.COLOR_PANEL_BORDER, 1, 0))
	t.set_stylebox("fill", "ProgressBar", _box(UIConst.COLOR_ACCENT, UIConst.COLOR_ACCENT, 1, 0))
	t.set_stylebox("normal", "LineEdit", _box(UIConst.COLOR_BUTTON_NORMAL, UIConst.COLOR_PANEL_BORDER, UIConst.BORDER_WIDTH, UIConst.BUTTON_PADDING))
	t.set_stylebox("focus", "LineEdit", _focus_box(UIConst.BUTTON_PADDING))
	t.set_font_size("font_size", "LineEdit", UIConst.FONT_SIZE_BUTTON)
	t.set_color("font_color", "LineEdit", UIConst.COLOR_TEXT)
	t.set_color("font_placeholder_color", "LineEdit", UIConst.COLOR_TEXT_DIM)
	t.set_color("caret_color", "LineEdit", UIConst.COLOR_FOCUS)
	t.set_type_variation("DialoguePanel", "PanelContainer")
	t.set_stylebox("panel", "DialoguePanel", _box(
			UIConst.COLOR_PANEL_FILL, UIConst.COLOR_ACCENT, UIConst.BORDER_WIDTH,
			StoryConst.BOX_PADDING, UIConst.COLOR_ACCENT))
	t.set_constant("separation", "VBoxContainer", UIConst.PANEL_SEPARATION)
	t.set_constant("separation", "HBoxContainer", UIConst.PANEL_SEPARATION)
	return t


static func _add_label_variation(t: Theme, variation: StringName, font_size: int, color: Color) -> void:
	t.set_type_variation(variation, "Label")
	t.set_font_size("font_size", variation, font_size)
	t.set_color("font_color", variation, color)


static func _style_button(t: Theme, type: StringName) -> void:
	var pad := UIConst.BUTTON_PADDING
	t.set_font_size("font_size", type, UIConst.FONT_SIZE_BUTTON)
	t.set_stylebox("normal", type, _box(UIConst.COLOR_BUTTON_NORMAL, UIConst.COLOR_PANEL_BORDER, UIConst.BORDER_WIDTH, pad))
	t.set_stylebox("hover", type, _box(UIConst.COLOR_BUTTON_HOVER, UIConst.COLOR_ACCENT, UIConst.BORDER_WIDTH, pad))
	t.set_stylebox("pressed", type, _box(UIConst.COLOR_BUTTON_PRESSED, UIConst.COLOR_ACCENT, UIConst.BORDER_WIDTH, pad))
	t.set_stylebox("hover_pressed", type, _box(UIConst.COLOR_BUTTON_PRESSED, UIConst.COLOR_ACCENT, UIConst.BORDER_WIDTH, pad))
	t.set_stylebox("disabled", type, _box(UIConst.COLOR_BUTTON_DISABLED, UIConst.COLOR_TEXT_DISABLED, UIConst.BORDER_WIDTH, pad))
	t.set_stylebox("focus", type, _focus_box(pad))
	for color_name: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color",
			&"font_hover_pressed_color", &"font_focus_color"]:
		t.set_color(color_name, type, UIConst.COLOR_TEXT)
	t.set_color("font_disabled_color", type, UIConst.COLOR_TEXT_DISABLED)


static func _style_slider(t: Theme) -> void:
	var half := UIConst.SLIDER_TRACK_THICKNESS / 2
	t.set_stylebox("slider", "HSlider", _box(UIConst.COLOR_SLIDER_TRACK, UIConst.COLOR_PANEL_BORDER, 1, half))
	t.set_stylebox("grabber_area", "HSlider", _box(UIConst.COLOR_ACCENT, UIConst.COLOR_ACCENT, 1, half))
	t.set_stylebox("grabber_area_highlight", "HSlider", _box(UIConst.COLOR_FOCUS, UIConst.COLOR_FOCUS, 1, half))
	t.set_stylebox("focus", "HSlider", _focus_box(half))
	var radius := UIConst.SLIDER_GRABBER_RADIUS
	t.set_icon("grabber", "HSlider", _circle_icon(radius, UIConst.COLOR_ACCENT))
	t.set_icon("grabber_highlight", "HSlider", _circle_icon(radius, UIConst.COLOR_FOCUS))
	t.set_icon("grabber_disabled", "HSlider", _circle_icon(radius, UIConst.COLOR_TEXT_DISABLED))


static func _box(fill: Color, border: Color, border_width: int, padding: int,
		glow: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(UIConst.CORNER_RADIUS)
	s.set_content_margin_all(padding)
	if glow.a > 0.0:
		s.shadow_color = Color(glow, 0.35)
		s.shadow_size = UIConst.GLOW_SIZE
	return s


# Drawn on top of the current state style, so it only draws the outline + glow.
static func _focus_box(padding: int) -> StyleBoxFlat:
	var s := _box(Color.TRANSPARENT, UIConst.COLOR_FOCUS, UIConst.FOCUS_BORDER_WIDTH, padding, UIConst.COLOR_FOCUS)
	s.draw_center = false
	return s


static func _circle_icon(radius: int, color: Color) -> ImageTexture:
	var diameter := radius * 2
	var img := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var center := Vector2(radius, radius)
	for y in diameter:
		for x in diameter:
			# One-pixel soft edge for antialiasing.
			var alpha := clampf(radius - Vector2(x + 0.5, y + 0.5).distance_to(center), 0.0, 1.0)
			img.set_pixel(x, y, Color(color, alpha))
	return ImageTexture.create_from_image(img)
