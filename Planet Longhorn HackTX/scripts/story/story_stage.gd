class_name StoryStage
extends Control
## Placeholder story art drawn in code: a ship interior, the outdoor planet, and
## the kid and longhorn elders. Shape coordinates below are in "character units"
## (the character is about 400 tall) scaled by CHARACTER_SCALE and screen height.

var _stage_id := ""
var _actors: Array[String] = []
var _speaker := ""
var _time := 0.0
var _talking := false
var _enter_start := -10.0
var _shake_until := 0.0
var _pulse_start := -10.0
var _pulse_points: Array[Vector2] = [] # Where drum pulses ripple from, filled in while drawing.


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func set_stage(stage_id: String, actors: Array[String]) -> void:
	if actors != _actors or stage_id != _stage_id:
		_enter_start = _time # New faces slide in.
	_stage_id = stage_id
	_actors = actors


func set_speaker(speaker_id: String) -> void:
	_speaker = speaker_id


## While true, the speaker's mouth flaps.
func set_talking(on: bool) -> void:
	_talking = on


## "shake" rattles the whole scene; "drums" sends a ripple out from the drum stones.
func play_effect(effect_name: String) -> void:
	if effect_name == "shake":
		_shake_until = _time + StoryConst.SHAKE_SECONDS
	elif effect_name == "drums":
		_pulse_start = _time


func _draw() -> void:
	var unit := size.y / 1080.0
	var shaking := _time < _shake_until
	if shaking:
		var amount := StoryConst.SHAKE_PIXELS * unit * (_shake_until - _time) / StoryConst.SHAKE_SECONDS
		draw_set_transform(Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * amount)
	_pulse_points.clear()
	match _stage_id:
		"outside":
			_draw_outside(unit)
		"pens":
			_draw_outside(unit)
			_draw_pens(unit)
		"night":
			_draw_night(unit)
		_:
			_draw_ship(unit)
	_draw_pulse(unit)
	_draw_actors(unit)
	if shaking:
		draw_set_transform(Vector2.ZERO)


# --- Scenery ---

func _draw_ship(unit: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), StoryConst.COLOR_WALL)
	var x := 0.0
	while x < size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, size.y * StoryConst.HORIZON_LINE), StoryConst.COLOR_WALL_SEAM, 4.0 * unit)
		x += StoryConst.SEAM_SPACING * unit
	draw_rect(Rect2(0.0, size.y * StoryConst.HORIZON_LINE, size.x, size.y), StoryConst.COLOR_FLOOR)

	# Porthole with a red planet outside.
	var porthole := Vector2(size.x * 0.78, size.y * 0.28)
	draw_circle(porthole, 170.0 * unit, StoryConst.COLOR_METAL)
	draw_circle(porthole, 150.0 * unit, StoryConst.COLOR_PORTHOLE_SKY)
	draw_circle(porthole + Vector2(40, 30) * unit, 70.0 * unit, StoryConst.COLOR_PLANET_RED)
	for star in [Vector2(-80, -60), Vector2(-30, -100), Vector2(-100, 40), Vector2(60, -90)]:
		draw_circle(porthole + (star as Vector2) * unit, 4.0 * unit, UIConst.COLOR_STAR)

	# Round hatch, and the door panel that mirrors the drum stones.
	var hatch := Vector2(size.x * 0.12, size.y * 0.33)
	draw_circle(hatch, 215.0 * unit, StoryConst.COLOR_METAL)
	draw_circle(hatch, 190.0 * unit, StoryConst.COLOR_HATCH)
	for i in 3:
		draw_circle(hatch + Vector2(-50 + i * 50, -120) * unit, 10.0 * unit, StoryConst.COLOR_HATCH_LIGHT)
	var panel := Rect2(hatch + Vector2(240, -80) * unit, Vector2(220, 130) * unit)
	draw_rect(panel, StoryConst.COLOR_METAL)
	draw_rect(panel.grow(-8.0 * unit), UIConst.COLOR_PANEL_FILL)
	_pulse_points.append(panel.get_center())
	var lit_dot := int(_time * 2.0) % CorsiConst.BLOCK_POSITIONS.size()
	for i in CorsiConst.BLOCK_POSITIONS.size():
		var dot_color := StoryConst.COLOR_PANEL_DOT_ON if i == lit_dot else StoryConst.COLOR_PANEL_DOT_OFF
		draw_circle(panel.get_center() + CorsiConst.BLOCK_POSITIONS[i] * 0.07 * unit, 7.0 * unit, dot_color)


