extends Control
## "Who's playing?": pick a profile, make a new one, or delete one (with a confirmation).
## Picking or creating a profile makes it the active one and carries on into the story.

@onready var _list_panel: PanelContainer = %ListPanel
@onready var _heading: Label = %Heading
@onready var _scroll: ScrollContainer = %Scroll
@onready var _rows: VBoxContainer = %Rows
@onready var _new_button: Button = %NewButton
@onready var _back_button: Button = %BackButton
@onready var _create_panel: PanelContainer = %CreatePanel
@onready var _new_heading: Label = %NewHeading
@onready var _hint: Label = %HintLabel
@onready var _name_edit: LineEdit = %NameEdit
@onready var _swatches: HBoxContainer = %Swatches
@onready var _error: Label = %ErrorLabel
@onready var _create_button: Button = %CreateButton
@onready var _cancel_button: Button = %CancelButton
@onready var _confirm_panel: PanelContainer = %ConfirmPanel
@onready var _confirm_label: Label = %ConfirmLabel
@onready var _confirm_delete: Button = %ConfirmDeleteButton
@onready var _confirm_keep: Button = %ConfirmKeepButton

var _selected_color := 0
var _pending_delete := ""
var _swatch_buttons: Array[Button] = []
var _sample_button: Button
var _sample_note: Label


func _ready() -> void:
	theme = ThemeBuilder.get_theme()
	_heading.text = ProfileConst.HEADING_TEXT
	_new_heading.text = ProfileConst.NEW_HEADING_TEXT
	_hint.text = ProfileConst.NEW_HINT_TEXT
	_name_edit.placeholder_text = ProfileConst.NAME_PLACEHOLDER
	_name_edit.max_length = ProfileConst.MAX_NAME_LENGTH
	_back_button.text = ProfileConst.BACK_TEXT
	_create_button.text = ProfileConst.CREATE_TEXT
	_cancel_button.text = ProfileConst.CANCEL_TEXT
	_confirm_delete.text = ProfileConst.DELETE_TEXT
	_confirm_keep.text = ProfileConst.KEEP_TEXT
	_error.add_theme_color_override("font_color", ProfileConst.COLOR_ERROR)
	_scroll.custom_minimum_size = ProfileConst.LIST_MIN_SIZE
	for panel: PanelContainer in [_list_panel, _create_panel, _confirm_panel]:
		panel.custom_minimum_size.x = ProfileConst.PANEL_MIN_WIDTH
	for button: Button in [_new_button, _back_button, _create_button, _cancel_button, _confirm_delete, _confirm_keep]:
		button.custom_minimum_size = UIConst.BUTTON_MIN_SIZE
	_rows.add_theme_constant_override("separation", ProfileConst.ROW_SEPARATION)

	_new_button.pressed.connect(_show_create)
	_sample_button = Button.new()
	_sample_button.text = ProfileConst.SAMPLE_TEXT
	_sample_button.custom_minimum_size = UIConst.BUTTON_MIN_SIZE
	_sample_button.size_flags_horizontal = _new_button.size_flags_horizontal
	_new_button.get_parent().add_child(_sample_button)
	_new_button.get_parent().move_child(_sample_button, _new_button.get_index() + 1)
	_sample_button.pressed.connect(_add_sample)
	_sample_note = Label.new()
	_sample_note.text = ProfileConst.SAMPLE_HINT
	_sample_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sample_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sample_note.add_theme_color_override("font_color", UIConst.COLOR_TEXT_DIM)
	_sample_note.add_theme_font_size_override("font_size", ProfileConst.SAMPLE_NOTE_FONT_SIZE)
	_new_button.get_parent().add_child(_sample_note)
	_new_button.get_parent().move_child(_sample_note, _sample_button.get_index() + 1)
	_back_button.pressed.connect(_go_back)
	_create_button.pressed.connect(_try_create)
	_name_edit.text_submitted.connect(func(_text: String) -> void: _try_create())
	_name_edit.text_changed.connect(func(_text: String) -> void: _error.text = "")
	_cancel_button.pressed.connect(_cancel_create)
	_confirm_delete.pressed.connect(_do_delete)
	_confirm_keep.pressed.connect(_show_list)
	_build_swatches()
	if ProfileStore.count() == 0:
		_show_create()
	else:
		_show_list()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if _confirm_panel.visible:
		_show_list()
	elif _create_panel.visible:
		_cancel_create()
	else:
		_go_back()


func _go_back() -> void:
	SceneTransition.change_scene(UIConst.SCENE_START)


# --- The list ---

