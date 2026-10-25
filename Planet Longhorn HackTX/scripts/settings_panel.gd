class_name SettingsPanel
extends Control
## Modal settings dialog. Emits `closed` so the opener can restore focus.

signal closed

@onready var _dimmer: ColorRect = %Dimmer
@onready var _panel: PanelContainer = %Panel
@onready var _slider: HSlider = %VolumeSlider
@onready var _close: Button = %CloseButton

var _music: CheckButton


func _ready() -> void:
	_dimmer.color = UIConst.COLOR_DIMMER
	_panel.custom_minimum_size = UIConst.SETTINGS_PANEL_MIN_SIZE
	_slider.custom_minimum_size.x = UIConst.SLIDER_MIN_WIDTH
	_slider.value_changed.connect(Settings.set_master_volume)
	_music = CheckButton.new()
	_music.text = "Music"
	_close.get_parent().add_child(_music)
	_close.get_parent().move_child(_music, _close.get_index())
	_music.toggled.connect(_on_music_toggled)
	_close.pressed.connect(close)


func open() -> void:
	_slider.set_value_no_signal(Settings.master_volume)
	_music.set_pressed_no_signal(Settings.music_on)
	visible = true
	_slider.grab_focus()


func close() -> void:
	if not visible:
		return
	Settings.save()
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _on_music_toggled(enabled: bool) -> void:
	Settings.set_music_on(enabled)
	Settings.save()
