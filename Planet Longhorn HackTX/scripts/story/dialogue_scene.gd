class_name DialogueScene
extends Control
## Plays one story beat: stage art, a speaker name and typed-out text with effects.
## Tap / click / Enter / gamepad A finishes the typing, then moves to the next line.
## Lines may carry an effect (screen shake, drum ripple) or a choice with flavor replies.

@onready var _stage: StoryStage = %Stage
@onready var _box: PanelContainer = %Box
@onready var _name: Label = %SpeakerName
@onready var _text: RichTextLabel = %LineText
@onready var _choices: VBoxContainer = %Choices
@onready var _buttons: HBoxContainer = %Buttons
@onready var _marker: ContinueMarker = %Marker
@onready var _continue: Button = %ContinueButton
@onready var _skip: Button = %SkipButton

var _lines: Array[Dictionary] = []
var _index := -1
var _tween: Tween
var _typing := false
var _stage_id := "ship" # Kept until a line names a new stage.
var _ended := false
var _speaker_id := "narrator"
var _pending_choice: Dictionary = {}
var _total_chars := 0
var _blips_played := 0
var _voice: AudioStreamPlayer
var _effect_sound: AudioStreamPlayer


func _ready() -> void:
	theme = ThemeBuilder.get_theme()
	# Opened straight from the editor (F6): play the first beat so it can be previewed.
	if StoryFlow.pending_beat == "" and OS.has_feature("editor"):
		StoryFlow.pending_beat = "arrival"
	var beat := StoryFlow.pending_beat
	_lines = StoryData.lines_for(beat, StoryFlow.pending_results)

	_name.add_theme_font_size_override("font_size", StoryConst.NAME_FONT_SIZE)
	_text.add_theme_font_size_override("normal_font_size", StoryConst.TEXT_FONT_SIZE)
	_text.add_theme_color_override("default_color", UIConst.COLOR_TEXT)
	_text.custom_minimum_size.y = StoryConst.TEXT_MIN_HEIGHT
	_box.get_child(0).add_theme_constant_override("separation", StoryConst.BOX_SEPARATION)
	_marker.custom_minimum_size = StoryConst.MARKER_SIZE
	_continue.text = StoryConst.CONTINUE_TEXT
	_skip.text = StoryConst.SKIP_TEXT
	for button: Button in [_continue, _skip]:
		button.custom_minimum_size = StoryConst.BUTTON_MIN_SIZE
	_continue.pressed.connect(_advance)
	_skip.pressed.connect(_end)
	_stage.gui_input.connect(_on_tap)
	_box.gui_input.connect(_on_tap)
	_voice = _make_player()
	_effect_sound = _make_player()
	_effect_sound.stream = DrumSound.make_stream()

	if _lines.is_empty():
		push_error("No story lines for beat '%s'" % beat)
		_ended = true
		SceneTransition.change_scene.call_deferred(UIConst.SCENE_HUB)
		return
	_continue.grab_focus()
	_show_line(0)


func _process(_delta: float) -> void:
	# One little typing sound every few letters, in the speaker's own pitch.
	if not _typing or _total_chars == 0:
		return
	var shown := int(_text.visible_ratio * _total_chars)
	while (_blips_played + 1) * StoryConst.BLIP_EVERY_CHARS <= shown:
		_blips_played += 1
		_blip()


func _make_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	add_child(player)
	return player


func _blip() -> void:
	var stream := DialogueBlips.stream_for(float(StoryData.SPEAKERS[_speaker_id].get("voice_hz", 0.0)))
	if stream == null:
		return
	_voice.stream = stream
	_voice.pitch_scale = 1.0 + randf_range(-StoryConst.BLIP_PITCH_JITTER, StoryConst.BLIP_PITCH_JITTER)
	_voice.play()


func _show_line(index: int) -> void:
	_index = index
	var line := _lines[index]
	if line.has("stage") or line.has("actors"):
		var actors: Array[String] = []
		actors.assign(line.get("actors", []))
		_stage_id = String(line.get("stage", _stage_id))
		_stage.set_stage(_stage_id, actors)
	_speaker_id = String(line["speaker"])
	var spec: Dictionary = StoryData.SPEAKERS[_speaker_id]
	_stage.set_speaker(_speaker_id)
	_name.text = String(spec["name"])
	_name.visible = _name.text != ""
	_name.add_theme_color_override("font_color", spec["color"])
	_choices.hide()
	_buttons.show()
	_pending_choice = line.get("choice", {})
	_text.text = String(_pending_choice["prompt"]) if line.has("choice") else String(line["text"])
	_total_chars = maxi(_text.get_total_character_count(), 1)
	_text.visible_ratio = 0.0
	_blips_played = 0
	_typing = true
	_marker.hide()
	_stage.set_talking(_speaker_id != "narrator")
	_play_effect(String(line.get("effect", "")))
	_pop_box()
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_text, "visible_ratio", 1.0, _total_chars / StoryConst.TYPEWRITER_CHARS_PER_SECOND)
	_tween.finished.connect(_finish_typing)


func _finish_typing() -> void:
	_typing = false
	_text.visible_ratio = 1.0
	_stage.set_talking(false)
	if _pending_choice.is_empty():
		_marker.show()
	else:
		_show_choices()


func _show_choices() -> void:
	_buttons.hide()
	for child in _choices.get_children():
		child.queue_free()
	var options: Array = _pending_choice["options"]
	var first: Button = null
	for i in options.size():
		var option: Dictionary = options[i]
		var button := Button.new()
		button.text = String(option["label"])
		button.custom_minimum_size = StoryConst.CHOICE_BUTTON_MIN_SIZE
		button.pressed.connect(_choose.bind(i))
		_choices.add_child(button)
		first = first if first != null else button
	_choices.show()
	first.grab_focus.call_deferred()


# The reply lines play next, then the story carries on as written.
func _choose(option_index: int) -> void:
	if _ended or _pending_choice.is_empty():
		return
	var option: Dictionary = (_pending_choice["options"] as Array)[option_index]
	var replies: Array = option["reply"]
	for k in replies.size():
		_lines.insert(_index + 1 + k, replies[k])
	_pending_choice = {}
	_choices.hide()
	_continue.grab_focus()
	_show_line(_index + 1)


func _advance() -> void:
	if _ended:
		return
	if _typing:
		_tween.kill()
		_finish_typing()
	elif not _pending_choice.is_empty():
		return # Waiting for the player to pick an option.
	elif _index + 1 < _lines.size():
		_show_line(_index + 1)
	else:
		_end()


func _end() -> void:
	if _ended:
		return
	_ended = true
	StoryFlow.finish_beat()


func _play_effect(effect_name: String) -> void:
	if effect_name == "":
		return
	_stage.play_effect(effect_name)
	if effect_name == "drums":
		_effect_sound.play()


# The box pops in a little each time a new line starts.
func _pop_box() -> void:
	_box.pivot_offset = _box.size / 2.0
	_box.scale = Vector2.ONE * StoryConst.BOX_POP_START_SCALE
	create_tween().tween_property(_box, "scale", Vector2.ONE, StoryConst.BOX_POP_SECONDS)


func _on_tap(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			_advance()
