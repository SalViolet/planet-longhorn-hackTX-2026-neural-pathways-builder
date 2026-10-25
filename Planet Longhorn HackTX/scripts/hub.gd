extends Control
## Mission map: shows the four missions, which are playable, and your best results.

const TITLE_TEXT := "LONGHORN PLANET"
const RESET_TEXT := "Reset story"

@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _progress_label: Label = %ProgressLabel
@onready var _quest_bar: ProgressBar = %QuestBar
@onready var _list: VBoxContainer = %MissionList
@onready var _back: Button = %BackButton
@onready var _reset: Button = %ResetButton
@onready var _player_label: Label = %PlayerLabel
@onready var _switch: Button = %SwitchButton

var _points: PointsOffer
var _report_panel: Control
var _report_heading: Label
var _report_body: Label
var _report_path := ""
var _report_copy: Button
var _report_button: Button


func _ready() -> void:
	theme = ThemeBuilder.get_theme()
	_title.text = TITLE_TEXT
	_list.add_theme_constant_override("separation", StoryConst.HUB_SEPARATION)
	(_title.get_parent() as Control).add_theme_constant_override("separation", StoryConst.HUB_SEPARATION)
	_back.custom_minimum_size = UIConst.BUTTON_MIN_SIZE
	_reset.custom_minimum_size = StoryConst.HUB_SMALL_BUTTON_SIZE
	_reset.text = RESET_TEXT
	_back.pressed.connect(func() -> void: SceneTransition.change_scene(UIConst.SCENE_START))
	_switch.text = ProfileConst.SWITCH_TEXT
	_switch.custom_minimum_size = ProfileConst.SWITCH_BUTTON_SIZE
	_switch.pressed.connect(func() -> void: SceneTransition.change_scene(UIConst.SCENE_PROFILES))
	var profile := ProfileStore.active_profile()
	_player_label.visible = not profile.is_empty()
	if not profile.is_empty():
		_player_label.text = ProfileConst.PLAYER_LABEL_FORMAT % profile["name"]
	# Testing aid: forget story progress, skill estimates and difficulty levels, to start over.
	_reset.pressed.connect(func() -> void:
		StoryProgress.reset()
		AdaptiveEngine.reset()
		get_tree().reload_current_scene())
	_quest_bar.custom_minimum_size = StoryConst.HUB_BAR_SIZE
	_build_report_ui()
	_points = PointsOffer.new()
	_points.place_left(self)
	_points.show_summary()
	_build_missions()


func _build_missions() -> void:
	var suggested := StoryRules.next_mission_id()
	var focus_target: Button = _back
	var done := 0
	var total := 0
	var any_skipped := false
	for entry: Dictionary in StoryData.MISSIONS:
		var id := String(entry["id"])
		if StoryData.is_playable(id):
			total += 1
			done += 1 if StoryProgress.plays(id) > 0 else 0
			any_skipped = any_skipped or (StoryProgress.plays(id) == 0 and StoryProgress.skips(id) > 0)
		var button := Button.new()
		button.custom_minimum_size = StoryConst.HUB_MISSION_MIN_SIZE
		var mark := StoryConst.HUB_NEXT_MARK if id == suggested and done < total else ""
		button.text = "%s%s%s\n%s" % [entry["title"], _status(id), mark, entry["blurb"]]
		button.disabled = not StoryData.is_playable(id)
		if not button.disabled:
			button.pressed.connect(StoryFlow.launch_mission.bind(id))
		_list.add_child(button)
		if id == suggested:
			focus_target = button
	_progress_label.text = StoryConst.HUB_PROGRESS_FORMAT % [done, total]
	_quest_bar.max_value = maxf(total, 1)
	_quest_bar.value = done
	if total > 0 and done == total:
		_subtitle.text = StoryConst.HUB_SUBTITLE_DONE
	elif any_skipped:
		_subtitle.text = StoryConst.HUB_SUBTITLE_SKIPPED
	else:
		_subtitle.text = StoryConst.HUB_SUBTITLE
	focus_target.grab_focus()


func _status(mission_id: String) -> String:
	if not StoryData.is_playable(mission_id):
		return "  (coming soon)"
	if StoryProgress.plays(mission_id) > 0:
		var level := "level %d, " % (AdaptiveEngine.level(mission_id) + 1) if AdaptiveEngine.is_placed(mission_id) else ""
		match StoryData.mission(mission_id)["summary"]:
			"accuracy":
				return "  (%sbest accuracy %d%%)" % [level, StoryProgress.best_accuracy_percent(mission_id)]
			"dprime":
				return "  (%sbest d' %.1f)" % [level, StoryProgress.best_dprime_x10(mission_id) / 10.0]
		return "  (%sbest span %d)" % [level, StoryProgress.best_span(mission_id)]
	return StoryConst.HUB_SKIPPED_TEXT if StoryProgress.skips(mission_id) > 0 else ""


func _build_report_ui() -> void:
	_report_button = Button.new()
	_report_button.text = ReportConst.BUTTON_TEXT
	_report_button.custom_minimum_size = ProfileConst.SWITCH_BUTTON_SIZE
	add_child(_report_button) # Top-right corner: the centre column has no room left.
	_report_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, UIConst.SCREEN_MARGIN)
	_report_button.pressed.connect(_on_report_pressed)

	_report_panel = Control.new()
	_report_panel.visible = false
	add_child(_report_panel)
	_report_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dimmer := ColorRect.new()
	dimmer.color = UIConst.COLOR_DIMMER
	_report_panel.add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_report_panel.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = ReportConst.PANEL_MIN_WIDTH
	center.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_report_heading = Label.new()
	_report_heading.theme_type_variation = &"HeadingLabel"
	_report_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_report_heading)
	_report_body = Label.new()
	_report_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_report_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_report_body)
	_report_copy = Button.new()
	_report_copy.text = ReportConst.COPY_TEXT
	_report_copy.custom_minimum_size = UIConst.BUTTON_MIN_SIZE
	_report_copy.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_report_copy.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(_report_path)
		_report_copy.text = ReportConst.COPIED_TEXT)
	box.add_child(_report_copy)
	var close := Button.new()
	close.text = ReportConst.CLOSE_TEXT
	close.custom_minimum_size = UIConst.BUTTON_MIN_SIZE
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func() -> void:
		_report_panel.hide()
		_report_button.grab_focus())
	box.add_child(close)


func _on_report_pressed() -> void:
	var result := ReportWriter.generate()
	_report_path = String(result["path"])
	_report_copy.text = ReportConst.COPY_TEXT
	_report_copy.visible = bool(result["ok"])
	if result["ok"]:
		_report_heading.text = ReportConst.PANEL_HEADING
		_report_body.text = "%s\n\n%s" % [ReportConst.PANEL_BODY, _report_path]
	else:
		_report_heading.text = ReportConst.PANEL_FAILED_HEADING
		_report_body.text = String(result["error"])
	_report_panel.show()
	(_report_copy if _report_copy.visible else _report_panel.find_children("*", "Button", true, false).back()).grab_focus()
