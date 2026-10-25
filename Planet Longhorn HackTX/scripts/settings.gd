extends Node
## Autoload "Settings": persisted user preferences (user://settings.cfg).

const PATH := "user://settings.cfg"
const SECTION_AUDIO := "audio"
const SECTION_DISPLAY := "display"
const KEY_MASTER_VOLUME := "master_volume"
const KEY_FULLSCREEN := "fullscreen"
const KEY_MUSIC_ON := "music_on"

var master_volume: float = UIConst.DEFAULT_MASTER_VOLUME
var fullscreen: bool = false
var music_on: bool = UIConst.DEFAULT_MUSIC_ON


func _ready() -> void:
	load_settings()
	apply()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return # First run: keep defaults.
	master_volume = clampf(float(cfg.get_value(SECTION_AUDIO, KEY_MASTER_VOLUME, master_volume)), 0.0, 1.0)
	fullscreen = bool(cfg.get_value(SECTION_DISPLAY, KEY_FULLSCREEN, fullscreen))
	music_on = bool(cfg.get_value(SECTION_AUDIO, KEY_MUSIC_ON, music_on))


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION_AUDIO, KEY_MASTER_VOLUME, master_volume)
	cfg.set_value(SECTION_AUDIO, KEY_MUSIC_ON, music_on)
	cfg.set_value(SECTION_DISPLAY, KEY_FULLSCREEN, fullscreen)
	var err := cfg.save(PATH)
	if err != OK:
		push_warning("Could not save settings (error %d)" % err)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_volume()


func set_music_on(enabled: bool) -> void:
	music_on = enabled


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_fullscreen()


## Reads the real window state, since the user can also toggle it with OS shortcuts.
func is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
			or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func apply() -> void:
	_apply_volume()
	# Browsers only allow fullscreen from a user gesture, so don't try at startup.
	if not OS.has_feature("web"):
		_apply_fullscreen()


func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, is_zero_approx(master_volume))
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.0001)))


func _apply_fullscreen() -> void:
	DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
