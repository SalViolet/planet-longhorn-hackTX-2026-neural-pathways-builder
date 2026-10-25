class_name SpaceBackground
extends Control
## Procedural deep-space backdrop drawn with _draw(): gradient, drifting
## nebula blobs and parallax star layers. No image assets.

## Set false during trials: no drifting or twinkling, so nothing on screen moves.
@export var animated: bool = true

var _stars: Array[PackedVector2Array] = [] # Normalized (0-1) so resizing is free.
var _nebula_texture: GradientTexture2D
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(animated)
	_nebula_texture = _make_nebula_texture()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for layer: Dictionary in UIConst.STAR_LAYERS:
		var points := PackedVector2Array()
		for i in int(layer["count"]):
			points.append(Vector2(rng.randf(), rng.randf()))
		_stars.append(points)


func _process(delta: float) -> void:
	_time += delta
	if size.x <= 0.0:
		return
	for i in UIConst.STAR_LAYERS.size():
		var layer: Dictionary = UIConst.STAR_LAYERS[i]
		var step := float(layer["speed"]) * delta / size.x
		var points := _stars[i]
		for j in points.size():
			points[j].x = fposmod(points[j].x - step, 1.0)
		_stars[i] = points
	queue_redraw()


func _draw() -> void:
	var top := UIConst.COLOR_SPACE_TOP
	var bottom := UIConst.COLOR_SPACE_BOTTOM
	draw_polygon(
			PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0.0), size, Vector2(0.0, size.y)]),
			PackedColorArray([top, top, bottom, bottom]))

	for blob: Dictionary in UIConst.NEBULA_BLOBS:
		var phase := _time * UIConst.NEBULA_DRIFT_SPEED + float(blob["phase"])
		var wobble := Vector2(sin(phase), cos(phase * 0.8)) * UIConst.NEBULA_DRIFT_AMOUNT
		var center: Vector2 = ((blob["center"] as Vector2) + wobble) * size
		var radius := float(blob["radius"]) * size.x
		draw_texture_rect(_nebula_texture,
				Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0),
				false, blob["color"] as Color)

	for i in UIConst.STAR_LAYERS.size():
		var layer: Dictionary = UIConst.STAR_LAYERS[i]
		var star_size := float(layer["size"])
		for p in _stars[i]:
			# Phase from position gives each star its own twinkle without per-star state.
			var twinkle := 0.6 + 0.4 * sin(_time * UIConst.STAR_TWINKLE_SPEED + p.x * 90.0 + p.y * 47.0)
			var color := UIConst.COLOR_STAR
			color.a = float(layer["alpha"]) * twinkle
			draw_rect(Rect2(p * size, Vector2(star_size, star_size)), color)


# White radial falloff; tinted per blob via draw_texture_rect's modulate.
func _make_nebula_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = UIConst.NEBULA_TEXTURE_SIZE
	tex.height = UIConst.NEBULA_TEXTURE_SIZE
	return tex
