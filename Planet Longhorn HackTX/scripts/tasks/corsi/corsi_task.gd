extends TaskModule
## Corsi block-tapping. Phases are driven by Time.get_ticks_usec() in _process,
## not tweens or timers, so trial timing doesn't depend on animation.

enum Phase { IDLE, PRE_TRIAL, PRESENT, RESPOND, INTER_TRIAL, DONE }

@onready var _status: Label = %StatusLabel
@onready var _board: Control = %Board
@onready var _results_panel: Control = %ResultsPanel
@onready var _results_dimmer: ColorRect = %ResultsDimmer
@onready var _results_box: PanelContainer = %ResultsBox
@onready var _summary: Label = %SummaryLabel
var _points_offer: PointsOffer
@onready var _play_again: Button = %PlayAgainButton
@onready var _continue: Button = %ContinueButton

var _params: Dictionary = {}
var _session: CorsiSession
var _phase: Phase = Phase.IDLE
var _phase_start_us := 0
var _blocks: Array[CorsiBlock] = []
var _sequence: Array[int] = []
var _response: Array[int] = []
var _tap_ms: Array[int] = [] # Time of each tap since the response phase began.
var _lit_block := -1
var _last_results: Dictionary = {}
var _drum: AudioStreamPlayer
var _progress: ProgressBar
var _waiting_for_focus := false


func _ready() -> void:
	theme = ThemeBuilder.get_theme()
	_add_skip_ui()
	_results_dimmer.color = UIConst.COLOR_DIMMER
	_results_box.custom_minimum_size.x = CorsiConst.RESULTS_TEXT_MIN_WIDTH
	_play_again.custom_minimum_size = UIConst.BUTTON_MIN_SIZE
	_continue.custom_minimum_size = UIConst.BUTTON_MIN_SIZE
	_play_again.pressed.connect(func() -> void: start(AdaptiveEngine.params_for(CorsiConst.MISSION_ID)))
	_continue.pressed.connect(func() -> void: StoryFlow.after_task(CorsiConst.MISSION_ID, _last_results))
	finished.connect(_show_results)
	_progress = _add_progress_bar()
	_points_offer = _add_points_offer()
	_add_mistake_cue()
	_build_drum()
	_build_board()
	set_process(false)
	start(AdaptiveEngine.params_for(CorsiConst.MISSION_ID))


func get_task_name() -> String:
	return CorsiConst.TASK_NAME


func can_skip() -> bool:
	return _phase != Phase.DONE


func get_mission_id() -> String:
	return CorsiConst.MISSION_ID


func start(params: Dictionary) -> void:
	_params = CorsiConst.DEFAULT_PARAMS.duplicate()
	_params.merge(params, true)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_session = CorsiSession.new(
			clampi(int(_params["start_span"]), 1, CorsiConst.MAX_SPAN),
			CorsiConst.MAX_SPAN, CorsiConst.TRIALS_PER_SPAN, _blocks.size(), rng)
	logger = TrialLogger.new()
	logger.begin(get_task_name())
	_results_panel.hide()
	_set_skip_button_visible(true)
	_waiting_for_focus = false
	set_process(true)
	_next_trial()


func _process(_delta: float) -> void:
	var elapsed_ms := float(Time.get_ticks_usec() - _phase_start_us) / TaskConst.USEC_PER_MS
	match _phase:
		Phase.PRE_TRIAL:
			if elapsed_ms >= CorsiConst.PRE_TRIAL_MS:
				_enter(Phase.PRESENT)
		Phase.PRESENT:
			_update_presentation(elapsed_ms)
		Phase.INTER_TRIAL:
			if elapsed_ms >= CorsiConst.INTER_TRIAL_MS:
				_next_trial()


func abort_current_trial(reason: String) -> void:
	if _phase != Phase.PRE_TRIAL and _phase != Phase.PRESENT and _phase != Phase.RESPOND:
		return
	logger.log_trial(
			_session.current_trial_number(), _trial_params(), _sequence,
			{"taps": _response, "tap_ms": _tap_ms},
			false, _tap_ms[0] if not _tap_ms.is_empty() else -1, false, reason)
	_session.abort_trial()
	_set_lit_block(-1)
	_set_blocks_enabled(false)
	_status.text = CorsiConst.STATUS_NONE
	_enter(Phase.INTER_TRIAL)


func _trial_params() -> Dictionary:
	return {
		"span": _session.current_span(),
		"item_duration_ms": _params["item_duration_ms"],
		"gap_ms": _params["gap_ms"],
	}


func _build_drum() -> void:
	_drum = AudioStreamPlayer.new()
	_drum.stream = DrumSound.make_stream()
	_drum.max_polyphony = CorsiConst.DRUM_POLYPHONY
	add_child(_drum)


func _build_board() -> void:
	_board.offset_left = -CorsiConst.BOARD_SIZE.x / 2.0
	_board.offset_right = CorsiConst.BOARD_SIZE.x / 2.0
	_board.offset_top = -CorsiConst.BOARD_SIZE.y / 2.0
	_board.offset_bottom = CorsiConst.BOARD_SIZE.y / 2.0
	var block_size := Vector2.ONE * CorsiConst.BLOCK_SIZE
	for i in CorsiConst.BLOCK_POSITIONS.size():
		var block := CorsiBlock.new()
		block.block_index = i
		block.size = block_size
		block.position = CorsiConst.BOARD_SIZE / 2.0 + CorsiConst.BLOCK_POSITIONS[i] - block_size / 2.0
		block.tapped.connect(_on_block_tapped)
		_board.add_child(block)
		_blocks.append(block)


func _enter(phase: Phase) -> void:
	_phase = phase
	_phase_start_us = Time.get_ticks_usec()


