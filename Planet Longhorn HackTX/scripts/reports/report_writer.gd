class_name ReportWriter
extends RefCounted
## Collects the active profile's data, builds the report and saves it into the profile's
## "reports" folder. Nothing leaves the device; the player or a parent opens the file.


## Returns {ok, path, error}. `path` is the full path on disk when ok.
static func generate() -> Dictionary:
	var runs: Array = RunHistory.load_all()
	if runs.is_empty():
		return {"ok": false, "path": "", "error": "Play at least one game first, then the report has something to show."}
	var levels := {}
	var skips := {}
	for task: Dictionary in ReportConst.TASKS:
		var id: String = task["id"]
		if DifficultyLadders.has_mission(id):
			levels[id] = {"level": AdaptiveEngine.level(id), "max": DifficultyLadders.max_level(id)}
		skips[id] = StoryProgress.skips(id)
	var profile := ProfileStore.active_profile()
	var now := Time.get_datetime_string_from_system()
	var html := ReportBuilder.build({
		"name": String(profile.get("name", "Guest")),
		"generated": now,
		"runs": runs,
		"levels": levels,
		"skips": skips,
	})
	var dir := RunHistory.path.get_base_dir().path_join(ReportConst.REPORT_DIR_NAME)
	DirAccess.make_dir_recursive_absolute(dir)
	var path := "%s/report_%s.html" % [dir, now.replace(":", "-")]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "path": "", "error": "Could not save the report (error %d)." % FileAccess.get_open_error()}
	file.store_string(html)
	file.close()
	var csv_path := "%s/daily_metrics_%s.csv" % [dir, now.replace(":", "-")]
	var csv := FileAccess.open(csv_path, FileAccess.WRITE)
	if csv != null:
		csv.store_string(ReportBuilder.daily_csv(runs))
	return {"ok": true, "path": ProjectSettings.globalize_path(path), "csv_path": ProjectSettings.globalize_path(csv_path), "error": ""}
