class_name SampleData
extends RefCounted
## Made-up play history so the progress report and points can be tried without playing for
## days. It always goes into its own player called "Sample", never into a real player.

const PLAYER_NAME := "Sample"
const PLAYER_COLOR := 2
const DAYS := 14
const SECONDS_PER_DAY := 86400
const PLAY_HOUR_SECONDS := 16 * 3600
const TODAY_TASKS: Array[String] = ["corsi", "go_nogo"] # Leaves two for the demo to earn.
const SKIP_CHANCE := 0.2 # Chance that a task is not played on an earlier day.
const GO_TRIALS := 45
const NOGO_TRIALS := 15
const CPT_TARGETS := 15
const CPT_TRIALS := 150
const CPT_BINS := 5
const DCCS_TRIALS := 56


## All runs for `days` days ending on the day of `now_unix`, oldest first. Performance rises a
## little over the period, with noise. Deterministic for a given seed.
static func build_runs(now_unix: int, days: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var runs: Array[Dictionary] = []
	for d in days:
		var progress := float(d) / maxf(days - 1, 1)
		var unix := now_unix - (days - 1 - d) * SECONDS_PER_DAY
		var day_start := unix - unix % SECONDS_PER_DAY
		var played := PointsConst.REQUIRED_TASKS.duplicate()
		if d == days - 1:
			played = TODAY_TASKS.duplicate()
		else:
			played = played.filter(func(_t: String) -> bool: return rng.randf() > SKIP_CHANCE)
		var minute := 0
		for task: String in played:
			var stamp := Time.get_datetime_string_from_unix_time(day_start + PLAY_HOUR_SECONDS + minute * 60)
			runs.append({"mission": task, "time": stamp, "metrics": _metrics(task, progress, rng),
					"bins": _bins(progress, rng) if task == "cpt" else []})
			minute += 7
	return runs


## What the points file would hold after these runs: {total, day, done}.
static func points_state(runs: Array) -> Dictionary:
	var by_day := PointsRules.tally(runs)
	var total := 0
	var last_day := ""
	for day: String in by_day:
		total += int(by_day[day]["points"])
		last_day = maxs(last_day, day)
	var done: Array = by_day[last_day]["done"] if last_day != "" else []
	return {"total": total, "day": last_day, "done": done}


## Creates (or refreshes) the "Sample" player with a history. Returns {ok, error, id}.
static func install(rng: RandomNumberGenerator = null) -> Dictionary:
	var local_rng := rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		local_rng.randomize()
	var id := ""
	for profile in ProfileStore.list():
		if profile["name"] == PLAYER_NAME:
			id = profile["id"]
	if id == "":
		var made := ProfileStore.create(PLAYER_NAME, PLAYER_COLOR, local_rng)
		if not made["ok"]:
			return {"ok": false, "error": String(made["error"]), "id": ""}
		id = made["profile"]["id"]
	var dir := ProfileStore.data_dir(id)
	DirAccess.make_dir_recursive_absolute(dir)
	var runs := build_runs(int(Time.get_unix_time_from_system()), DAYS, local_rng)
	RunHistory.write(runs, dir.path_join(ReportConst.HISTORY_FILE))
	var state := points_state(runs)
	PointsStore.write_state(dir.path_join(PointsConst.FILE_NAME), int(state["total"]), String(state["day"]), state["done"])
	return {"ok": true, "error": "", "id": id}


static func maxs(a: String, b: String) -> String:
	return b if b > a else a


static func _level(rng: RandomNumberGenerator, progress: float, top: int) -> int:
	return clampi(roundi(progress * top + rng.randf_range(-0.6, 0.6)), 0, top)


static func _noise(rng: RandomNumberGenerator, spread: float) -> float:
	return rng.randf_range(-spread, spread)


static func _metrics(task: String, progress: float, rng: RandomNumberGenerator) -> Dictionary:
	var skill := clampf(0.55 + 0.3 * progress + _noise(rng, 0.08), 0.2, 0.98)
	var m := {"invalid_trials": 1 if rng.randf() < 0.15 else 0, "anticipatory_responses": rng.randi_range(0, 2)}
	match task:
		"corsi":
			var span := clampi(roundi(3.0 + 4.0 * skill + _noise(rng, 0.6)), 2, 9)
			var correct := span * 2 - 2 + rng.randi_range(0, 1)
			m.merge({"max_span": span, "correct_trials": correct, "total_trials": span * 2 - 1,
					"corsi_score": span * correct, "mean_accuracy": clampf(0.55 + 0.4 * skill, 0.0, 1.0),
					"difficulty_level": _level(rng, progress, 3)})
		"go_nogo":
			var hits := clampi(roundi(GO_TRIALS * (0.8 + 0.18 * skill)), 0, GO_TRIALS)
			var fas := clampi(roundi(NOGO_TRIALS * (0.55 - 0.45 * skill)), 0, NOGO_TRIALS)
			m.merge({"hits": hits, "omissions": GO_TRIALS - hits, "commissions": fas,
					"correct_rejections": NOGO_TRIALS - fas, "go_trials": GO_TRIALS, "nogo_trials": NOGO_TRIALS,
					"total_trials": GO_TRIALS + NOGO_TRIALS,
					"accuracy": float(hits + NOGO_TRIALS - fas) / (GO_TRIALS + NOGO_TRIALS),
					"hit_rate": float(hits) / GO_TRIALS, "commission_rate": float(fas) / NOGO_TRIALS,
					"rt_mean_ms": 520.0 - 110.0 * skill + _noise(rng, 15.0), "rt_sd_ms": 130.0 - 50.0 * skill,
					"d_prime": SignalDetection.d_prime(hits, GO_TRIALS, fas, NOGO_TRIALS),
					"difficulty_level": _level(rng, progress, 4)})
		"dccs":
			var mixed := clampf(0.6 + 0.35 * skill + _noise(rng, 0.04), 0.0, 1.0)
			m.merge({"accuracy": clampf(0.7 + 0.28 * skill, 0.0, 1.0), "pre_accuracy": clampf(0.92 + _noise(rng, 0.06), 0.0, 1.0),
					"post_accuracy": clampf(0.8 + 0.15 * skill, 0.0, 1.0), "mixed_accuracy": mixed,
					"pre_rt_ms": 900.0 - 200.0 * skill, "post_rt_ms": 950.0 - 200.0 * skill,
					"mixed_rt_ms": 1250.0 - 300.0 * skill, "switch_cost_rt_ms": 260.0 - 140.0 * skill + _noise(rng, 30.0),
					"mixing_cost_rt_ms": 320.0 - 150.0 * skill + _noise(rng, 30.0),
					"perseverative_errors": roundi(7.0 - 6.0 * skill + _noise(rng, 1.0)),
					"total_trials": DCCS_TRIALS, "difficulty_level": _level(rng, progress, 4)})
		"cpt":
			var hits := clampi(roundi(CPT_TARGETS * (0.7 + 0.28 * skill)), 0, CPT_TARGETS)
			var non_targets := CPT_TRIALS - CPT_TARGETS
			var fas := clampi(roundi(8.0 - 7.0 * skill + _noise(rng, 1.0)), 0, non_targets)
			m.merge({"hits": hits, "omissions": CPT_TARGETS - hits, "commissions": fas,
					"correct_rejections": non_targets - fas, "targets": CPT_TARGETS, "total_trials": CPT_TRIALS,
					"hit_rate": float(hits) / CPT_TARGETS, "commission_rate": float(fas) / non_targets,
					"d_prime": SignalDetection.d_prime(hits, CPT_TARGETS, fas, non_targets),
					"criterion": SignalDetection.criterion(hits, CPT_TARGETS, fas, non_targets),
					"rt_mean_ms": 560.0 - 90.0 * skill, "rt_sd_ms": 150.0 - 50.0 * skill,
					"rt_cv": (150.0 - 50.0 * skill) / (560.0 - 90.0 * skill),
					"difficulty_level": _level(rng, progress, 4)})
	return m


## Hit rate per time block: starts high and drifts down a little, as a steady watch often does.
static func _bins(progress: float, rng: RandomNumberGenerator) -> Array:
	var bins: Array = []
	for i in CPT_BINS:
		bins.append(clampf(0.95 - 0.04 * i + 0.04 * progress + _noise(rng, 0.05), 0.0, 1.0))
	return bins
