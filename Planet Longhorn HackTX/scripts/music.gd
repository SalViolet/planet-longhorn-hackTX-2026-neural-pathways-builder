extends Node
## Autoload "Music": one looping background track that keeps playing across scenes. It is much
## quieter during the four tasks so it never competes with the trials (Corsi's single drum tone
## in particular), and the player can turn it off in Settings. The volume glides by frame time,
## which never touches trial timing.

var _player: AudioStreamPlayer
var _current_db := UIConst.MUSIC_SILENT_DB


## The volume (decibels) the music should be heading to.
static func target_db(in_task: bool, music_on: bool) -> float:
	if not music_on:
		return UIConst.MUSIC_SILENT_DB
	return UIConst.MUSIC_TASK_DB if in_task else UIConst.MUSIC_DB


func _ready() -> void:
	var stream := load(UIConst.MUSIC_PATH) as AudioStreamMP3
	if stream == null:
		push_warning("Music file missing: %s" % UIConst.MUSIC_PATH)
		set_process(false)
		return
	stream.loop = true
	_player = AudioStreamPlayer.new()
	_player.stream = stream
	_player.volume_db = _current_db
	add_child(_player)


func _process(delta: float) -> void:
	var in_task := get_tree().current_scene is TaskModule
	var target := target_db(in_task, Settings.music_on)
	_current_db = move_toward(_current_db, target, UIConst.MUSIC_FADE_DB_PER_SECOND * delta)
	_player.volume_db = _current_db
	var audible := _current_db > UIConst.MUSIC_SILENT_DB
	if audible and not _player.playing:
		_player.play()
	elif not audible and _player.playing:
		_player.stop()
