extends TaskModule
## Go/No-Go (herd rescue). Each trial is fixation -> stimulus -> blank ISI, timed with
## Time.get_ticks_usec() in _process (no tweens or timers). The player may respond from
## stimulus onset until the end of the ISI. Taps during fixation are ignored but counted.

enum State { IDLE, WAITING, LEAD_IN, TRIAL, DONE }

@onready var _stimulus: GoNoGoStimulus = %Stimulus
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
var _session: GoNoGoSession
var _state: State = State.IDLE
var _trial: Dictionary = {}
var _phase: GoNoGoClock.Phase = GoNoGoClock.Phase.FIXATION
var _trial_start_us := 0
var _stim_onset_us := 0
var _lead_in_start_us := 0
var _responded := false
var _rt_ms := -1
var _early_taps := 0
var _break_shown := false
var _last_results: Dictionary = {}
var _progress: ProgressBar
var _waiting_for_focus := false
var _skip_practice: Button
var _pad: ResponsePad


func _ready() -> void:
	theme = ThemeBuilder.get_theme()
	_add_skip_ui()
	_add_mistake_cue()
	for dimmer: ColorRect in [_overlay_dimmer, _results_dimmer]:
		dimmer.color = UIConst.COLOR_DIMMER
	_overlay_box.custom_minimum_size.x = GoNoGoConst.OVERLAY_TEXT_MIN_WIDTH
	_results_box.custom_minimum_size.x = GoNoGoConst.RESULTS_TEXT_MIN_WIDTH
	for button: Button in [_start, _play_again, _continue]:
		button.custom_minimum_size = UIConst.BUTTON_MIN_SIZE
	_start.pressed.connect(_on_start_pressed)
	_skip_practice = Button.new()
	_skip_practice.text = GoNoGoConst.SKIP_PRACTICE_TEXT
	_skip_practice.custom_minimum_size = UIConst.BUTTON_MIN_SIZE
	_skip_practice.size_flags_horizontal = _start.size_flags_horizontal
	_start.get_parent().add_child(_skip_practice)
	_skip_practice.pressed.connect(_on_skip_practice_pressed)
	_play_again.pressed.connect(func() -> void: start(AdaptiveEngine.params_for(GoNoGoConst.MISSION_ID)))
	_continue.pressed.connect(func() -> void: StoryFlow.after_task(GoNoGoConst.MISSION_ID, _last_results))
	_progress = _add_progress_bar()
	_pad = _add_response_pad(GoNoGoConst.PAD_TEXT, GoNoGoConst.COLOR_PAD, _stimulus)
	_pad.pressed_down.connect(_on_pad_pressed)
	_set_herd_button_enabled(false)
	_points_offer = _add_points_offer()
	finished.connect(_show_results)
	set_process(false)
	start(AdaptiveEngine.params_for(GoNoGoConst.MISSION_ID))


func get_task_name() -> String:
	return GoNoGoConst.TASK_NAME


func can_skip() -> bool:
	return _state != State.DONE


func get_mission_id() -> String:
	return GoNoGoConst.MISSION_ID


func start(params: Dictionary) -> void:
	_params = GoNoGoConst.DEFAULT_PARAMS.duplicate()
	_params.merge(params, true)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_session = GoNoGoSession.new(_params, rng)
	logger = TrialLogger.new()
	logger.begin(get_task_name())
	_break_shown = false
	_waiting_for_focus = false
	_progress.value = 0.0
	_results_panel.hide()
	_set_skip_button_visible(true)
	set_process(true)
	var start_text := GoNoGoConst.START_PRACTICE_TEXT if int(_params["practice_trials"]) > 0 \
			else GoNoGoConst.START_MAIN_TEXT
	_show_overlay(GoNoGoConst.HEADING_TEXT, GoNoGoConst.INSTRUCTIONS_TEXT, start_text)


func _process(_delta: float) -> void:
	_update_progress()
	match _state:
		State.LEAD_IN:
			if _elapsed_ms(_lead_in_start_us) >= GoNoGoConst.LEAD_IN_MS:
				_begin_trial()
		State.TRIAL:
			_update_trial()


func _update_progress() -> void:
	var total := maxi(_session.total_trials(), 1)
	var done := _session.completed_trials()
	var partial := 0.0
	if _state == State.TRIAL and not _trial.is_empty():
		var elapsed := _elapsed_ms(_trial_start_us)
		var duration := float(_params["fixation_ms"] + _params["stimulus_ms"] + int(_trial["isi_ms"]))
		partial = clampf(elapsed / maxf(duration, 1.0), 0.0, 1.0)
		done -= 1 # The session counts a trial as soon as it starts.
	_progress.value = clampf((float(done) + partial) / float(total), 0.0, 1.0)


func _input(event: InputEvent) -> void:
	if _state != State.TRIAL:
		return
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		get_viewport().set_input_as_handled() # Space, Enter or gamepad A.
		_pad.press_visual()
		_register_response()


## The big button was pushed with the mouse or a finger (it already showed itself sinking).
func _on_pad_pressed() -> void:
	if _state == State.TRIAL and _phase != GoNoGoClock.Phase.FIXATION:
		_register_response()


func abort_current_trial(reason: String) -> void:
	if _state != State.TRIAL:
		return
	logger.log_trial(_trial["number"], _trial_params(), _stimulus_info(), {"responded": _responded},
			false, _rt_ms, false, reason)
	_session.record(false, -1, false)
	_begin_lead_in()


func on_focus_gained() -> void:
	if _waiting_for_focus:
		_waiting_for_focus = false
		_begin_lead_in()


