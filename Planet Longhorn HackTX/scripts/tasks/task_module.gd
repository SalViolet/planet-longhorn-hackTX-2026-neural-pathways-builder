class_name TaskModule
extends Control
## Base class for every cognitive task scene. Subclasses override
## get_task_name() and start(), and call _finish() when the run ends.

signal finished(results: Dictionary)

var logger: TrialLogger = TrialLogger.new()
## False while the window is in the background. Tasks wait for it before starting a trial.
var window_has_focus := true

var _skip_ui: SkipPrompt
var _mistake_cue: MistakeCue
var last_award: Dictionary = {} # Points earned by the run that just finished (empty for dev runs).
var _skip_open := false
var _skip_previous_focus: Control


func get_task_name() -> String:
	return "task"


## The story mission this task belongs to ("" if none). Finished runs feed the adaptive engine.
func get_mission_id() -> String:
	return ""


@warning_ignore("unused_parameter")
func start(params: Dictionary) -> void:
	push_error("%s must override start()" % get_task_name())


## Tasks override this: stop the trial in progress and log it as invalid with `reason`.
## It must do nothing when no trial is running. Called on window focus loss.
@warning_ignore("unused_parameter")
func abort_current_trial(reason: String) -> void:
	pass


## Tasks override this: carry on if the run was waiting (for the window to come back, or for
## the skip warning to be answered).
func on_focus_gained() -> void:
	pass


## Tasks override this: false once the run is over (the results screen), when skipping makes no sense.
func can_skip() -> bool:
	return true


## Tasks check this before starting each trial: the window must be in front and the skip
## warning closed.
func can_run_trials() -> bool:
	return window_has_focus and not _skip_open


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		window_has_focus = false
		abort_current_trial(TaskConst.REASON_FOCUS_LOST)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		window_has_focus = true
		on_focus_gained()


## Adds the corner Skip button and its warning on top of everything. Call once from _ready,
## after the theme is set.
func _add_skip_ui() -> void:
	_skip_ui = SkipPrompt.new()
	add_child(_skip_ui)
	# Keep it on top of anything the task adds later, such as overlays and the progress bar.
	(func() -> void: move_child(_skip_ui, -1)).call_deferred()
	_skip_ui.keep_playing.connect(_on_skip_declined)
	_skip_ui.skip_confirmed.connect(_on_skip_confirmed)
	_skip_ui.opened.connect(_on_skip_opened)


## Adds the soft orange mistake glow. Call once from _ready; show it with `_mistake_cue.play()`.
func _add_mistake_cue() -> void:
	_mistake_cue = MistakeCue.new()
	add_child(_mistake_cue)


## Adds the big push button at the bottom centre, just after `after` in the child order so
## overlays and results panels stay on top of it. Returns the pad.
func _add_response_pad(label_text: String, color: Color, after: Control) -> ResponsePad:
	var pad := ResponsePad.new()
	add_child(pad)
	move_child(pad, after.get_index() + 1)
	pad.setup(label_text, color)
	pad.anchor_left = 0.5
	pad.anchor_right = 0.5
	pad.anchor_top = 1.0
	pad.anchor_bottom = 1.0
	pad.offset_left = -TaskConst.PAD_SIZE.x / 2.0
	pad.offset_right = TaskConst.PAD_SIZE.x / 2.0
	pad.offset_top = -TaskConst.PAD_SIZE.y - TaskConst.PAD_BOTTOM_MARGIN
	pad.offset_bottom = -TaskConst.PAD_BOTTOM_MARGIN
	return pad


## Puts the calf that offers points at the left of the screen, outside the results panel.
func _add_points_offer() -> PointsOffer:
	var offer := PointsOffer.new()
	offer.place_left(self)
	return offer


## Adds the "Level N" / "Level up!" line to a results summary (nothing for dev runs).
func _append_level_line(lines: Array[String], results: Dictionary) -> void:
	var text := AdaptiveEngine.level_text(get_mission_id(), results)
	if text != "":
		lines.append(text)


## Tasks call this first in `_input`: a click on the Skip button is not a response to the
## trial, and must reach the button so it works on the first click.
func _is_skip_button_click(event: InputEvent) -> bool:
	return _skip_ui != null and _skip_ui.is_click_on_button(event)


## Hides the Skip button, for example while the results screen is showing.
func _set_skip_button_visible(on: bool) -> void:
	if _skip_ui != null:
		_skip_ui.set_button_visible(on)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _skip_ui != null and can_skip() and not _skip_ui.is_open():
		get_viewport().set_input_as_handled()
		_skip_ui.open()


func _on_skip_opened() -> void:
	if _skip_open:
		return
	_skip_open = true
	_skip_previous_focus = get_viewport().gui_get_focus_owner()
	abort_current_trial(TaskConst.REASON_SKIP_PROMPT) # The trial in progress is logged as invalid.


func _on_skip_declined() -> void:
	_skip_open = false
	if is_instance_valid(_skip_previous_focus) and _skip_previous_focus.is_visible_in_tree():
		_skip_previous_focus.grab_focus()
	if window_has_focus:
		on_focus_gained()


## Nothing from this run is saved or counted. The story takes the player back to the hub.
func _on_skip_confirmed() -> void:
	set_process(false)
	StoryFlow.skip_mission(get_mission_id())


## Saves the trial log, records its path in the results, tells the adaptive engine, then adds the numbers to `Metrics`, then emits `finished`.
func _finish(results: Dictionary) -> void:
	results["log_path"] = logger.save_csv()
	if get_mission_id() != "":
		AdaptiveEngine.record_run(get_mission_id(), results)
		if int(results.get("difficulty_level", -1)) >= 0: # Dev runs are not counted.
			Metrics.record(get_mission_id(), results)
			RunHistory.record(get_mission_id(), results, Time.get_datetime_string_from_system())
			var tagged := results.duplicate()
			tagged["mission_id"] = get_mission_id()
			last_award = PointsStore.record_completion(get_mission_id(), "", StoryData.performance_band(tagged))
		else:
			last_award = {}
	finished.emit(results)


## A thin bar across the top of the screen. Set `value` (0-1) between trials only.
func _add_progress_bar() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = 1.0
	bar.step = 0.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	bar.anchor_right = 1.0
	bar.offset_left = TaskConst.PROGRESS_BAR_MARGIN
	bar.offset_right = -TaskConst.PROGRESS_BAR_MARGIN
	bar.offset_top = TaskConst.PROGRESS_BAR_MARGIN
	bar.offset_bottom = TaskConst.PROGRESS_BAR_MARGIN + TaskConst.PROGRESS_BAR_HEIGHT
	bar.visible = TaskConst.SHOW_PROGRESS_BAR
	return bar