func _draw_outside(unit: float) -> void:
	var horizon := size.y * StoryConst.HORIZON_LINE
	draw_polygon(
			PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0.0), Vector2(size.x, horizon), Vector2(0.0, horizon)]),
			PackedColorArray([UIConst.COLOR_SPACE_TOP, UIConst.COLOR_SPACE_TOP,
					StoryConst.COLOR_SKY_HORIZON, StoryConst.COLOR_SKY_HORIZON]))
	for i in StoryConst.STAR_COUNT:
		# Cheap deterministic hash so the stars don't move between frames.
		var sx := fposmod(sin(i * 12.9898) * 43758.5453, 1.0)
		var sy := fposmod(sin(i * 78.233) * 12345.6789, 1.0)
		draw_circle(Vector2(sx * size.x, sy * horizon * 0.8), (2.0 + i % 3) * unit, UIConst.COLOR_STAR)
	draw_circle(Vector2(size.x * 0.78, size.y * 0.3), 210.0 * unit, StoryConst.COLOR_PLANET_RED)
	draw_circle(Vector2(size.x * 0.14, size.y * 0.2), 110.0 * unit, StoryConst.COLOR_PLANET_GREEN)

	# Ground, with a few rocks and the drum stones along the back.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, horizon), Vector2(size.x * 0.3, horizon - 14.0 * unit),
		Vector2(size.x * 0.62, horizon), Vector2(size.x, horizon - 18.0 * unit),
		Vector2(size.x, size.y), Vector2(0, size.y)]), StoryConst.COLOR_GROUND)
	draw_rect(Rect2(0.0, horizon + 28.0 * unit, size.x, 20.0 * unit), StoryConst.COLOR_GROUND_LIGHT)
	_draw_rock(Vector2(size.x * 0.06, horizon), 150.0 * unit, StoryConst.COLOR_ROCK)
	_draw_rock(Vector2(size.x * 0.14, horizon), 110.0 * unit, StoryConst.COLOR_ROCK_ICE)
	_draw_rock(Vector2(size.x * 0.9, horizon), 130.0 * unit, StoryConst.COLOR_ROCK_ICE)
	for i in 7:
		var stone := Vector2(size.x * (0.1 + i * 0.13), horizon + (60.0 + (i % 2) * 26.0) * unit)
		_pulse_points.append(stone)
		draw_circle(stone, 34.0 * unit, CorsiConst.COLOR_STONE_RIM)
		draw_circle(stone, 26.0 * unit, CorsiConst.COLOR_STONE_FACE)
		draw_arc(stone, 17.0 * unit, 0.0, TAU, 24, CorsiConst.COLOR_STONE_RING, 3.0 * unit)


func _draw_pens(unit: float) -> void:
	var ground := size.y * StoryConst.HORIZON_LINE
	for x in [0.1, 0.9]:
		var rect := Rect2(Vector2(size.x * x - StoryConst.PEN_WIDTH * unit / 2.0, ground + 10.0 * unit),
				Vector2(StoryConst.PEN_WIDTH, StoryConst.PEN_HEIGHT) * unit)
		draw_rect(rect, StoryConst.COLOR_FENCE, false, 10.0 * unit)
		for i in 4:
			var post_x := rect.position.x + rect.size.x * i / 3.0
			draw_line(Vector2(post_x, rect.position.y - 10.0 * unit), Vector2(post_x, rect.position.y + 24.0 * unit), StoryConst.COLOR_FENCE, 10.0 * unit)


