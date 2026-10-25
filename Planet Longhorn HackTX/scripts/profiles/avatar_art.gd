class_name AvatarArt
extends RefCounted
## Round avatar portraits for the profile screens, drawn in code (placeholder art). Index
## picks one of ProfileConst.AVATARS: kids in space suits and young longhorns.


## Draws avatar `index` as a circle of `radius` around `center`.
static func draw(canvas: CanvasItem, center: Vector2, radius: float, index: int) -> void:
	var count := ProfileConst.AVATARS.size()
	var spec: Dictionary = ProfileConst.AVATARS[clampi(index, 0, count - 1)]
	canvas.draw_circle(center, radius, (spec["suit"] as Color).darkened(ProfileConst.AVATAR_BACKGROUND_DARKEN))
	if spec["kind"] == "calf":
		_draw_calf(canvas, center, radius, spec)
	else:
		_draw_kid(canvas, center, radius, spec)


static func _draw_calf(canvas: CanvasItem, center: Vector2, r: float, spec: Dictionary) -> void:
	var k := ProfileConst.AVATAR_CALF_SCALE * r
	LonghornArt.draw(canvas, center + Vector2(0, r * 0.82), k, LonghornArt.look(spec["suit"]), true, false)


static func _draw_kid(canvas: CanvasItem, c: Vector2, r: float, spec: Dictionary) -> void:
	var suit: Color = spec["suit"]
	var skin: Color = spec["skin"]
	var hair: Color = spec["hair"]
	var dark := StoryConst.COLOR_EYE_DARK
	# Shoulders, then the collar.
	canvas.draw_colored_polygon(_ellipse(c + Vector2(0, r * 0.66), r * 0.62, r * 0.3), suit)
	canvas.draw_arc(c + Vector2(0, r * 0.4), r * 0.2, 0.2, PI - 0.2, 12, StoryConst.COLOR_KID_GLOVE, r * 0.07)
	# Hair behind the head, by style.
	var head := c + Vector2(0, -r * 0.1)
	match String(spec["style"]):
		"puffs":
			for side in [-1.0, 1.0]:
				canvas.draw_circle(head + Vector2(r * 0.34 * side, -r * 0.34), r * 0.19, hair)
			canvas.draw_circle(head + Vector2(0, -r * 0.1), r * 0.42, hair)
		"spiky":
			canvas.draw_circle(head + Vector2(0, -r * 0.08), r * 0.42, hair)
			for i in 5:
				var x := lerpf(-0.34, 0.34, i / 4.0)
				canvas.draw_colored_polygon(PackedVector2Array([
					head + Vector2((x - 0.1) * r, -r * 0.3), head + Vector2((x + 0.1) * r, -r * 0.3),
					head + Vector2(x * 1.25 * r, -r * 0.62)]), hair)
		_:
			canvas.draw_circle(head + Vector2(0, -r * 0.1), r * 0.44, hair)
	canvas.draw_circle(head + Vector2(0, r * 0.03), r * 0.38, skin)
	if String(spec["style"]) == "bangs":
		for dx in [-0.24, -0.08, 0.08, 0.24]:
			canvas.draw_circle(head + Vector2(dx * r, -r * 0.3), r * 0.14, hair)
	if spec["goggles"]:
		canvas.draw_line(head + Vector2(-r * 0.42, -r * 0.42), head + Vector2(r * 0.42, -r * 0.42), StoryConst.COLOR_KID_GOGGLE_STRAP, r * 0.05)
		for side in [-1.0, 1.0]:
			canvas.draw_circle(head + Vector2(r * 0.16 * side, -r * 0.44), r * 0.11, StoryConst.COLOR_KID_GOGGLE_STRAP)
			canvas.draw_circle(head + Vector2(r * 0.16 * side, -r * 0.44), r * 0.075, StoryConst.COLOR_KID_GOGGLE_LENS)
	# Face.
	for side in [-1.0, 1.0]:
		canvas.draw_circle(head + Vector2(r * 0.14 * side, -r * 0.02), r * 0.055, dark)
		canvas.draw_circle(head + Vector2(r * 0.14 * side - r * 0.015, -r * 0.035), r * 0.018, Color.WHITE)
		canvas.draw_circle(head + Vector2(r * 0.25 * side, r * 0.1), r * 0.06, StoryConst.COLOR_KID_CHEEK)
	canvas.draw_arc(head + Vector2(0, r * 0.1), r * 0.12, 0.3, PI - 0.3, 10, dark, r * 0.035)


static func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		points.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return points
