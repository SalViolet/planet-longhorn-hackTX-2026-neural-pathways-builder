extends CanvasLayer
## Autoload "SceneTransition": fades to black, swaps the scene, fades back in.

const TOP_LAYER := 100

var _rect: ColorRect
var _tween: Tween
var _changing := false # A change is under way and the old scene is still showing.


func _ready() -> void:
	layer = TOP_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = UIConst.COLOR_FADE
	add_child(_rect)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.modulate.a = 1.0 # Start black so the first screen fades in.
	await get_tree().process_frame
	await _fade_to(0.0, UIConst.FADE_IN_SECONDS)


## True while the old scene is still fading out. Callers use this to ignore double presses.
func is_changing() -> bool:
	return _changing


func change_scene(path: String) -> void:
	# Repeated requests while the old scene is fading out are ignored. A request
	# during the previous scene's fade-in is accepted and cuts that fade short.
	if _changing:
		return
	_changing = true
	await _fade_to(1.0, UIConst.FADE_OUT_SECONDS)
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Could not load scene %s (error %d)" % [path, err])
	# change_scene_to_file is deferred; wait until the new scene is in the tree.
	await get_tree().process_frame
	await get_tree().process_frame
	_changing = false
	await _fade_to(0.0, UIConst.FADE_IN_SECONDS)


func _fade_to(alpha: float, seconds: float) -> void:
	# While (partly) opaque, swallow mouse/touch so nothing can be clicked mid-fade.
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_rect, "modulate:a", alpha, seconds)
	await _tween.finished
	if alpha <= 0.0:
		_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
