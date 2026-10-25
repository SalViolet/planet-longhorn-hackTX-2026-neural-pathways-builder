extends Control

# Change these two to rename the game / tagline.
const TITLE_TEXT := "PLANET LONGHORN"
const TAGLINE_TEXT := "Something is waiting beyond the stars"

@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _begin: Button = %BeginButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit: Button = %QuitButton
@onready var _version: Label = %VersionLabel
@onready var _settings_panel: SettingsPanel = %SettingsPanel

var _menu_buttons: Array[Button] = []


func _ready() -> void:
	theme = ThemeBuilder.get_theme()
	_title.text = TITLE_TEXT
	_subtitle.text = TAGLINE_TEXT
	_version.text = "v%s" % ProjectSettings.get_setting("application/config/version", "0.0.0")
	_quit.visible = not OS.has_feature("web")

	for button: Button in [_begin, _settings_button, _quit]:
		button.custom_minimum_size = UIConst.BUTTON_MIN_SIZE
		if button.visible:
			_menu_buttons.append(button)
	_wrap_focus()

	_begin.pressed.connect(func() -> void: SceneTransition.change_scene(UIConst.SCENE_PROFILES))
	_settings_button.pressed.connect(_open_settings)
	_quit.pressed.connect(func() -> void: get_tree().quit())
	_settings_panel.closed.connect(_on_settings_closed)

	_title.resized.connect(func() -> void: _title.pivot_offset = _title.size / 2.0)
	_start_title_pulse()
	_begin.grab_focus()


# Up from the first button goes to the last, and vice versa.
func _wrap_focus() -> void:
	var count := _menu_buttons.size()
	for i in count:
		var button := _menu_buttons[i]
		button.focus_neighbor_bottom = button.get_path_to(_menu_buttons[(i + 1) % count])
		button.focus_neighbor_top = button.get_path_to(_menu_buttons[(i - 1 + count) % count])


func _start_title_pulse() -> void:
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_apply_glow, 0.0, 1.0, UIConst.TITLE_PULSE_SECONDS)
	tween.tween_method(_apply_glow, 1.0, 0.0, UIConst.TITLE_PULSE_SECONDS)


func _apply_glow(amount: float) -> void:
	var glow := UIConst.COLOR_TITLE_GLOW
	glow.a = lerpf(UIConst.TITLE_GLOW_MIN_ALPHA, UIConst.TITLE_GLOW_MAX_ALPHA, amount)
	_title.add_theme_color_override("font_outline_color", glow)
	_title.scale = Vector2.ONE * lerpf(1.0, UIConst.TITLE_PULSE_SCALE, amount)


func _open_settings() -> void:
	# Focus neighbours are geometric, so keep menu buttons unfocusable behind the modal.
	for button in _menu_buttons:
		button.focus_mode = Control.FOCUS_NONE
	_settings_panel.open()


func _on_settings_closed() -> void:
	for button in _menu_buttons:
		button.focus_mode = Control.FOCUS_ALL
	_settings_button.grab_focus()
