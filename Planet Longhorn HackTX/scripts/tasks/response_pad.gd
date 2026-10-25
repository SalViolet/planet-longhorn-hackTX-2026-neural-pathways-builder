class_name ResponsePad
extends Control
## A big push button for tasks that answer with one tap (Go/No-Go, CPT). It sits low on the
## screen, away from the stimulus. It sinks when pressed (mouse, touch or key) and registers
## on the way down, not on release. Clicking elsewhere does nothing. Its label never changes.

signal pressed_down

var label_text := ""
var face_color := Color.WHITE

var _pressed_until_us := 0
var _hover := false
var _drawn_pressed := false
var _drawn_hover := false


func setup(text: String, color: Color) -> void:
	label_text = text
	face_color = color
	custom_minimum_size = TaskConst.PAD_SIZE
	size = TaskConst.PAD_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


## Shows the button sinking (also called for key presses).
func press_visual() -> void:
	_pressed_until_us = Time.get_ticks_usec() + TaskConst.PAD_FLASH_MS * TaskConst.USEC_PER_MS
	queue_redraw()


func _process(_delta: float) -> void:
	_hover = is_visible_in_tree() and Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position())
	if _is_pressed() != _drawn_pressed or _hover != _drawn_hover:
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			press_visual()
			pressed_down.emit()


func _is_pressed() -> bool:
	return Time.get_ticks_usec() < _pressed_until_us


func _draw() -> void:
	_drawn_pressed = _is_pressed()
	_drawn_hover = _hover
	var depth := TaskConst.PAD_DEPTH
	var face_height := size.y - depth
	var offset := depth if _drawn_pressed else 0.0
	if not _drawn_pressed:
		_box(Rect2(0, depth, size.x, face_height), TaskConst.COLOR_PAD_SIDE)
	var color := face_color
	if _drawn_pressed:
		color = face_color.darkened(0.25)
	elif _drawn_hover:
		color = face_color.lightened(0.15)
	var face := Rect2(0, offset, size.x, face_height)
	_box(face, color)
	var font := get_theme_default_font()
	var font_size := TaskConst.PAD_FONT_SIZE
	var text_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var baseline := face.position.y + face.size.y / 2.0 + font.get_ascent(font_size) / 2.0 - font.get_descent(font_size) / 2.0
	draw_string(font, Vector2((size.x - text_size.x) / 2.0, baseline), label_text,
			HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, TaskConst.COLOR_PAD_TEXT)


func _box(rect: Rect2, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(TaskConst.PAD_RADIUS)
	draw_style_box(style, rect)