func _show_list() -> void:
	_create_panel.hide()
	_confirm_panel.hide()
	_list_panel.show()
	for child in _rows.get_children():
		child.queue_free()
	var focus_target: Button = null
	for profile in ProfileStore.list():
		var play := _add_row(profile)
		if profile["id"] == ProfileStore.last_id() or focus_target == null:
			focus_target = play
	var full := ProfileStore.count() >= ProfileConst.MAX_PROFILES
	_new_button.text = ProfileConst.FULL_BUTTON_TEXT if full else ProfileConst.NEW_BUTTON_TEXT
	_new_button.disabled = full
	(focus_target if focus_target != null else _new_button).grab_focus.call_deferred()


func _add_row(profile: Dictionary) -> Button:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", ProfileConst.ROW_SEPARATION)
	var badge := ProfileBadge.new()
	badge.custom_minimum_size = Vector2.ONE * ProfileConst.BADGE_SIZE
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.setup(profile["color"])
	var play := Button.new()
	play.text = profile["name"]
	play.custom_minimum_size = ProfileConst.ROW_BUTTON_MIN_SIZE
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play.pressed.connect(_on_play.bind(profile["id"]))
	var delete := Button.new()
	delete.text = ProfileConst.DELETE_TEXT
	delete.custom_minimum_size = ProfileConst.DELETE_BUTTON_MIN_SIZE
	delete.pressed.connect(_ask_delete.bind(profile["id"]))
	row.add_child(badge)
	row.add_child(play)
	row.add_child(delete)
	_rows.add_child(row)
	return play


func _on_play(id: String) -> void:
	if SceneTransition.is_changing():
		return
	if ProfileStore.activate(id):
		StoryFlow.begin_quest()


func _add_sample() -> void:
	var result := SampleData.install()
	_sample_note.text = ProfileConst.SAMPLE_HINT if result["ok"] else String(result["error"])
	_show_list()


# --- Deleting ---

func _ask_delete(id: String) -> void:
	_pending_delete = id
	_confirm_label.text = ProfileConst.CONFIRM_FORMAT % ProfileStore.get_profile(id).get("name", "")
	_list_panel.hide()
	_confirm_panel.show()
	_confirm_keep.grab_focus() # The safe choice is focused first.


func _do_delete() -> void:
	ProfileStore.delete(_pending_delete)
	_pending_delete = ""
	if ProfileStore.count() == 0:
		_show_create()
	else:
		_show_list()


# --- Creating ---

func _build_swatches() -> void:
	var group := ButtonGroup.new()
	for i in ProfileConst.AVATARS.size():
		var swatch := Button.new()
		swatch.toggle_mode = true
		swatch.button_group = group
		swatch.custom_minimum_size = Vector2.ONE * ProfileConst.SWATCH_SIZE
		for state in ["normal", "hover", "disabled"]:
			swatch.add_theme_stylebox_override(state, _swatch_box(false))
		for state in ["pressed", "hover_pressed"]:
			swatch.add_theme_stylebox_override(state, _swatch_box(true))
		var portrait := ProfileBadge.new()
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		swatch.add_child(portrait)
		portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, ProfileConst.SWATCH_INSET)
		portrait.setup(i)
		swatch.toggled.connect(func(on: bool) -> void:
			if on:
				_selected_color = i)
		_swatches.add_child(swatch)
		_swatch_buttons.append(swatch)


# The picker button is just a ring that shows which avatar is chosen; the portrait sits inside.
func _swatch_box(selected: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color.TRANSPARENT
	box.set_corner_radius_all(ProfileConst.SWATCH_RADIUS)
	if selected:
		box.set_border_width_all(ProfileConst.SWATCH_SELECTED_BORDER)
		box.border_color = UIConst.COLOR_FOCUS
	return box


func _show_create() -> void:
	_list_panel.hide()
	_confirm_panel.hide()
	_create_panel.show()
	_name_edit.text = ""
	_error.text = ""
	var used: Array[int] = []
	for profile in ProfileStore.list():
		used.append(profile["color"])
	_selected_color = ProfileRules.next_free_color(used)
	_swatch_buttons[_selected_color].button_pressed = true
	_name_edit.grab_focus.call_deferred()


func _cancel_create() -> void:
	if ProfileStore.count() == 0:
		_go_back()
	else:
		_show_list()


func _try_create() -> void:
	var result := ProfileStore.create(_name_edit.text, _selected_color)
	if not result["ok"]:
		_error.text = result["error"]
		_name_edit.grab_focus()
		return
	if SceneTransition.is_changing():
		return
	ProfileStore.activate(result["profile"]["id"])
	StoryFlow.begin_quest()