func _next_trial() -> void:
	_progress.value = _progress_fraction()
	if _session.is_finished():
		_complete()
		return
	if not can_run_trials():
		_waiting_for_focus = true # Resumes in on_focus_gained().
		_phase = Phase.IDLE
		return
	_sequence = _session.next_sequence()
	_response.clear()
	_tap_ms.clear()
	_set_blocks_enabled(false)
	_set_lit_block(-1)
	_status.text = CorsiConst.STATUS_WATCH
	_enter(Phase.PRE_TRIAL)


# Item i is lit for item_duration_ms, then dark for gap_ms. Taps are ignored throughout.
func _update_presentation(elapsed_ms: float) -> void:
	var item_ms := float(_params["item_duration_ms"])
	var slot_ms := maxf(item_ms + float(_params["gap_ms"]), 1.0)
	var item := int(elapsed_ms / slot_ms)
	if item >= _sequence.size():
		_set_lit_block(-1)
		_begin_response()
		return
	_set_lit_block(_sequence[item] if fmod(elapsed_ms, slot_ms) < item_ms else -1)


## Switches between pointer and keyboard/gamepad mode as soon as the player changes input type.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventScreenTouch:
		if not CorsiBlock.pointer_mode:
			CorsiBlock.pointer_mode = true
			get_viewport().gui_release_focus() # The pointer now picks the stone, not the focus ring.
		return
	if not _is_navigation_event(event) or not CorsiBlock.pointer_mode:
		return
	CorsiBlock.pointer_mode = false
	if _phase == Phase.RESPOND and get_viewport().gui_get_focus_owner() == null:
		_focus_block_under_pointer_or_default()
		get_viewport().set_input_as_handled() # This first key press only shows the ring.


func _is_navigation_event(event: InputEvent) -> bool:
	if not event.is_pressed() or event.is_echo():
		return false
	for action: StringName in [&"ui_accept", &"ui_up", &"ui_down", &"ui_left", &"ui_right"]:
		if event.is_action_pressed(action):
			return true
	return false


func _focus_block_under_pointer_or_default() -> void:
	var target := CorsiConst.INITIAL_FOCUS_BLOCK
	for i in _blocks.size():
		if _blocks[i].has_point_under_pointer():
			target = i
	_blocks[target].grab_focus()


func _begin_response() -> void:
	_enter(Phase.RESPOND)
	_status.text = CorsiConst.STATUS_REPEAT
	_set_blocks_enabled(true)
	if not CorsiBlock.pointer_mode:
		_blocks[CorsiConst.INITIAL_FOCUS_BLOCK].grab_focus()


func _on_block_tapped(block_index: int) -> void:
	if _phase != Phase.RESPOND:
		return
	_tap_ms.append(TaskConst.us_to_ms(Time.get_ticks_usec() - _phase_start_us))
	_response.append(block_index)
	var expected := _sequence[_response.size() - 1]
	if block_index == expected:
		_blocks[block_index].flash(CorsiConst.TAP_HIGHLIGHT_MS, false, true)
		_mistake_cue.play_correct(TaskConst.TEXT_RIGHT)
	else:
		_blocks[block_index].flash(CorsiConst.TAP_HIGHLIGHT_MS, true)
		_mistake_cue.play(false, TaskConst.TEXT_TRY_AGAIN) # Silent: every stone shares one tone.
	_drum.play()
	if _response.size() >= _sequence.size():
		_finish_trial()


func _finish_trial() -> void:
	var trial_number := _session.current_trial_number()
	var trial_params := _trial_params() # Read before submit_response moves the span on.
	var correct := _session.submit_response(_response)
	logger.log_trial(
			trial_number,
			trial_params,
			_sequence,
			{"taps": _response, "tap_ms": _tap_ms},
			correct,
			_tap_ms[0],
			true)
	_set_blocks_enabled(false)
	_status.text = CorsiConst.STATUS_NONE
	_enter(Phase.INTER_TRIAL)


func on_focus_gained() -> void:
	if _waiting_for_focus:
		_waiting_for_focus = false
		_next_trial()


func _progress_fraction() -> float:
	return _session.progress(int(_params["start_span"]))


func _complete() -> void:
	_enter(Phase.DONE)
	set_process(false)
	_status.text = CorsiConst.STATUS_NONE
	var results := _session.get_results()
	results["difficulty_level"] = int(_params.get("difficulty_level", -1))
	_progress.value = 1.0
	_finish(results)


func _set_blocks_enabled(on: bool) -> void:
	for block in _blocks:
		block.set_enabled(on)


func _set_lit_block(index: int) -> void:
	if index == _lit_block:
		return
	if _lit_block >= 0:
		_blocks[_lit_block].set_lit(false)
	_lit_block = index
	if index >= 0:
		_blocks[index].set_lit(true)
		_drum.play()


func _show_results(results: Dictionary) -> void:
	_last_results = results
	_set_skip_button_visible(false)
	var per_trial := PackedStringArray()
	for accuracy: float in results["trial_accuracy"]:
		per_trial.append("%d%%" % roundi(accuracy * 100.0))
	var lines: Array[String] = [
		"Max span: %d" % results["max_span"],
		"Correct trials: %d of %d" % [results["correct_trials"], results["total_trials"]],
		"Corsi score: %d" % results["corsi_score"],
		"Accuracy: %d%%" % roundi(float(results["mean_accuracy"]) * 100.0),
		"Per trial: %s" % "  ".join(per_trial),
	]
	_append_level_line(lines, results)
	_summary.text = "\n".join(lines)
	_points_offer.show_award(last_award)
	_results_panel.show()
	_play_again.grab_focus()


func _go_to_hub() -> void:
	SceneTransition.change_scene(UIConst.SCENE_HUB)
