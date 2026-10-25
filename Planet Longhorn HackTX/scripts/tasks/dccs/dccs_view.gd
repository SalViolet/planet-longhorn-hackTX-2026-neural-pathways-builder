class_name DccsView
extends Control
## Draws the two pens, the cue sign and the gift to sort. Each pen is a big push button: the
## card in it sinks when pressed (mouse, touch or arrow key). The press registers on the
## way down, not on release. Nothing else here animates.
## Shape coordinates are in character units, scaled by screen height / 1080.

signal pen_pressed(side: int)

enum Mode { IDLE, CUE, STIMULUS }

var _mode: Mode = Mode.IDLE
var _rule := DccsStimulus.Rule.COLOR
var _hue := DccsStimulus.Hue.BLUE
var _shape := DccsStimulus.Shape.STAR
var _pressed_side := -1
var _pressed_until_us := 0
var _hover_side := -1
var _drawn_pressed := -1
var _drawn_hover := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(_delta: float) -> void:
	_hover_side = _pen_at(get_local_mouse_position())
	if _current_pressed() != _drawn_pressed or _hover_side != _drawn_hover:
		queue_redraw()


## Shows a pen sinking, for key presses (mouse presses do this themselves).
func press_visual(side: int) -> void:
	_pressed_side = side
	_pressed_until_us = Time.get_ticks_usec() + DccsConst.PRESS_FLASH_MS * TaskConst.USEC_PER_MS
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse := event as InputEventMouseButton
	if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	var side := _pen_at(mouse.position)
	if side < 0:
		return # Only the pens are buttons; the rest of the screen does nothing.
	accept_event()
	press_visual(side)
	pen_pressed.emit(side)


func _pen_rect(side: int) -> Rect2:
	var k := size.y / DccsConst.SCREEN_UNIT_HEIGHT
	var x := DccsConst.PEN_X if side == DccsStimulus.Pen.LEFT else 1.0 - DccsConst.PEN_X
	var center := Vector2(size.x * x, size.y * DccsConst.PEN_Y)
	var half := DccsConst.PEN_SIZE * k / 2.0
	return Rect2(center - half, half * 2.0)


func _pen_at(point: Vector2) -> int:
	for side in [DccsStimulus.Pen.LEFT, DccsStimulus.Pen.RIGHT]:
		if _pen_rect(side).has_point(point):
			return side
	return -1


func _current_pressed() -> int:
	return _pressed_side if Time.get_ticks_usec() < _pressed_until_us else -1


func show_cue(rule: int) -> void:
	_mode = Mode.CUE
	_rule = rule as DccsStimulus.Rule
	queue_redraw()


func show_stimulus(rule: int, hue: int, shape: int) -> void:
	_mode = Mode.STIMULUS
	_rule = rule as DccsStimulus.Rule
	_hue = hue as DccsStimulus.Hue
	_shape = shape as DccsStimulus.Shape
	queue_redraw()


func clear_trial() -> void:
	_mode = Mode.IDLE
	queue_redraw()


func _draw() -> void:
	var k := size.y / DccsConst.SCREEN_UNIT_HEIGHT
	_drawn_pressed = _current_pressed()
	_drawn_hover = _hover_side
	_draw_pen(DccsStimulus.Pen.LEFT, Vector2(size.x * DccsConst.PEN_X, size.y * DccsConst.PEN_Y), k, DccsStimulus.Hue.BLUE, DccsStimulus.Shape.STAR)
	_draw_pen(DccsStimulus.Pen.RIGHT, Vector2(size.x * (1.0 - DccsConst.PEN_X), size.y * DccsConst.PEN_Y), k, DccsStimulus.Hue.ORANGE, DccsStimulus.Shape.ROUND)
	var middle := size.x / 2.0
	if _mode == Mode.CUE:
		_draw_cue(Vector2(middle, size.y * DccsConst.STIMULUS_Y), k * DccsConst.CUE_BIG_SCALE)
	elif _mode == Mode.STIMULUS:
		_draw_cue(Vector2(middle, size.y * DccsConst.CUE_Y), k * DccsConst.CUE_SMALL_SCALE)
		_draw_card(Vector2(middle, size.y * DccsConst.STIMULUS_Y), k * DccsConst.STIMULUS_SCALE, _hue, _shape)