func _draw_night(unit: float) -> void:
	var horizon := size.y * StoryConst.HORIZON_LINE
	draw_polygon(
			PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0.0), Vector2(size.x, horizon), Vector2(0.0, horizon)]),
			PackedColorArray([StoryConst.COLOR_NIGHT_TOP, StoryConst.COLOR_NIGHT_TOP,
					StoryConst.COLOR_NIGHT_HORIZON, StoryConst.COLOR_NIGHT_HORIZON]))
	for i in StoryConst.STAR_COUNT:
		var sx := fposmod(sin(i * 12.9898) * 43758.5453, 1.0)
		var sy := fposmod(sin(i * 78.233) * 12345.6789, 1.0)
		draw_circle(Vector2(sx * size.x, sy * horizon * 0.85), (2.0 + i % 3) * unit, UIConst.COLOR_STAR)
	_pulse_points.append(Vector2(size.x * 0.82, size.y * 0.2))
	draw_circle(Vector2(size.x * 0.82, size.y * 0.2), StoryConst.MOON_RADIUS * unit, StoryConst.COLOR_MOON)
	draw_rect(Rect2(0.0, horizon, size.x, size.y), StoryConst.COLOR_NIGHT_GROUND)
	for line in StoryConst.STREAM_LINES:
		var y := horizon + (24.0 + line * 22.0) * unit
		var points := PackedVector2Array()
		for i in 41:
			var x := size.x * i / 40.0
			points.append(Vector2(x, y + sin(x / (140.0 * unit) + line * 1.7) * 6.0 * unit))
		draw_polyline(points, StoryConst.COLOR_STREAM, 4.0 * unit, true)


# A ripple from each drum stone (or the ship's panel) when a line says "drums".
func _draw_pulse(unit: float) -> void:
	var t := (_time - _pulse_start) / StoryConst.PULSE_SECONDS
	if t < 0.0 or t >= 1.0:
		return
	var color := Color(UIConst.COLOR_ACCENT, (1.0 - t) * 0.75)
	for point in _pulse_points:
		draw_arc(point, (StoryConst.PULSE_START_RADIUS + StoryConst.PULSE_GROW * t) * unit, 0.0, TAU, 48, color, 6.0 * unit)


func _draw_rock(base: Vector2, height: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-height * 0.7, 0), base + Vector2(-height * 0.2, -height),
		base + Vector2(height * 0.25, -height * 0.7), base + Vector2(height * 0.7, 0)]), color)


# --- Characters ---

func _draw_actors(unit: float) -> void:
	var count := _actors.size()
	for i in count:
		var spec: Dictionary = StoryData.SPEAKERS.get(_actors[i], {})
		if spec.is_empty():
			continue
		var slot := 0.5 if count == 1 else lerpf(0.2, 0.8, float(i) / float(count - 1))
		if count == 2:
			slot = 0.34 + i * 0.32
		var speaking := _actors[i] == _speaker
		var origin := Vector2(size.x * slot, size.y * StoryConst.GROUND_LINE)
		var enter := 1.0 - pow(1.0 - clampf((_time - _enter_start) / StoryConst.ENTER_SECONDS, 0.0, 1.0), 3.0)
		if slot < 0.45:
			origin.x -= (1.0 - enter) * StoryConst.ENTER_DISTANCE * unit
		elif slot > 0.55:
			origin.x += (1.0 - enter) * StoryConst.ENTER_DISTANCE * unit
		else:
			origin.y += (1.0 - enter) * StoryConst.ENTER_DISTANCE * 0.5 * unit
		var blink := fposmod(_time + i * 1.37, StoryConst.BLINK_PERIOD) < StoryConst.BLINK_SECONDS
		var talking := speaking and _talking
		if speaking:
			origin.y += sin(_time * StoryConst.BOB_SPEED) * StoryConst.BOB_PIXELS * unit
		var k := unit * StoryConst.CHARACTER_SCALE
		var dim := 1.0 if speaking else StoryConst.CHARACTER_DIM
		if _actors[i] == "kid":
			_draw_player(origin, k, spec, dim, blink, talking)
		elif spec["kind"] == "kid":
			_draw_kid(origin, k, spec, dim, blink, talking)
		else:
			_draw_longhorn(origin, k, spec, dim, blink, talking)


