class_name CorsiBlock
extends Control
## One drum stone. Drawn in code; lit by the task (sequence) or by a tap flash.

signal tapped(block_index: int)

## True while the player is using mouse, trackpad or touch: the ring follows the pointer.
## False while using keyboard or gamepad: the ring marks the focused stone.
## Shared by all stones and kept between runs; the task flips it when the input type changes.
static var pointer_mode := true

var block_index: int = 0

var _enabled := false
var _lit := false
var _flash_until_us := 0
var _flash_is_mistake := false
var _flash_is_correct := false
var _drawn_lit := false
var _hovered := false
var _drawn_ring := false


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _process(_delta: float) -> void:
	# The flash expires by clock time, so redraw when the lit state flips.
	if _is_lit() != _drawn_lit:
		queue_redraw()
	_hovered = _enabled and pointer_mode and is_visible_in_tree() \
			and _has_point(get_local_mouse_position())
	if _wants_ring() != _drawn_ring:
		queue_redraw()


## Disabled blocks ignore taps and cannot take focus.
func set_enabled(on: bool) -> void:
	_enabled = on
	focus_mode = Control.FOCUS_ALL if on else Control.FOCUS_NONE
	if not on and has_focus():
		release_focus()
	queue_redraw()


func set_lit(on: bool) -> void:
	_lit = on
	queue_redraw()


func flash(duration_ms: int, mistake: bool = false, correct: bool = false) -> void:
	_flash_is_mistake = mistake
	_flash_is_correct = correct
	_flash_until_us = Time.get_ticks_usec() + duration_ms * TaskConst.USEC_PER_MS
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not _enabled:
		return
	var pressed := false
	if event is InputEventMouseButton: # Touch is emulated as mouse input.
		var mouse := event as InputEventMouseButton
		pressed = mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	elif event.is_action_pressed("ui_accept") and not event.is_echo():
		pressed = true
	if pressed:
		accept_event()
		tapped.emit(block_index)


func has_point_under_pointer() -> bool:
	return _has_point(get_local_mouse_position())


func _wants_ring() -> bool:
	if not _enabled:
		return false
	return _hovered if pointer_mode else has_focus()


func _is_lit() -> bool:
	return _lit or Time.get_ticks_usec() < _flash_until_us


# Round stones: only the circle counts as the tap area.
func _has_point(point: Vector2) -> bool:
	return point.distance_to(size / 2.0) <= size.x / 2.0


func _draw() -> void:
	_drawn_lit = _is_lit()
	_drawn_ring = _wants_ring()
	var center := size / 2.0
	var radius := size.x / 2.0
	if _drawn_lit:
		for layer in range(CorsiConst.GLOW_LAYERS, 0, -1):
			draw_circle(center, radius * (1.0 + layer * CorsiConst.GLOW_STEP), CorsiConst.COLOR_STONE_GLOW)
	draw_circle(center, radius, CorsiConst.COLOR_STONE_RIM)
	var face := CorsiConst.COLOR_STONE_FACE
	if _drawn_lit:
		face = CorsiConst.COLOR_STONE_FACE_LIT
		if not _lit and _flash_is_mistake:
			face = TaskConst.COLOR_MISTAKE
		elif not _lit and _flash_is_correct:
			face = TaskConst.COLOR_CORRECT
	draw_circle(center, radius * CorsiConst.STONE_FACE_RATIO, face)
	# Inner ring suggests a drum skin; the arc on the upper left is a soft highlight.
	draw_arc(center, radius * CorsiConst.STONE_RING_RATIO, 0.0, TAU, CorsiConst.ARC_SEGMENTS,
			CorsiConst.COLOR_STONE_RING, CorsiConst.EDGE_WIDTH)
	draw_arc(center, radius * CorsiConst.STONE_HIGHLIGHT_RATIO, PI * 0.9, PI * 1.5,
			CorsiConst.ARC_SEGMENTS, CorsiConst.COLOR_STONE_HIGHLIGHT, CorsiConst.EDGE_WIDTH * 2.0)
	draw_arc(center, radius, 0.0, TAU, CorsiConst.ARC_SEGMENTS,
			CorsiConst.COLOR_STONE_EDGE_LIT if _drawn_lit else CorsiConst.COLOR_STONE_EDGE,
			CorsiConst.EDGE_WIDTH)
	if _drawn_ring:
		draw_arc(center, radius * CorsiConst.FOCUS_RING_SCALE, 0.0, TAU, CorsiConst.ARC_SEGMENTS,
				UIConst.COLOR_FOCUS, CorsiConst.FOCUS_RING_WIDTH)
