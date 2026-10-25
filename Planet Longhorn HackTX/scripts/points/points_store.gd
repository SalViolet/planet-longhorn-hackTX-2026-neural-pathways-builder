class_name PointsStore
extends RefCounted
## Saved points (points.cfg in the active profile's folder): the running total, and which
## required tasks were finished on which day. `path` can be pointed elsewhere for tests.

const SECTION := "points"

static var path := PointsConst.DEFAULT_PATH
static var _cfg: ConfigFile = null


static func reload_from_disk() -> void:
	_cfg = null


static func today() -> String:
	return Time.get_date_string_from_system()


static func total() -> int:
	return int(_data().get_value(SECTION, "total", 0))


## Required tasks finished on `day` (default today).
static func done_on(day: String = "") -> Array:
	var d := day if day != "" else today()
	if String(_data().get_value(SECTION, "day", "")) != d:
		return []
	return _data().get_value(SECTION, "done", [])


## Call when a task run finishes. Saves and returns {task_points, extra, bonus, repeat, total, done_count}.
static func record_completion(mission_id: String, day: String = "", band: String = "tried") -> Dictionary:
	var d := day if day != "" else today()
	var done := done_on(d).duplicate()
	var award := PointsRules.award(done, mission_id, band)
	if int(award["task_points"]) > 0:
		done.append(mission_id)
	var new_total := total() + int(award["task_points"]) + int(award["bonus"])
	_data().set_value(SECTION, "total", new_total)
	_data().set_value(SECTION, "day", d)
	_data().set_value(SECTION, "done", done)
	save()
	award["total"] = new_total
	award["done_count"] = done.size()
	return award


## Writes a points file directly, for sample data. Does not touch the active profile.
static func write_state(to_path: String, total_points: int, day: String, done: Array) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "total", total_points)
	cfg.set_value(SECTION, "day", day)
	cfg.set_value(SECTION, "done", done)
	cfg.save(to_path)


static func save() -> void:
	var err := _data().save(path)
	if err != OK:
		push_warning("Could not save points (error %d)" % err)


static func _data() -> ConfigFile:
	if _cfg == null:
		_cfg = ConfigFile.new()
		_cfg.load(path)
	return _cfg
