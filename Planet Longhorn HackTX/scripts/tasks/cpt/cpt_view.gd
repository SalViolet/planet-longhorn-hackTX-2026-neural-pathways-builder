class_name CptView
extends Control
## The quiet night stream and the night-watch shapes, drawn in code. The scenery is static; only
## the shape appears and disappears, plus the flashlight beam when the player shines it. Every
## shape, the thief included, is one colour and one size, so nothing pops out but its outline.
## Shape coordinates are scaled by screen height / 1080.

var _glyph := -1
var _beam_until_us := 0
var _drawn_beam := false


func show_glyph(glyph_id: int) -> void:
	_glyph = glyph_id
	queue_redraw()


func clear() -> void:
	_glyph = -1
	queue_redraw()


## The flashlight beam, shown briefly after the player pushes the button (a response, not a cue).
func shine() -> void:
	_beam_until_us = Time.get_ticks_usec() + CptConst.BEAM_MS * TaskConst.USEC_PER_MS
	queue_redraw()


func _process(_delta: float) -> void:
	if (Time.get_ticks_usec() < _beam_until_us) != _drawn_beam:
		queue_redraw()


func _draw() -> void:
	var k := size.y / CptConst.SCREEN_UNIT_HEIGHT
	_draw_stream(k)
	var center := size / 2.0
	draw_circle(center, CptConst.FIXATION_RADIUS * k, CptConst.COLOR_FIXATION)
	_drawn_beam = Time.get_ticks_usec() < _beam_until_us
	if _drawn_beam:
		_draw_beam(center, k)
	if _glyph >= 0:
		_draw_glyph(_glyph, center, CptConst.GLYPH_RADIUS * k)


# A soft cone of light from the flashlight button up to the middle of the screen.
func _draw_beam(center: Vector2, k: float) -> void:
	var origin := Vector2(size.x / 2.0, size.y - CptConst.BEAM_ORIGIN_FROM_BOTTOM * k)
	var spread := CptConst.GLYPH_RADIUS * k * CptConst.BEAM_SPREAD
	var beam := PackedVector2Array([
		origin + Vector2(-CptConst.BEAM_BASE * k, 0), origin + Vector2(CptConst.BEAM_BASE * k, 0),
		center + Vector2(spread, 0), center + Vector2(-spread, 0)])
	draw_colored_polygon(beam, CptConst.COLOR_BEAM)
	draw_colored_polygon(_half_disc(center, spread), CptConst.COLOR_BEAM) # The lit pool above the cone.


func _draw_stream(k: float) -> void:
	for line in CptConst.STREAM_LINES:
		var y := size.y * (CptConst.STREAM_TOP + line * CptConst.STREAM_SPACING)
		var points := PackedVector2Array()
		for i in CptConst.STREAM_STEPS + 1:
			var x := size.x * i / CptConst.STREAM_STEPS
			var phase := x / (CptConst.STREAM_WAVE_PERIOD * k) + line * 1.7
			points.append(Vector2(x, y + sin(phase) * CptConst.STREAM_WAVE_HEIGHT * k))
		draw_polyline(points, CptConst.COLOR_STREAM, CptConst.STREAM_LINE_WIDTH * k, true)


# Eight different-looking cows and one cow in a ski mask (the thief). Same colour and size
# throughout, so the thief is found by its outline, not by a colour that pops out.
const COWS: Array[Dictionary] = [
	{"horn": "long", "ears": "round"}, # 0: long horns, plain.
	{"horn": "short", "ears": "floppy", "spots": [[0.3, -0.12, 0.2]]}, # 1: patch over one eye.
	{"horn": "none", "ears": "floppy", "tuft": true}, # 2: no horns, big floppy ears.
	{"horn": "curl", "ears": "round", "spots": [[0.0, -0.4, 0.14]]}, # 3: curly horns.
	{"horn": "up", "ears": "round", "head_w": 0.8, "spots": [[-0.2, -0.3, 0.1], [0.22, -0.18, 0.1]]}, # 4: narrow face.
	{"horn": "tiny", "ears": "round", "head_w": 1.18, "spots": [[-0.35, -0.2, 0.16], [0.4, 0.0, 0.14], [0.0, -0.45, 0.12]]}, # 5: chubby.
	{"horn": "long", "ears": "round", "fringe": true}, # 6: bangs.
	{"horn": "tiny", "ears": "round", "tuft": true, "head_w": 0.88, "eye_scale": 1.6}, # 7: calf.
]


func _draw_glyph(id: int, c: Vector2, r: float) -> void:
	if id >= 0 and id < COWS.size():
		_draw_cow(c, r, COWS[id], false)
	else:
		_draw_cow(c, r, {"horn": "long", "ears": "round"}, true)