# A fenced pen with its target card inside. The whole pen is the button; the card sinks when pressed.
func _draw_pen(side: int, center: Vector2, k: float, hue: DccsStimulus.Hue, shape: DccsStimulus.Shape) -> void:
	var half := DccsConst.PEN_SIZE * k / 2.0
	var rect := Rect2(center - half, half * 2.0)
	var pressed := _drawn_pressed == side
	var fill_alpha := DccsConst.PEN_FILL_PRESSED if pressed else (DccsConst.PEN_FILL_HOVER if _drawn_hover == side else DccsConst.PEN_FILL)
	draw_rect(rect, Color(DccsConst.COLOR_FENCE_DARK, fill_alpha))
	draw_rect(rect, DccsConst.COLOR_FENCE, false, 14.0 * k)
	for i in 5:
		var x := rect.position.x + rect.size.x * i / 4.0
		draw_line(Vector2(x, rect.position.y - 14.0 * k), Vector2(x, rect.position.y + 30.0 * k), DccsConst.COLOR_FENCE, 14.0 * k)
	var card_k := k * DccsConst.PEN_TARGET_SCALE
	var depth := DccsConst.BUTTON_DEPTH * k
	var card_center := center
	if pressed:
		card_center += Vector2(0, depth)
	else:
		# The raised button's side, so it looks pushable.
		var card_half := DccsConst.CARD_SIZE * card_k / 2.0
		draw_rect(Rect2(center - Vector2(card_half, card_half) + Vector2(0, depth), Vector2(card_half, card_half) * 2.0), DccsConst.COLOR_BUTTON_SIDE)
	_draw_card(card_center, card_k, hue, shape)


func _draw_card(center: Vector2, k: float, hue: DccsStimulus.Hue, shape: DccsStimulus.Shape) -> void:
	var half := DccsConst.CARD_SIZE * k / 2.0
	var rect := Rect2(center - Vector2(half, half), Vector2(half, half) * 2.0)
	draw_rect(rect, DccsConst.COLOR_CARD)
	draw_rect(rect, DccsConst.COLOR_CARD_EDGE, false, 6.0 * k)
	var color := DccsConst.COLOR_BLUE if hue == DccsStimulus.Hue.BLUE else DccsConst.COLOR_ORANGE
	if shape == DccsStimulus.Shape.STAR:
		draw_colored_polygon(_star_points(center, half * 0.78), color)
	else:
		draw_circle(center, half * 0.62, color)


# Colour rule: a disc split into the two colours. Shape rule: outlines of both shapes.
func _draw_cue(center: Vector2, k: float) -> void:
	var radius := DccsConst.CARD_SIZE * k * 0.5
	if _rule == DccsStimulus.Rule.COLOR:
		draw_colored_polygon(_half_disc(center, radius, true), DccsConst.COLOR_BLUE)
		draw_colored_polygon(_half_disc(center, radius, false), DccsConst.COLOR_ORANGE)
	else:
		var gap := radius * 1.05
		var star := _star_points(center + Vector2(-gap, 0), radius)
		star.append(star[0])
		draw_polyline(star, DccsConst.COLOR_CUE_LINE, 8.0 * k, true)
		draw_arc(center + Vector2(gap, 0), radius * 0.78, 0.0, TAU, 48, DccsConst.COLOR_CUE_LINE, 8.0 * k, true)


func _star_points(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := DccsConst.STAR_POINTS * 2
	for i in count:
		var r := radius if i % 2 == 0 else radius * DccsConst.STAR_INNER_RATIO
		var angle := -PI / 2.0 + TAU * i / count
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	return points


func _half_disc(center: Vector2, radius: float, left: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := 24
	var start := PI / 2.0 if left else -PI / 2.0
	for i in steps + 1:
		var angle := start + PI * i / steps
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points
