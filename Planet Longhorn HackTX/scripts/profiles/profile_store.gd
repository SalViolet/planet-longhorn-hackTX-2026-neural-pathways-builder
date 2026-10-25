class_name ProfileStore
extends RefCounted
## The list of player profiles (profiles.cfg) and the active one. Each profile has its own
## folder, named by a random code, holding its story progress, adaptive data and trial logs.
## The nickname lives only in profiles.cfg. Nothing in a profile's folder contains it.
##
## With no active profile ("guest", for example when a scene is run on its own from the
## editor) the old shared save paths are used.
## `index_path` and `root_dir` can be pointed elsewhere for tests.

static var index_path := ProfileConst.INDEX_PATH
static var root_dir := ProfileConst.ROOT_DIR

static var _profiles: Array[Dictionary] = []
static var _loaded := false
static var _active_id := ""
static var _last_id := ""


static func reload_from_disk() -> void:
	_loaded = false
	_ensure_loaded()


static func list() -> Array[Dictionary]:
	_ensure_loaded()
	var out: Array[Dictionary] = []
	out.assign(_profiles)
	return out


static func count() -> int:
	_ensure_loaded()
	return _profiles.size()


static func get_profile(id: String) -> Dictionary:
	_ensure_loaded()
	for p in _profiles:
		if p["id"] == id:
			return p.duplicate()
	return {}


## Returns {ok, error, profile}. On failure `error` is the message to show the player.
static func create(raw_name: String, color_index: int, rng: RandomNumberGenerator = null) -> Dictionary:
	_ensure_loaded()
	var names := PackedStringArray()
	for p in _profiles:
		names.append(p["name"])
	var error := ProfileRules.validate(raw_name, names)
	if error != "":
		return {"ok": false, "error": error}
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var id := _new_id(rng)
	var profile := {
		"id": id,
		"name": ProfileRules.clean_name(raw_name),
		"color": clampi(color_index, 0, ProfileConst.COLORS.size() - 1),
	}
	_profiles.append(profile)
	_save()
	return {"ok": true, "error": "", "profile": profile.duplicate()}


## Removes the profile and everything saved for it.
static func delete(id: String) -> void:
	_ensure_loaded()
	if not ProfileRules.is_valid_id(id):
		return
	for i in _profiles.size():
		if _profiles[i]["id"] == id:
			_profiles.remove_at(i)
			break
	if _active_id == id:
		deactivate()
	if _last_id == id:
		_last_id = ""
	_remove_dir(data_dir(id))
	_save()


## Makes this profile the one whose progress, difficulty and logs are used.
static func activate(id: String) -> bool:
	_ensure_loaded()
	if get_profile(id).is_empty():
		return false
	_active_id = id
	_last_id = id
	var dir := data_dir(id)
	DirAccess.make_dir_recursive_absolute(dir)
	StoryProgress.path = dir.path_join("progress.cfg")
	StoryProgress.reload_from_disk()
	AdaptiveEngine.path = dir.path_join("adaptive.cfg")
	AdaptiveEngine.reload_from_disk()
	TrialLogger.log_dir = dir.path_join("trial_logs")
	RunHistory.path = dir.path_join(ReportConst.HISTORY_FILE)
	PointsStore.path = dir.path_join(PointsConst.FILE_NAME)
	PointsStore.reload_from_disk()
	_save()
	return true


## Back to the shared "guest" save paths.
static func deactivate() -> void:
	_active_id = ""
	StoryProgress.path = StoryProgress.DEFAULT_PATH
	StoryProgress.reload_from_disk()
	AdaptiveEngine.path = AdaptiveConst.SKILL_PATH
	AdaptiveEngine.reload_from_disk()
	TrialLogger.log_dir = TrialLogger.DEFAULT_LOG_DIR
	RunHistory.path = ReportConst.GUEST_HISTORY_PATH
	PointsStore.path = PointsConst.DEFAULT_PATH
	PointsStore.reload_from_disk()


static func active_id() -> String:
	return _active_id


static func active_profile() -> Dictionary:
	return get_profile(_active_id) if _active_id != "" else {}


## The profile used most recently (highlighted first on the "Who's playing?" screen).
static func last_id() -> String:
	_ensure_loaded()
	return _last_id


static func data_dir(id: String) -> String:
	return root_dir.path_join(id)


static func _new_id(rng: RandomNumberGenerator) -> String:
	var id := ""
	while id == "" or not get_profile(id).is_empty():
		id = "%08x" % (rng.randi() & 0xFFFFFFFF)
	return id


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_profiles = []
	_last_id = ""
	var cfg := ConfigFile.new()
	if cfg.load(index_path) != OK:
		return # First run: no profiles yet.
	for entry: Variant in cfg.get_value("data", "profiles", []):
		if entry is Dictionary and ProfileRules.is_valid_id(String(entry.get("id", ""))) and String(entry.get("name", "")) != "":
			_profiles.append({
				"id": String(entry["id"]),
				"name": String(entry["name"]),
				"color": clampi(int(entry.get("color", 0)), 0, ProfileConst.COLORS.size() - 1),
			})
	_last_id = String(cfg.get_value("state", "last_id", ""))
	if get_profile(_last_id).is_empty():
		_last_id = ""


static func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("data", "profiles", _profiles)
	cfg.set_value("state", "last_id", _last_id)
	var err := cfg.save(index_path)
	if err != OK:
		push_warning("Could not save profiles (error %d)" % err)


# Only ever called with a folder inside root_dir (ids are checked before this is reached).
static func _remove_dir(path: String) -> void:
	if not path.begins_with(root_dir) or not DirAccess.dir_exists_absolute(path):
		return
	for sub in DirAccess.get_directories_at(path):
		_remove_dir(path.path_join(sub))
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)