func _draw_cow(c: Vector2, r: float, spec: Dictionary, masked: bool) -> void:
	var color := CptConst.COLOR_GLYPH
	var hole := CptConst.COLOR_EYE_HOLE
	var head_w: float = spec.get("head_w", 1.0)
	var center := c + Vector2(0, r * 0.12)
	var rx := r * 0.58 * head_w
	var ry := r * 0.64
	# Horns first, so the head sits on top of their roots.
	for side in [-1.0, 1.0]:
		var s: float = side
		var root := center + Vector2(rx * 0.7 * s, -ry * 0.6)
		match String(spec.get("horn", "long")):
			"long":
				draw_polyline(PackedVector2Array([root, root + Vector2(r * 0.4 * s, -r * 0.05), root + Vector2(r * 0.55 * s, -r * 0.3), root + Vector2(r * 0.52 * s, -r * 0.55)]), color, r * 0.15, true)
			"short":
				draw_polyline(PackedVector2Array([root, root + Vector2(r * 0.25 * s, -r * 0.05), root + Vector2(r * 0.3 * s, -r * 0.25)]), color, r * 0.15, true)
			"tiny":
				draw_polyline(PackedVector2Array([root, root + Vector2(r * 0.12 * s, -r * 0.18)]), color, r * 0.14, true)
			"up":
				draw_polyline(PackedVector2Array([root, root + Vector2(r * 0.2 * s, -r * 0.45), root + Vector2(r * 0.18 * s, -r * 0.7)]), color, r * 0.13, true)
			"curl":
				var curl := PackedVector2Array()
				for i in 13:
					var a := lerpf(PI * 0.9, -PI * 0.7, i / 12.0)
					var spiral := r * lerpf(0.34, 0.14, i / 12.0)
					curl.append(root + Vector2(r * 0.34 * s, -r * 0.1) + Vector2(cos(a) * s, -sin(a)) * spiral)
				draw_polyline(curl, color, r * 0.12, true)
	# Ears, then the head.
	for side in [-1.0, 1.0]:
		var s: float = side
		if String(spec.get("ears", "round")) == "floppy":
			draw_colored_polygon(_ellipse(center + Vector2((rx + r * 0.12) * s, r * 0.12), r * 0.15, r * 0.32), color)
		else:
			draw_circle(center + Vector2((rx + r * 0.1) * s, -r * 0.02), r * 0.2, color)
	draw_colored_polygon(_ellipse(center, rx, ry), color)
	if spec.get("tuft", false):
		for dx in [-0.12, 0.0, 0.12]:
			draw_line(center + Vector2(r * dx, -ry), center + Vector2(r * dx * 1.8, -ry - r * 0.22), color, r * 0.07)
	if spec.get("fringe", false):
		for i in 5:
			var fx := lerpf(-0.8, 0.8, i / 4.0)
			draw_line(center + Vector2(rx * fx, -ry * 0.95), center + Vector2(rx * fx * 0.9, -ry * 0.45), hole, r * 0.05)
	for spot: Array in spec.get("spots", []):
		draw_circle(center + Vector2(rx * float(spot[0]), ry * float(spot[1])), r * float(spot[2]), hole)
	if masked:
		_draw_ski_mask(center, rx, ry, r, color, hole)
		return
	# Face: eyes, and a dark muzzle with nostrils.
	var eye_r := r * 0.07 * float(spec.get("eye_scale", 1.0))
	for side in [-1.0, 1.0]:
		draw_circle(center + Vector2(rx * 0.42 * side, -ry * 0.2), eye_r, hole)
	draw_colored_polygon(_ellipse(center + Vector2(0, ry * 0.5), rx * 0.62, ry * 0.3), hole)
	for side in [-1.0, 1.0]:
		draw_circle(center + Vector2(rx * 0.2 * side, ry * 0.5), r * 0.045, color)


# A dark knitted mask over the whole face with angry eye slits, a grin slit and a pom-pom.
func _draw_ski_mask(center: Vector2, rx: float, ry: float, r: float, color: Color, hole: Color) -> void:
	draw_colored_polygon(_ellipse(center, rx * 0.86, ry * 0.88), hole)
	draw_line(center + Vector2(0, -ry * 0.9), center + Vector2(0, -ry * 1.1), color, r * 0.06) # Pom-pom stem.
	draw_circle(center + Vector2(0, -ry * 1.18), r * 0.14, color)
	for side in [-1.0, 1.0]:
		var s: float = side
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(rx * 0.12 * s, -ry * 0.2), center + Vector2(rx * 0.6 * s, -ry * 0.42),
			center + Vector2(rx * 0.56 * s, -ry * 0.1)]), color)
	var grin := PackedVector2Array()
	for i in 7:
		grin.append(center + Vector2(lerpf(-rx * 0.4, rx * 0.4, i / 6.0), ry * 0.45 + (ry * 0.12 if i % 2 == 0 else 0.0)))
	draw_polyline(grin, color, r * 0.05, true)


func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		points.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return points


func _half_disc(c: Vector2, r: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		points.append(c + Vector2(cos(a), sin(a)) * r)
	return points
