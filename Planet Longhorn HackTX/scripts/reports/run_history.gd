class_name RunHistory
extends RefCounted
## One saved line per finished run (numbers only), kept in the active profile's folder so a
## report can cover all play, not just this session. ProfileStore points `path` at the profile.

static var path := ReportConst.GUEST_HISTORY_PATH


## Saves the numeric results of a finished run. Lists (per-trial, time bins) are not kept,
## except the CPT hit rate per time block.
static func record(mission_id: String, results: Dictionary, time_text: String) -> void:
	var metrics := {}
	for key: String in results:
		var value: Variant = results[key]
		if value is int or value is float:
			metrics[key] = value
	var bins: Array = []
	for bin: Variant in results.get("bins", []):
		if bin is Dictionary and int((bin as Dictionary).get("targets", 0)) > 0:
			bins.append(float((bin as Dictionary)["hit_rate"]))
		else:
			bins.append(null)
	var runs := load_all()
	runs.append({"mission": mission_id, "time": time_text, "metrics": metrics, "bins": bins})
	write(runs, path)


## Writes a whole history to `to_path` (also used for sample data).
static func write(runs: Array, to_path: String) -> void:
	var file := FileAccess.open(to_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write %s (error %d)" % [to_path, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(runs))


static func load_all() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not FileAccess.file_exists(path):
		return out
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Array:
		for entry: Variant in parsed:
			if entry is Dictionary:
				out.append(entry)
	return out
