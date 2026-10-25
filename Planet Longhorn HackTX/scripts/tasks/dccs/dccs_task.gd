extends TaskModule
## DCCS (sorting day). Each trial is: cue, then the gift until the player sorts it (or the
## timeout), then a blank ITI. Timed with Time.get_ticks_usec() in _process (no tweens or timers).
## The player sorts into the left or right pen by tapping a half of the screen or with the
## left/right arrow keys. Taps during the cue are ignored for scoring but counted in the log.

enum State { IDLE, WAITING, LEAD_IN, TRIAL, DONE }

@onready var _view: DccsView = %View
@onready var _overlay: Control = %Overlay
@onready var _overlay_dimmer: ColorRect = %OverlayDimmer
@onready var _overlay_box: PanelContainer = %OverlayBox
@onready var _overlay_heading: Label = %OverlayHeading
@onready var _overlay_body: Label = %OverlayBody
@onready var _start: Button = %StartButton
@onready var _results_panel: Control = %ResultsPanel
@onready var _results_dimmer: ColorRect = %ResultsDimmer
@onready var _results_box: PanelContainer = %ResultsBox
@onready var _summary: Label = %SummaryLabel
var _points_offer: PointsOffer
@onready var _play_again: Button = %PlayAgainButton
@onready var _continue: Button = %ContinueButton

var _params: Dictionary = {}
var _session: DccsSession
var _state: State = State.IDLE
var _trial: Dictionary = {}
var _phase: DccsClock.Phase = DccsClock.Phase.CUE
var _trial_start_us := 0
var _stim_onset_us := 0
var _lead_in_start_us := 0
var _responded := false
var _response_side := -1
var _response_elapsed_ms := -1.0
var _rt_ms := -1
var _early_taps := 0
var _announced_block := ""
var _last_results: Dictionary = {}
var _progress: ProgressBar
var _waiting_for_focus := false


func _ready() -> void:
	theme = ThemeBuilder.get_theme()
	_add_skip_ui()
	_add_mistake_cue()
	for dimmer: ColorRect in [_overlay_dimmer, _results_dimmer]:
		dimmer.color = UIConst.COLOR_DIMMER
	_overlay_box.custom_minimum_size.x = DccsConst.OVERLAY_TEXT_MIN_WIDTH
	_results_box.custom_minimum_size.x = DccsConst.RESULTS_TEXT_MIN_WIDTH
	for button: Button in [_start, _play_again, _continue]:
		button.custom_minimum_size = UIConst.BUTTON_MIN_SIZE
	_start.pressed.connect(_on_start_pressed)
	_play_again.pressed.connect(func() -> void: start(AdaptiveEngine.params_for(DccsConst.MISSION_ID)))
	_continue.pressed.connect(func() -> void: StoryFlow.after_task(DccsConst.MISSION_ID, _last_results))
	finished.connect(_show_results)
	_view.pen_pressed.connect(_on_pen_pressed)
	_progress = _add_progress_bar()
	_points_offer = _add_points_offer()
	set_process(false)
	start(AdaptiveEngine.params_for(DccsConst.MISSION_ID))


func get_task_name() -> String:
	return DccsConst.TASK_NAME


func can_skip() -> bool:
	return _state != State.DONE


func get_mission_id() -> String:
	return DccsConst.MISSION_ID


func start(params: Dictionary) -> void:
	_params = DccsConst.DEFAULT_PARAMS.duplicate()
	_params.merge(params, true)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_session = DccsSession.new(_params, rng)
	logger = TrialLogger.new()
	logger.begin(get_task_name())
	_announced_block = ""
	_waiting_for_focus = false
	_progress.value = 0.0
	_results_panel.hide()
	_set_skip_button_visible(true)
	set_process(true)
	_begin_trial()


func _process(_delta: float) -> void:
	match _state:
		State.LEAD_IN:
			if _elapsed_ms(_lead_in_start_us) >= DccsConst.LEAD_IN_MS:
				_begin_trial()
		State.TRIAL:
			_update_trial()


func _input(event: InputEvent) -> void:
	if _state != State.TRIAL:
		return
	if _is_skip_button_click(event):
		return
	var side := -1
	if event.is_action_pressed("ui_left") and not event.is_echo():
		side = DccsStimulus.Pen.LEFT
	elif event.is_action_pressed("ui_right") and not event.is_echo():
		side = DccsStimulus.Pen.RIGHT
	if side >= 0:
		get_viewport().set_input_as_handled()
		_view.press_visual(side)
		_register_response(side)


## A pen button was pressed with the mouse or a finger (the view already showed it sinking).
func _on_pen_pressed(side: int) -> void:
	if _state == State.TRIAL:
		_register_response(side)


func abort_current_trial(reason: String) -> void:
	if _state != State.TRIAL:
		return
	logger.log_trial(_trial["number"], _trial_params(), _stimulus_info(), {"pen": DccsStimulus.side_name(_response_side)},
			false, _rt_ms, false, reason)
	_session.record(-1, -1, false)
	_begin_lead_in()


func on_focus_gained() -> void:
	if _waiting_for_focus:
		_waiting_for_focus = false
		_begin_lead_in()


func _show_overlay(heading: String, body: String, button_text: String) -> void:
	_state = State.WAITING
	_view.clear_trial()
	_overlay_heading.text = heading
	_overlay_body.text = body
	_start.text = button_text
	_overlay.show()
	_start.grab_focus()


func _on_start_pressed() -> void:
	_overlay.hide()
	_begin_lead_in()