func _show_overlay(heading: String, body: String, button_text: String) -> void:
	_state = State.WAITING
	_stimulus.clear()
	_overlay_heading.text = heading
	_overlay_body.text = body
	_start.text = button_text
	_skip_practice.visible = button_text == GoNoGoConst.START_PRACTICE_TEXT
	_overlay.show()
	_start.grab_focus()


## Jumps past the practice trials straight to the real ones (no break screen).
func _on_skip_practice_pressed() -> void:
	_session.skip_practice()
	_break_shown = true
	_on_start_pressed()


func _on_start_pressed() -> void:
	_overlay.hide()
	_begin_lead_in()


func _begin_lead_in() -> void:
	_set_herd_button_enabled(false)
	_state = State.LEAD_IN
	_stimulus.clear()
	_lead_in_start_us = Time.get_ticks_usec()


func _begin_trial() -> void:
	_set_herd_button_enabled(false)
	_progress.value = float(_session.completed_trials()) / _session.total_trials()
	if not _session.has_next():
		_complete()
		return
	if _session.next_is_first_main_trial() and not _break_shown:
		_break_shown = true
		_show_overlay(GoNoGoConst.BREAK_HEADING_TEXT, GoNoGoConst.BREAK_TEXT, GoNoGoConst.START_MAIN_TEXT)
		return
	if not can_run_trials():
		_waiting_for_focus = true # Resumes in on_focus_gained().
		_state = State.IDLE
		return
	_trial = _session.next_trial()
	_responded = false
	_rt_ms = -1
	_early_taps = 0
	_stim_onset_us = 0
	_phase = GoNoGoClock.Phase.FIXATION
	_state = State.TRIAL
	_trial_start_us = Time.get_ticks_usec()
	_stimulus.show_fixation()


func _update_trial() -> void:
	var phase := GoNoGoClock.phase_at(_elapsed_ms(_trial_start_us), int(_params["fixation_ms"]),
			int(_params["stimulus_ms"]), int(_trial["isi_ms"]))
	if phase == _phase:
		return
	_phase = phase
	if phase == GoNoGoClock.Phase.STIMULUS:
		_stim_onset_us = Time.get_ticks_usec()
		if _trial["is_go"]:
			_stimulus.show_calf()
		else:
			_stimulus.show_snake()
		_set_herd_button_enabled(true)
	elif phase == GoNoGoClock.Phase.ISI:
		_stimulus.clear()
	if phase != GoNoGoClock.Phase.STIMULUS and _stim_onset_us == 0:
		# A long frame skipped the stimulus; count RT from when it should have appeared.
		_stim_onset_us = _trial_start_us + int(_params["fixation_ms"]) * TaskConst.USEC_PER_MS
	if phase == GoNoGoClock.Phase.DONE:
		_finish_trial()


func _register_response() -> void:
	var now := Time.get_ticks_usec()
	if _phase == GoNoGoClock.Phase.FIXATION:
		_early_taps += 1
	elif not _responded:
		_responded = true
		_rt_ms = TaskConst.us_to_ms(now - _stim_onset_us)
		if _trial["is_go"]:
			_mistake_cue.play_correct(TaskConst.TEXT_RIGHT) # Tapped a calf.
		else:
			_mistake_cue.play(true, TaskConst.TEXT_TRY_AGAIN) # Tapped a snake.


func _finish_trial() -> void:
	var result := _session.record(_responded, _rt_ms)
	if _trial["is_go"] and not _responded:
		_mistake_cue.play_too_slow() # A calf got away.
	elif not _trial["is_go"] and not _responded:
		_mistake_cue.play_correct(TaskConst.TEXT_RIGHT) # Left the snake alone.
	logger.log_trial(_trial["number"], _trial_params(), _stimulus_info(), {"responded": _responded},
			result["correct"], _rt_ms, true)
	_begin_trial()


func _trial_params() -> Dictionary:
	return {
		"practice": _trial["practice"],
		"fixation_ms": _params["fixation_ms"],
		"stimulus_ms": _params["stimulus_ms"],
		"isi_ms": _trial["isi_ms"],
		"early_taps": _early_taps,
	}


func _stimulus_info() -> Dictionary:
	return {"type": "go" if _trial["is_go"] else "nogo"}


func _complete() -> void:
	_set_herd_button_enabled(false)
	_state = State.DONE
	set_process(false)
	_stimulus.clear()
	var results := _session.get_results()
	results["difficulty_level"] = int(_params.get("difficulty_level", -1))
	_progress.value = 1.0
	_finish(results)


func _set_herd_button_enabled(enabled: bool) -> void:
	if _pad != null:
		_pad.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func _elapsed_ms(since_us: int) -> float:
	return float(Time.get_ticks_usec() - since_us) / TaskConst.USEC_PER_MS


func _show_results(results: Dictionary) -> void:
	_last_results = results
	_set_skip_button_visible(false)
	var speed := "n/a"
	if results["rt_mean_ms"] > 0.0:
		speed = "%d ms (SD %d)" % [roundi(results["rt_mean_ms"]), roundi(results["rt_sd_ms"])]
	var lines: Array[String] = [
		"Calves herded home: %d of %d" % [results["hits"], results["go_trials"]],
		"Calves missed: %d" % results["omissions"],
		"Snakes tapped by mistake: %d of %d" % [results["commissions"], results["nogo_trials"]],
		"Snakes avoided: %d" % results["correct_rejections"],
		"Accuracy: %d%%" % roundi(float(results["accuracy"]) * 100.0),
		"Average speed: %s" % speed,
		"d-prime: %.2f" % results["d_prime"],
	]
	_append_level_line(lines, results)
	_summary.text = "\n".join(lines)
	_points_offer.show_award(last_award)
	_results_panel.show()
	_play_again.grab_focus()
