extends TaskModule
## CPT (night watch). Trials run on a fixed grid from the start of the run (trial i begins at
## i * trial_ms), timed with Time.get_ticks_usec() in _process, so the run never drifts.
## During the run only the shape changes, plus the player's own response: the flashlight beam
## and a soft green or orange glow with a short word at the top. A thin progress bar at the top
## steps once per trial (trials finished out of all trials), so it is always accurate.
## If the window loses focus, the trial in progress is logged as invalid and the run pauses
## until the window returns, then resumes with the next trial after a short quiet pause.

enum State { IDLE, WAITING, LEAD_IN, RUN, PAUSED, DONE }

@onready var _view: CptView = %View
@onready var _overlay: Control = %Overlay
@onready var _overlay_dimmer: ColorRect = %OverlayDimmer
@onready var _overlay_box: PanelContainer = %OverlayBox
@onready var _overlay_heading: Label = %OverlayHeading
@onready var _overlay_body: Label = %OverlayBody
@onready var _start: Button = %StartButton
@onready var _dev_start: Button = %DevStartButton
@onready var _results_panel: Control = %ResultsPanel
@onready var _results_dimmer: ColorRect = %ResultsDimmer
@onready var _results_box: PanelContainer = %ResultsBox
@onready var _summary: Label = %SummaryLabel
var _points_offer: PointsOffer
var _pad: ResponsePad
var _progress: ProgressBar
@onready var _play_again: Button = %PlayAgainButton
@onready var _continue: Button = %ContinueButton

var _params: Dictionary = {}
var _session: CptSession
var _state: State = State.IDLE
var _trial_count := 0
var _trial_ms := 0
var _run_start_us := 0
var _lead_in_start_us := 0
var _resume_index := 0 # The trial the run (re)starts from.
var _index := -1 # The trial in progress, -1 before the first one.
var _onset_us := 0
var _responded := false
var _rt_ms := -1
var _extra_taps := 0
var _trial_logged := false # True once the trial in progress is already in the log (aborted or skipped).
var _last_results: Dictionary = {}
var _pending_params: Dictionary = {}


func _ready() -> void:
	theme = ThemeBuilder.get_theme()
	_add_skip_ui()
	_add_mistake_cue()
	_progress = _add_progress_bar()
	_points_offer = _add_points_offer()
	_pad = _add_response_pad(CptConst.PAD_TEXT, CptConst.COLOR_PAD, _view)
	_pad.pressed_down.connect(_on_pad_pressed)
	for dimmer: ColorRect in [_overlay_dimmer, _results_dimmer]:
		dimmer.color = UIConst.COLOR_DIMMER
	_overlay_box.custom_minimum_size.x = CptConst.OVERLAY_TEXT_MIN_WIDTH
	_results_box.custom_minimum_size.x = CptConst.RESULTS_TEXT_MIN_WIDTH
	for button: Button in [_start, _dev_start, _play_again, _continue]:
		button.custom_minimum_size = UIConst.BUTTON_MIN_SIZE
	_start.text = CptConst.START_TEXT
	_dev_start.text = CptConst.DEV_START_TEXT
	_dev_start.visible = OS.is_debug_build() # Quick test mode is for development only.
	_start.pressed.connect(func() -> void: _begin_lead_in(false))
	_dev_start.pressed.connect(func() -> void: _begin_lead_in(true))
	_play_again.pressed.connect(func() -> void: start(AdaptiveEngine.params_for(CptConst.MISSION_ID)))
	_continue.pressed.connect(func() -> void: StoryFlow.after_task(CptConst.MISSION_ID, _last_results))
	finished.connect(_show_results)
	set_process(false)
	start(AdaptiveEngine.params_for(CptConst.MISSION_ID))


func get_task_name() -> String:
	return CptConst.TASK_NAME


func can_skip() -> bool:
	return _state != State.DONE


func get_mission_id() -> String:
	return CptConst.MISSION_ID


## Shows the instructions; the run itself begins when the player presses Start.
func start(params: Dictionary) -> void:
	_pending_params = params
	_progress.value = 0.0
	_results_panel.hide()
	_set_skip_button_visible(true)
	_state = State.WAITING
	_view.clear()
	_overlay_heading.text = CptConst.HEADING_TEXT
	_overlay_body.text = CptConst.INSTRUCTIONS_TEXT
	_overlay.show()
	_start.grab_focus()
	set_process(true)


func _process(_delta: float) -> void:
	match _state:
		State.LEAD_IN:
			if _elapsed_ms(_lead_in_start_us) >= CptConst.LEAD_IN_MS:
				_start_schedule()
		State.RUN:
			_update_run()


func _input(event: InputEvent) -> void:
	if _state != State.RUN or _index < 0:
		return
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		get_viewport().set_input_as_handled() # Space, Enter or gamepad A.
		_pad.press_visual()
		_register_tap()


## The big button was pushed with the mouse or a finger (it already showed itself sinking).
func _on_pad_pressed() -> void:
	if _state == State.RUN and _index >= 0:
		_register_tap()


func _register_tap() -> void:
	_view.shine()
	if _responded:
		_extra_taps += 1
	else:
		_responded = true
		_rt_ms = TaskConst.us_to_ms(Time.get_ticks_usec() - _onset_us)
		if _session.is_target(_index):
			_mistake_cue.play_correct(TaskConst.TEXT_RIGHT) # The light caught the thief.
		else:
			_mistake_cue.play(true, TaskConst.TEXT_TRY_AGAIN) # Shone it on a harmless shape.


