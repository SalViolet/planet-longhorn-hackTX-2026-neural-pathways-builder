class_name LonghornArt
extends RefCounted
## Draws a longhorn in code so the elders (story scenes) and the calves (Go/No-Go) share one
## face and one set of shapes. Coordinates are character units, origin at the feet, negative y up.
## Elders have long horns and a tall body; calves are smaller with a big head and short horns.


## Colors for one longhorn from its hide color. `dim` darkens it (characters not speaking).
static func look(base: Color, dim: float = 1.0) -> Dictionary:
	return {
		"hide": dim_color(base, dim),
		"light": dim_color(base.lightened(0.3), dim),
		"dark": dim_color(base.darkened(0.3), dim),
		"horn": dim_color(StoryConst.COLOR_HORN, dim),
		"white": dim_color(StoryConst.COLOR_EYE_WHITE, dim),
		"pupil": dim_color(StoryConst.COLOR_EYE_DARK, dim),
	}


static func dim_color(color: Color, factor: float) -> Color:
	return Color(color.r * factor, color.g * factor, color.b * factor, color.a)


## Draws the body, horns, head and face. Returns the head center so callers can add a beard,
## a headband or a mouth relative to it.
static func draw(canvas: CanvasItem, o: Vector2, k: float, look_colors: Dictionary,
		young: bool, blink: bool) -> Vector2:
	var hide: Color = look_colors["hide"]
	var light: Color = look_colors["light"]
	var dark: Color = look_colors["dark"]
	var horn: Color = look_colors["horn"]
	var white: Color = look_colors["white"]
	var pupil: Color = look_colors["pupil"]
	var body_k := k * (StoryConst.CALF_BODY_SCALE if young else 1.0)
	var head := Vector2(0, StoryConst.CALF_HEAD_Y if young else StoryConst.ELDER_HEAD_Y)
	var head_r := StoryConst.CALF_HEAD_RADIUS if young else StoryConst.ELDER_HEAD_RADIUS
	var muzzle_r := StoryConst.CALF_MUZZLE_RADIUS if young else StoryConst.ELDER_MUZZLE_RADIUS
	var eye_r := StoryConst.CALF_EYE_RADIUS if young else StoryConst.ELDER_EYE_RADIUS
	var horn_len := StoryConst.CALF_HORN_SCALE if young else 1.0
	var h := o + head * k
	for side in [-1.0, 1.0]:
		var s: float = side
		canvas.draw_circle(o + Vector2(45 * s, -20) * body_k, 32.0 * body_k, dark) # Feet.
		canvas.draw_circle(o + Vector2(98 * s, -125) * body_k, 30.0 * body_k, hide) # Hands.
		var base := head + Vector2(52 * s, -30)
		var horn_points := _bezier(o + base * k,
				o + (base + Vector2(163 * s, 7) * horn_len) * k,
				o + (base + Vector2(138 * s, -113) * horn_len) * k)
		canvas.draw_polyline(horn_points, horn, (14.0 if young else 20.0) * k, true)
		canvas.draw_circle(o + (head + Vector2(88 * s, 0)) * k, 24.0 * k, dark) # Ears.
	canvas.draw_circle(o + Vector2(0, -125) * body_k, 105.0 * body_k, hide)
	canvas.draw_circle(o + Vector2(0, -105) * body_k, 62.0 * body_k, light)
	canvas.draw_circle(h, head_r * k, hide)
	canvas.draw_circle(o + (head + Vector2(0, 30)) * k, muzzle_r * k, light)
	for side in [-1.0, 1.0]:
		var s: float = side
		canvas.draw_circle(o + (head + Vector2(15 * s, 34)) * k, 5.0 * k, dark)
		var eye := o + (head + Vector2(30 * s, -23)) * k
		if blink:
			canvas.draw_line(eye + Vector2(-12, 0) * k, eye + Vector2(12, 0) * k, pupil, 4.0 * k)
		else:
			canvas.draw_circle(eye, eye_r * k, white)
			canvas.draw_circle(eye + Vector2(3, 1) * k, eye_r * 0.5 * k, pupil)
	if young: # A little tuft of hair on top.
		var tuft: Color = look_colors["dark"]
		for dx in [-12.0, 0.0, 12.0]:
			canvas.draw_line(h + Vector2(dx, -head_r + 6) * k, h + Vector2(dx * 1.6, -head_r - 18) * k, tuft, 6.0 * k)
	return h


static func _bezier(p0: Vector2, p1: Vector2, p2: Vector2, steps: int = 14) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / steps
		points.append(p0.lerp(p1, t).lerp(p1.lerp(p2, t), t))
	return points