func _begin_lead_in() -> void:
	_state = State.LEAD_IN
	_view.clear_trial()
	_lead_in_start_us = Time.get_ticks_usec()


func _begin_trial() -> void:
	_progress.value = float(_session.completed_trials()) / _session.total_trials()
	if not _session.has_next():
		_complete()
		return
	var block := _session.next_block_start()
	if block != "" and block != _announced_block:
		_announced_block = block
		_show_overlay(DccsConst.HEADING_TEXT, DccsConst.BLOCK_TEXT[block],
				DccsConst.START_TEXT if block == "pre" else DccsConst.CONTINUE_TEXT)
		return
	if not can_run_trials():
		_waiting_for_focus = true # Resumes in on_focus_gained().
		_state = State.IDLE
		return
	_trial = _session.next_trial()
	_responded = false
	_response_side = -1
	_response_elapsed_ms = -1.0
	_rt_ms = -1
	_early_taps = 0
	_stim_onset_us = 0
	_phase = DccsClock.Phase.CUE
	_state = State.TRIAL
	_trial_start_us = Time.get_ticks_usec()
	_view.show_cue(_trial["rule"])


func _update_trial() -> void:
	var phase := DccsClock.phase_at(_elapsed_ms(_trial_start_us), int(_params["cue_ms"]),
			int(_params["response_timeout_ms"]), int(_params["iti_ms"]), _response_elapsed_ms)
	if phase == _phase:
		return
	_phase = phase
	if phase == DccsClock.Phase.STIMULUS:
		_stim_onset_us = Time.get_ticks_usec()
		_view.show_stimulus(_trial["rule"], _trial["hue"], _trial["shape"])
	elif phase == DccsClock.Phase.ITI:
		_view.clear_trial()
	if phase != DccsClock.Phase.STIMULUS and _stim_onset_us == 0:
		# A long frame skipped the stimulus; count RT from when it should have appeared.
		_stim_onset_us = _trial_start_us + int(_params["cue_ms"]) * TaskConst.USEC_PER_MS
	if phase == DccsClock.Phase.DONE:
		_finish_trial()


func _register_response(side: int) -> void:
	var now := Time.get_ticks_usec()
	if _phase == DccsClock.Phase.CUE:
		_early_taps += 1
	elif _phase == DccsClock.Phase.STIMULUS and not _responded:
		_responded = true
		_response_side = side
		_rt_ms = TaskConst.us_to_ms(now - _stim_onset_us)
		_response_elapsed_ms = _elapsed_ms(_trial_start_us)
		if side == _trial["correct_side"]:
			_mistake_cue.play_correct(TaskConst.TEXT_RIGHT)
		else:
			_mistake_cue.play(true, TaskConst.TEXT_TRY_AGAIN)


func _finish_trial() -> void:
	var result := _session.record(_response_side, _rt_ms)
	if not _responded:
		_mistake_cue.play_too_slow() # No answer in time.
	logger.log_trial(_trial["number"], _trial_params(), _stimulus_info(), {"pen": DccsStimulus.side_name(_response_side)},
			result["correct"], _rt_ms, true)
	_begin_trial()


func _trial_params() -> Dictionary:
	return {
		"block": _trial["block"],
		"rule": "color" if _trial["rule"] == DccsStimulus.Rule.COLOR else "shape",
		"switch": _trial["switch"],
		"conflict": _trial["conflict"],
		"cue_ms": _params["cue_ms"],
		"response_timeout_ms": _params["response_timeout_ms"],
		"iti_ms": _params["iti_ms"],
		"early_taps": _early_taps,
	}


func _stimulus_info() -> Dictionary:
	return {
		"hue": "blue" if _trial["hue"] == DccsStimulus.Hue.BLUE else "orange",
		"shape": "star" if _trial["shape"] == DccsStimulus.Shape.STAR else "round",
		"correct_pen": DccsStimulus.side_name(_trial["correct_side"]),
	}


func _complete() -> void:
	_state = State.DONE
	set_process(false)
	_view.clear_trial()
	var results := _session.get_results()
	results["difficulty_level"] = int(_params.get("difficulty_level", -1))
	_progress.value = 1.0
	_finish(results)


func _elapsed_ms(since_us: int) -> float:
	return float(Time.get_ticks_usec() - since_us) / TaskConst.USEC_PER_MS


func _show_results(results: Dictionary) -> void:
	_last_results = results
	_set_skip_button_visible(false)
	var lines: Array[String] = [
		"Accuracy: %d%%" % roundi(float(results["accuracy"]) * 100.0),
		"Color block: %s" % _block_line(results, "pre"),
		"Shape block: %s" % _block_line(results, "post"),
		"Mixed block: %s" % _block_line(results, "mixed"),
		"Switch cost: %s" % _cost_line(results["switch_cost_rt_ms"]),
		"Mixing cost: %s" % _cost_line(results["mixing_cost_rt_ms"]),
		"Stuck-on-old-rule errors: %d" % results["perseverative_errors"],
	]
	_append_level_line(lines, results)
	_summary.text = "\n".join(lines)
	_points_offer.show_award(last_award)
	_results_panel.show()
	_play_again.grab_focus()


func _block_line(results: Dictionary, block: String) -> String:
	var speed := "n/a"
	if results[block + "_rt_ms"] > 0.0:
		speed = "%d ms" % roundi(results[block + "_rt_ms"])
	return "%d%% correct, %s" % [roundi(float(results[block + "_accuracy"]) * 100.0), speed]


func _cost_line(cost_ms: float) -> String:
	return "%+d ms" % roundi(cost_ms) if cost_ms != 0.0 else "n/a"
