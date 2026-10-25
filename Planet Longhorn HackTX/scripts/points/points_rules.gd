class_name PointsRules
extends RefCounted
## Which points a finished task earns. Pure logic.
##
## Each required task earns POINTS_PER_TASK the first time it is finished on a given day, plus
## an extra for a "good" or "great" run (the same bands the story uses), so finishing always
## earns at least the base. Finishing the last one of the day also earns DAILY_BONUS (once a day).


## `done_today` lists the required tasks already finished today (before this one).
## `band` is "great", "good" or "tried". Returns {task_points, extra, bonus, repeat}, where
## task_points already includes the extra.
static func award(done_today: Array, mission_id: String, band: String = "tried") -> Dictionary:
	if mission_id not in PointsConst.REQUIRED_TASKS or mission_id in done_today:
		return {"task_points": 0, "extra": 0, "bonus": 0, "repeat": mission_id in done_today}
	var after := done_today.size() + 1
	var bonus := PointsConst.DAILY_BONUS if after >= PointsConst.REQUIRED_TASKS.size() else 0
	var extra := extra_for(band)
	return {"task_points": PointsConst.POINTS_PER_TASK + extra, "extra": extra, "bonus": bonus, "repeat": false}


static func extra_for(band: String) -> int:
	match band:
		"great":
			return PointsConst.EXTRA_GREAT
		"good":
			return PointsConst.EXTRA_GOOD
	return 0


static func max_per_day() -> int:
	return PointsConst.REQUIRED_TASKS.size() * (PointsConst.POINTS_PER_TASK + PointsConst.EXTRA_GREAT) + PointsConst.DAILY_BONUS


## Replays a run history (oldest first) through the points rules. Returns
## {date: {"done": Array of tasks, "points": int}}, the points each day would have earned.
static func tally(runs: Array) -> Dictionary:
	var by_day := {}
	for run: Dictionary in runs:
		var day := String(run["time"]).substr(0, 10)
		if not by_day.has(day):
			by_day[day] = {"done": [], "points": 0}
		var entry: Dictionary = by_day[day]
		var tagged: Dictionary = (run["metrics"] as Dictionary).duplicate()
		tagged["mission_id"] = run["mission"]
		var result := award(entry["done"], String(run["mission"]), StoryData.performance_band(tagged))
		if int(result["task_points"]) > 0:
			(entry["done"] as Array).append(run["mission"])
			entry["points"] = int(entry["points"]) + int(result["task_points"]) + int(result["bonus"])
	return by_day
