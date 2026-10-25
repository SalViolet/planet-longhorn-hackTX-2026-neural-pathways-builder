class_name GoNoGoStimulus
extends Control
## The fixation cross, the friendly calf (go) and the snake (no-go), drawn in
## code. Nothing here animates: the picture only changes when the task says so.

enum Kind { NONE, FIXATION, COW, SNAKE }

var _kind: Kind = Kind.NONE


func show_fixation() -> void:
	_set_kind(Kind.FIXATION)


func show_calf() -> void:
	_set_kind(Kind.COW)


func show_snake() -> void:
	_set_kind(Kind.SNAKE)


func clear() -> void:
	_set_kind(Kind.NONE)


func _set_kind(kind: Kind) -> void:
	_kind = kind
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var k := size.y / GoNoGoConst.SCREEN_UNIT_HEIGHT
	match _kind:
		Kind.FIXATION:
			var arm := GoNoGoConst.FIXATION_ARM * k
			draw_line(center + Vector2(-arm, 0), center + Vector2(arm, 0), GoNoGoConst.COLOR_FIXATION, GoNoGoConst.FIXATION_WIDTH * k)
			draw_line(center + Vector2(0, -arm), center + Vector2(0, arm), GoNoGoConst.COLOR_FIXATION, GoNoGoConst.FIXATION_WIDTH * k)
		Kind.COW:
			_draw_calf(center, k)
		Kind.SNAKE:
			_draw_snake(center, k)


# A young longhorn, drawn with the same shapes as the elders. Coordinates are in character units
# around the center (negative y is up); the calf stands on a ground point below the center.
func _draw_calf(center: Vector2, k: float) -> void:
	var calf_k := k * GoNoGoConst.CALF_SCALE
	var feet := center + Vector2(0, GoNoGoConst.CALF_FEET_OFFSET * k)
	LonghornArt.draw(self, feet, calf_k, LonghornArt.look(StoryConst.COLOR_CALF_HIDE), true, false)


func _draw_snake(origin: Vector2, k: float) -> void:
	var o := origin + Vector2(GoNoGoConst.SNAKE_CENTER_SHIFT * k, 0.0)
	var points := PackedVector2Array()
	var steps := GoNoGoConst.SNAKE_STEPS
	for i in steps + 1:
		var x := lerpf(-GoNoGoConst.SNAKE_HALF_LENGTH, GoNoGoConst.SNAKE_HALF_LENGTH, float(i) / steps)
		points.append(o + Vector2(x, sin(x / GoNoGoConst.SNAKE_WAVE_PERIOD) * GoNoGoConst.SNAKE_WAVE_HEIGHT) * k)
	draw_polyline(points, GoNoGoConst.COLOR_SNAKE_BODY, GoNoGoConst.SNAKE_BODY_WIDTH * k, true)
	draw_polyline(points, GoNoGoConst.COLOR_SNAKE_PATTERN, GoNoGoConst.SNAKE_PATTERN_WIDTH * k, true)
	var head := points[points.size() - 1]
	draw_circle(head, 40.0 * k, GoNoGoConst.COLOR_SNAKE_BODY)
	# Forked tongue.
	draw_line(head + Vector2(36, 8) * k, head + Vector2(80, 8) * k, GoNoGoConst.COLOR_SNAKE_ANGER, 5.0 * k)
	draw_line(head + Vector2(80, 8) * k, head + Vector2(98, -4) * k, GoNoGoConst.COLOR_SNAKE_ANGER, 4.0 * k)
	draw_line(head + Vector2(80, 8) * k, head + Vector2(98, 20) * k, GoNoGoConst.COLOR_SNAKE_ANGER, 4.0 * k)
	# Angry eyes: yellow with slanted brows.
	for side in [-1.0, 1.0]:
		var s: float = side
		var eye := head + Vector2(10 * s + 4, -12) * k
		draw_circle(eye, 11.0 * k, GoNoGoConst.COLOR_SNAKE_EYE)
		draw_circle(eye + Vector2(2, 1) * k, 5.0 * k, GoNoGoConst.COLOR_EYE)
		draw_line(eye + Vector2(-12 * s, -18) * k, eye + Vector2(10 * s, -8) * k, GoNoGoConst.COLOR_SNAKE_ANGER, 5.0 * k)
