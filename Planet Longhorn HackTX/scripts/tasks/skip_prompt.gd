class_name SkipPrompt
extends Control
## The corner "Skip" button and the warning that follows it. Built in code and added on top of a
## task by TaskModule. The button can't take keyboard focus, so Space/Enter in a task never
## trigger it. Nothing here appears unless the player asks for it.

signal opened
signal keep_playing
signal skip_confirmed

var _button: Button
var _modal: Control
var _keep: Button
var _skip: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_button()
	_build_modal()


func is_open() -> bool:
	return _modal.visible


func open() -> void:
	_modal.show()
	_keep.grab_focus() # The safe choice is focused first.
	opened.emit()


func close() -> void:
	_modal.hide()


## True if a mouse or touch event lands on the visible Skip button.
func is_click_on_button(event: InputEvent) -> bool:
	if not (event is InputEventMouseButton) or not _button.is_visible_in_tree():
		return false
	return _button.get_global_rect().has_point((event as InputEventMouseButton).position)


func set_button_visible(on: bool) -> void:
	_button.visible = on and TaskConst.SHOW_SKIP_BUTTON


func _unhandled_input(event: InputEvent) -> void:
	if _modal.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_keep_pressed()


func _build_button() -> void:
	_button = Button.new()
	_button.text = TaskConst.SKIP_BUTTON_TEXT
	_button.focus_mode = Control.FOCUS_NONE
	_button.custom_minimum_size = TaskConst.SKIP_BUTTON_SIZE
	_button.add_theme_font_size_override("font_size", TaskConst.SKIP_BUTTON_FONT_SIZE)
	_button.modulate.a = TaskConst.SKIP_BUTTON_ALPHA
	_button.visible = TaskConst.SHOW_SKIP_BUTTON
	add_child(_button)
	_button.anchor_left = 1.0
	_button.anchor_right = 1.0
	_button.offset_left = -TaskConst.SKIP_BUTTON_SIZE.x - TaskConst.PROGRESS_BAR_MARGIN
	_button.offset_right = -TaskConst.PROGRESS_BAR_MARGIN
	_button.offset_top = TaskConst.SKIP_BUTTON_TOP
	_button.offset_bottom = TaskConst.SKIP_BUTTON_TOP + TaskConst.SKIP_BUTTON_SIZE.y
	_button.pressed.connect(open)


func _build_modal() -> void:
	_modal = Control.new()
	_modal.visible = false
	add_child(_modal)
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dimmer := ColorRect.new()
	dimmer.color = UIConst.COLOR_DIMMER
	_modal.add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_modal.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = TaskConst.SKIP_PANEL_MIN_WIDTH
	center.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var heading := Label.new()
	heading.text = TaskConst.SKIP_HEADING
	heading.theme_type_variation = &"HeadingLabel"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	var warning := Label.new()
	warning.text = TaskConst.SKIP_WARNING
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(warning)
	_keep = _make_button(TaskConst.SKIP_KEEP_TEXT, box)
	_skip = _make_button(TaskConst.SKIP_CONFIRM_TEXT, box)
	_keep.pressed.connect(_keep_pressed)
	_skip.pressed.connect(_skip_pressed)


func _make_button(text: String, parent: Control) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = UIConst.BUTTON_MIN_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(button)
	return button


func _keep_pressed() -> void:
	close()
	keep_playing.emit()


func _skip_pressed() -> void:
	close()
	skip_confirmed.emit()
