class_name AdaptiveEngine
extends RefCounted
## The adaptive layer, used through static calls: one SkillModel and one Staircase per
## mission, saved to user://adaptive.cfg. `path` can be pointed elsewhere for tests.

static var path := AdaptiveConst.SKILL_PATH
static var _skill: SkillModel = null
static var _stairs: Dictionary = {}


static func reload_from_disk() -> void:
	_skill = null
	_stairs = {}


static func skill() -> SkillModel:
	_ensure_loaded()
	return _skill


static func level(mission_id: String) -> int:
	if not DifficultyLadders.has_mission(mission_id):
		return -1
	_ensure_loaded()
	return _stair(mission_id).level


## True once a finished run has placed the player on this mission's ladder.
static func is_placed(mission_id: String) -> bool:
	if not DifficultyLadders.has_mission(mission_id):
		return false
	_ensure_loaded()
	return _stair(mission_id).placed


## The line shown on a results screen: the current level, and whether this run moved it ("" for dev runs).
static func level_text(mission_id: String, results: Dictionary) -> String:
	var played_at := int(results.get("difficulty_level", -1))
	if played_at < 0 or not DifficultyLadders.has_mission(mission_id):
		return ""
	var now := level(mission_id)
	if now > played_at:
		return "Level up! You are now level %d" % (now + 1)
	if now < played_at:
		return "Next time will be a little easier (level %d)" % (now + 1)
	return "Level %d" % (now + 1)


## Params for the next run of a mission (empty for a mission with no ladder).
static func params_for(mission_id: String) -> Dictionary:
	if not DifficultyLadders.has_mission(mission_id):
		return {}
	return DifficultyLadders.params_for(mission_id, level(mission_id))


## Folds a finished run into the skill estimate and the staircase, then saves.
## Runs without a difficulty level (dev modes) or with too many invalid trials are ignored.
static func record_run(mission_id: String, results: Dictionary) -> void:
	if not DifficultyLadders.has_mission(mission_id):
		return
	var run_level := int(results.get("difficulty_level", -1))
	if run_level < 0 or _too_many_invalid(results):
		return
	_ensure_loaded()
	_skill.record_results(mission_id, results)
	var stair := _stair(mission_id)
	if stair.placed:
		stair.update(DifficultyLadders.judge(mission_id, results, run_level))
	else:
		# The first finished run places the player from how it went; after that the staircase moves one step at a time.
		stair.place(DifficultyLadders.placement_level(mission_id, results, run_level))
	save()


## Forgets all skill estimates and difficulty levels, and saves the empty state.
static func reset() -> void:
	_skill = SkillModel.new()
	_stairs = {}
	for mission_id: String in DifficultyLadders.LADDERS:
		_stairs[mission_id] = Staircase.new(DifficultyLadders.start_level(mission_id), DifficultyLadders.max_level(mission_id))
	save()


static func save() -> void:
	_ensure_loaded()
	var cfg := ConfigFile.new()
	var data := _skill.to_dict()
	for domain: String in data["estimates"]:
		cfg.set_value("skill", domain + "_estimate", data["estimates"][domain])
	for domain: String in data["plays"]:
		cfg.set_value("skill", domain + "_plays", data["plays"][domain])
	for mission_id: String in _stairs:
		var stair_data: Dictionary = (_stairs[mission_id] as Staircase).to_dict()
		for key: String in stair_data:
			cfg.set_value("staircase", "%s_%s" % [mission_id, key], stair_data[key])
	var err := cfg.save(path)
	if err != OK:
		push_warning("Could not save adaptive data (error %d)" % err)


static func _ensure_loaded() -> void:
	if _skill != null:
		return
	_skill = SkillModel.new()
	var cfg := ConfigFile.new()
	var found := cfg.load(path) == OK
	var estimates := {}
	var plays := {}
	for domain: String in AdaptiveConst.MISSION_DOMAINS.values():
		if found and cfg.has_section_key("skill", domain + "_estimate"):
			estimates[domain] = cfg.get_value("skill", domain + "_estimate")
			plays[domain] = cfg.get_value("skill", domain + "_plays", 0)
	_skill.load_dict({"estimates": estimates, "plays": plays})
	for mission_id: String in DifficultyLadders.LADDERS:
		var stair := Staircase.new(DifficultyLadders.start_level(mission_id), DifficultyLadders.max_level(mission_id))
		if found:
			var data := {}
			for key in ["level", "placed", "success_streak", "failure_streak"]:
				var full_key := "%s_%s" % [mission_id, key]
				if cfg.has_section_key("staircase", full_key):
					data[key] = cfg.get_value("staircase", full_key)
			stair.load_dict(data)
		_stairs[mission_id] = stair


static func _stair(mission_id: String) -> Staircase:
	return _stairs[mission_id]


static func _too_many_invalid(results: Dictionary) -> bool:
	var invalid := int(results.get("invalid_trials", 0))
	var total := int(results.get("total_trials", 0)) + invalid
	return total > 0 and float(invalid) / total > AdaptiveConst.MAX_INVALID_SHARE
