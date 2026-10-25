class_name StoryProgress
extends RefCounted
## Saved story progress (user://progress.cfg): beats seen and best mission results.
## `path` can be pointed elsewhere (then reload_from_disk()) for tests.

const SECTION_SEEN := "seen"
const SECTION_MISSIONS := "missions"
const SECTION_STATE := "state"

const DEFAULT_PATH := "user://progress.cfg" # Used when no profile is active.

static var path := DEFAULT_PATH
static var _cfg: ConfigFile = null


static func reload_from_disk() -> void:
	_cfg = null


static func has_seen(beat_id: String) -> bool:
	return bool(_data().get_value(SECTION_SEEN, beat_id, false))


static func mark_seen(beat_id: String) -> void:
	_data().set_value(SECTION_SEEN, beat_id, true)
	save()


## Counts a play and keeps the best span, score and accuracy (whichever the task reports).
static func record_mission(mission_id: String, results: Dictionary) -> void:
	var cfg := _data()
	cfg.set_value(SECTION_MISSIONS, mission_id + "_plays", plays(mission_id) + 1)
	cfg.set_value(SECTION_MISSIONS, mission_id + "_best_span",
			maxi(best_span(mission_id), int(results.get("max_span", 0))))
	cfg.set_value(SECTION_MISSIONS, mission_id + "_best_score",
			maxi(best_score(mission_id), int(results.get("corsi_score", 0))))
	cfg.set_value(SECTION_MISSIONS, mission_id + "_best_dprime_x10",
			maxi(best_dprime_x10(mission_id), roundi(float(results.get("d_prime", 0.0)) * 10.0)))
	cfg.set_value(SECTION_MISSIONS, mission_id + "_best_accuracy",
			maxi(best_accuracy_percent(mission_id), roundi(float(results.get("accuracy", 0.0)) * 100.0)))
	save()


## A skipped game counts nothing as played; this only remembers that it was skipped.
static func record_skip(mission_id: String) -> void:
	_data().set_value(SECTION_MISSIONS, mission_id + "_skips", skips(mission_id) + 1)
	save()


static func skips(mission_id: String) -> int:
	return int(_data().get_value(SECTION_MISSIONS, mission_id + "_skips", 0))


static func plays(mission_id: String) -> int:
	return int(_data().get_value(SECTION_MISSIONS, mission_id + "_plays", 0))


static func best_span(mission_id: String) -> int:
	return int(_data().get_value(SECTION_MISSIONS, mission_id + "_best_span", 0))


static func best_score(mission_id: String) -> int:
	return int(_data().get_value(SECTION_MISSIONS, mission_id + "_best_score", 0))


static func best_accuracy_percent(mission_id: String) -> int:
	return int(_data().get_value(SECTION_MISSIONS, mission_id + "_best_accuracy", 0))


## Best d-prime times 10, as a whole number (so 3.5 is stored as 35).
static func best_dprime_x10(mission_id: String) -> int:
	return int(_data().get_value(SECTION_MISSIONS, mission_id + "_best_dprime_x10", 0))


## The mission the elders ask for next ("" if none chosen yet).
static func next_mission() -> String:
	return String(_data().get_value(SECTION_STATE, "next_mission", ""))


static func set_next_mission(mission_id: String) -> void:
	_data().set_value(SECTION_STATE, "next_mission", mission_id)
	save()


static func reset() -> void:
	_cfg = ConfigFile.new()
	save()


static func save() -> void:
	var err := _data().save(path)
	if err != OK:
		push_warning("Could not save progress (error %d)" % err)


static func _data() -> ConfigFile:
	if _cfg == null:
		_cfg = ConfigFile.new()
		_cfg.load(path) # Missing file on first run is fine.
	return _cfg