## The player character is whichever avatar the active player picked: a kid in a space suit
## (hair, skin, suit and goggles vary) or a young longhorn.
func _draw_player(o: Vector2, k: float, spec: Dictionary, dim: float, blink: bool, talking: bool) -> void:
	var avatar := _player_avatar()
	if avatar["kind"] == "calf":
		var head := LonghornArt.draw(self, o, k, LonghornArt.look(avatar["suit"], dim), true, blink)
		if talking:
			draw_circle(head + Vector2(0, 44) * k, (5.0 + 8.0 * absf(sin(_time * StoryConst.TALK_SPEED))) * k,
					LonghornArt.dim_color(StoryConst.COLOR_EYE_DARK, dim))
		return
	var look := spec.duplicate()
	look["body"] = avatar["suit"]
	look["head"] = avatar["skin"]
	look["accent"] = avatar["hair"]
	look["style"] = avatar["style"]
	look["goggles"] = avatar["goggles"]
	_draw_kid(o, k, look, dim, blink, talking)


func _player_avatar() -> Dictionary:
	var index := int(ProfileStore.active_profile().get("color", 0))
	return ProfileConst.AVATARS[clampi(index, 0, ProfileConst.AVATARS.size() - 1)]


func _draw_kid(o: Vector2, k: float, spec: Dictionary, dim: float, blink: bool, talking: bool) -> void:
	var suit := _dim(spec["body"], dim)
	var suit_dark := _dim((spec["body"] as Color).darkened(0.3), dim)
	var skin := _dim(spec["head"], dim)
	var hair := _dim(spec["accent"], dim)
	var dark := _dim(StoryConst.COLOR_EYE_DARK, dim)
	var white := _dim(StoryConst.COLOR_EYE_WHITE, dim)
	var glove := _dim(StoryConst.COLOR_KID_GLOVE, dim)
	var boot := _dim(StoryConst.COLOR_KID_BOOT, dim)
	var strap := _dim(StoryConst.COLOR_KID_GOGGLE_STRAP, dim)
	# Backpack peeking out behind the shoulder, then legs and boots.
	_capsule(o, k, Vector2(64, -240), Vector2(64, -160), 40.0, suit_dark)
	for side in [-1.0, 1.0]:
		var s: float = side
		_capsule(o, k, Vector2(28 * s, -110), Vector2(28 * s, -30), 46.0, suit)
		_capsule(o, k, Vector2(34 * s, -14), Vector2(48 * s, -14), 40.0, boot)
	# Body, belt and chest badge.
	_capsule(o, k, Vector2(0, -225), Vector2(0, -120), 136.0, suit)
	_capsule(o, k, Vector2(-58, -128), Vector2(58, -128), 16.0, _dim(StoryConst.COLOR_KID_BELT, dim))
	draw_circle(o + Vector2(0, -128) * k, 10.0 * k, _dim(StoryConst.COLOR_KID_BUCKLE, dim))
	draw_circle(o + Vector2(-34, -168) * k, 14.0 * k, _dim(StoryConst.COLOR_KID_BADGE, dim))
	draw_circle(o + Vector2(-34, -168) * k, 7.0 * k, suit_dark)
	# Arms and gloves.
	for side in [-1.0, 1.0]:
		var s: float = side
		_capsule(o, k, Vector2(66 * s, -205), Vector2(92 * s, -138), 32.0, suit)
		draw_circle(o + Vector2(94 * s, -128) * k, 19.0 * k, glove)
	# Suit collar ring, then the head: hair behind, face, bangs.
	draw_arc(o + Vector2(0, -232) * k, 46.0 * k, 0.0, TAU, 24, glove, 12.0 * k)
	var style := String(spec.get("style", "bangs"))
	draw_circle(o + Vector2(0, -312) * k, 80.0 * k, hair)
	if style == "puffs":
		for side in [-1.0, 1.0]:
			draw_circle(o + Vector2(62 * side, -372) * k, 34.0 * k, hair)
	elif style == "spiky":
		for i in 5:
			var x := lerpf(-52.0, 52.0, i / 4.0)
			draw_colored_polygon(PackedVector2Array([
				o + Vector2(x - 20, -360) * k, o + Vector2(x + 20, -360) * k, o + Vector2(x * 1.3, -418) * k]), hair)
	for side in [-1.0, 1.0]:
		var s: float = side
		draw_circle(o + Vector2(66 * s, -285) * k, 26.0 * k, hair)
	draw_circle(o + Vector2(0, -292) * k, 70.0 * k, skin)
	if style == "round":
		draw_circle(o + Vector2(0, -352) * k, 56.0 * k, hair)
	else:
		for dx in [-42.0, -14.0, 16.0, 44.0]:
			draw_circle(o + Vector2(dx, -346 + absf(dx) * 0.25) * k, 24.0 * k, hair)
	# Goggles pushed up on the head (some avatars have them).
	if spec.get("goggles", true):
		_capsule(o, k, Vector2(-68, -372), Vector2(68, -372), 10.0, strap)
		for side in [-1.0, 1.0]:
			var s: float = side
			draw_circle(o + Vector2(28 * s, -374) * k, 20.0 * k, strap)
			draw_circle(o + Vector2(28 * s, -374) * k, 14.0 * k, _dim(StoryConst.COLOR_KID_GOGGLE_LENS, dim))
	# Face: eyes with a sparkle, eyebrows, blush, nose and mouth.
	for side in [-1.0, 1.0]:
		var s: float = side
		var eye := o + Vector2(26 * s, -296) * k
		if blink:
			draw_line(eye + Vector2(-11, 0) * k, eye + Vector2(11, 0) * k, dark, 4.0 * k)
		else:
			draw_circle(eye, 14.0 * k, white)
			draw_circle(eye + Vector2(1, 1) * k, 9.0 * k, dark)
			draw_circle(eye + Vector2(-2, -3) * k, 3.0 * k, white)
		draw_line(eye + Vector2(-12 * s, -22) * k, eye + Vector2(12 * s, -26) * k, hair, 5.0 * k)
		draw_circle(o + Vector2(46 * s, -268) * k, 12.0 * k, StoryConst.COLOR_KID_CHEEK)
	draw_circle(o + Vector2(0, -280) * k, 5.0 * k, _dim((spec["head"] as Color).darkened(0.2), dim))
	if talking:
		draw_circle(o + Vector2(0, -258) * k, (6.0 + 9.0 * absf(sin(_time * StoryConst.TALK_SPEED))) * k, dark)
	else:
		draw_arc(o + Vector2(0, -266) * k, 24.0 * k, 0.3, PI - 0.3, 12, dark, 4.5 * k)