func abort_current_trial(reason: String) -> void:
	if _state != State.RUN:
		return
	if _index >= 0:
		logger.log_trial(_index + 1, _trial_params(), _stimulus_info(_index), {"responded": _responded},
				false, _rt_ms, false, reason)
		_session.record(_index, false, -1, false)
		_trial_logged = true
		_resume_index = _index + 1
	_view.clear()
	_state = State.PAUSED # Resumes in on_focus_gained().


func on_focus_gained() -> void:
	if _state == State.PAUSED:
		_begin_lead_in(false, true)


func _begin_lead_in(dev_mode: bool, resuming: bool = false) -> void:
	_overlay.hide()
	if not resuming:
		_setup_run(dev_mode)
	_state = State.LEAD_IN
	_view.clear()
	_lead_in_start_us = Time.get_ticks_usec()


func _setup_run(dev_mode: bool) -> void:
	_params = CptConst.DEFAULT_PARAMS.duplicate()
	_params.merge(_pending_params, true)
	if dev_mode:
		_params["trials"] = CptConst.DEV_TRIALS
		_params.erase("difficulty_level") # Short test runs must not move the adaptive engine.
	_trial_ms = int(_params["trial_ms"])
	_trial_count = int(_params.get("trials", int(_params["duration_ms"]) / _trial_ms))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_session = CptSession.new(_trial_count, float(_params["target_probability"]), rng)
	logger = TrialLogger.new()
	logger.begin(get_task_name())
	_resume_index = 0


func _start_schedule() -> void:
	if not can_run_trials():
		_state = State.PAUSED
		return
	if _resume_index >= _trial_count:
		_complete()
		return
	# Trial numbering stays on one grid even after a pause: the next trial starts right away.
	_run_start_us = Time.get_ticks_usec() - _resume_index * _trial_ms * TaskConst.USEC_PER_MS
	_index = _resume_index - 1
	_state = State.RUN


func _update_run() -> void:
	var elapsed := _elapsed_ms(_run_start_us)
	var due := CptClock.trial_index(elapsed, _trial_ms)
	while _index < due:
		if _index >= 0:
			_end_trial()
		_index += 1
		if _index >= _trial_count:
			_complete()
			return
		if _index < due:
			# A very long frame skipped a whole trial: log it as invalid, never as a miss.
			_start_trial()
			logger.log_trial(_index + 1, _trial_params(), _stimulus_info(_index), {"responded": false},
					false, -1, false, TaskConst.REASON_FRAME_SKIPPED)
			_session.record(_index, false, -1, false)
			_trial_logged = true
			_view.clear()
		else:
			_start_trial()
	if _index >= 0 and not CptClock.stimulus_visible(elapsed, _trial_ms, int(_params["stimulus_ms"])):
		_view.clear()


func _start_trial() -> void:
	_progress.value = float(_index) / maxf(_trial_count, 1) # Trials finished so far.
	_trial_logged = false
	_responded = false
	_rt_ms = -1
	_extra_taps = 0
	_onset_us = Time.get_ticks_usec()
	_view.show_glyph(_session.glyph_at(_index))


func _end_trial() -> void:
	if _trial_logged:
		return
	var result := _session.record(_index, _responded, _rt_ms)
	logger.log_trial(_index + 1, _trial_params(), _stimulus_info(_index), {"responded": _responded},
			result["correct"], _rt_ms, true)
	if _session.is_target(_index) and not _responded:
		_mistake_cue.play_too_slow() # The thief got away.


func _trial_params() -> Dictionary:
	return {
		"stimulus_ms": _params["stimulus_ms"],
		"trial_ms": _params["trial_ms"],
		"extra_taps": _extra_taps,
	}


func _stimulus_info(index: int) -> Dictionary:
	return {"glyph": _session.glyph_at(index), "target": _session.is_target(index)}


func _complete() -> void:
	_progress.value = 1.0
	_state = State.DONE
	set_process(false)
	_view.clear()
	var results := _session.get_results()
	results["difficulty_level"] = int(_params.get("difficulty_level", -1))
	_finish(results)


func _elapsed_ms(since_us: int) -> float:
	return float(Time.get_ticks_usec() - since_us) / TaskConst.USEC_PER_MS


func _show_results(results: Dictionary) -> void:
	_last_results = results
	_set_skip_button_visible(false)
	var speed := "n/a"
	if results["rt_mean_ms"] > 0.0:
		speed = "%d ms (SD %d, CV %.2f)" % [roundi(results["rt_mean_ms"]), roundi(results["rt_sd_ms"]), results["rt_cv"]]
	var bin_rates := PackedStringArray()
	for bin: Dictionary in results["bins"]:
		bin_rates.append("%d%%" % roundi(float(bin["hit_rate"]) * 100.0) if bin["targets"] > 0 else "-")
	var lines: Array[String] = [
		"Masked cows caught: %d of %d" % [results["hits"], results["targets"]],
		"Masked cows missed: %d" % results["omissions"],
		"Wrong taps: %d" % results["commissions"],
		"d-prime: %.2f   criterion: %.2f" % [results["d_prime"], results["criterion"]],
		"Reaction time: %s" % speed,
		"Caught over time: %s" % "  ".join(bin_rates),
	]
	_append_level_line(lines, results)
	_summary.text = "\n".join(lines)
	_points_offer.show_award(last_award)
	_results_panel.show()
	_play_again.grab_focus()
