class_name ContinueMarker
extends Control
## A small bobbing arrow: "there is more, press Continue".

var _time := 0.0


func _process(delta: float) -> void:
	if visible:
		_time += delta
		queue_redraw()


func _draw() -> void:
	var bob := sin(_time * StoryConst.MARKER_BOB_SPEED) * StoryConst.MARKER_BOB_PIXELS
	var c := size / 2.0 + Vector2(0.0, bob)
	var w := size.x * 0.4
	var h := size.y * 0.3
	draw_colored_polygon(PackedVector2Array([c + Vector2(-w, -h), c + Vector2(w, -h), c + Vector2(0.0, h)]), StoryConst.COLOR_MARKER)