## A rounded stick: a line with round ends, in character units.
func _capsule(o: Vector2, k: float, a: Vector2, b: Vector2, width: float, color: Color) -> void:
	draw_line(o + a * k, o + b * k, color, width * k)
	draw_circle(o + a * k, width * 0.5 * k, color)
	draw_circle(o + b * k, width * 0.5 * k, color)


func _draw_longhorn(o: Vector2, k: float, spec: Dictionary, dim: float, blink: bool, talking: bool) -> void:
	var accent := LonghornArt.dim_color(spec["accent"], dim)
	var pupil := LonghornArt.dim_color(StoryConst.COLOR_EYE_DARK, dim)
	var head := LonghornArt.draw(self, o, k, LonghornArt.look(spec["body"], dim), false, blink)
	if spec["style"] == "beard":
		draw_colored_polygon(PackedVector2Array([
			o + Vector2(-30, -205) * k, o + Vector2(30, -205) * k, o + Vector2(0, -135) * k]),
			_dim(StoryConst.COLOR_BEARD, dim))
	elif spec["style"] == "band":
		draw_line(o + Vector2(-72, -312) * k, o + Vector2(72, -312) * k, accent, 14.0 * k)
	if talking:
		draw_circle(head + Vector2(0, 52) * k, (5.0 + 8.0 * absf(sin(_time * StoryConst.TALK_SPEED))) * k, pupil)


func _dim(color: Color, factor: float) -> Color:
	return Color(color.r * factor, color.g * factor, color.b * factor, color.a)
