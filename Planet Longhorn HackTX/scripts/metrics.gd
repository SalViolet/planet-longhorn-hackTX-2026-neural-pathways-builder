extends Node
## Autoload "Metrics": for every number shown on a results screen, a running total over
## all finished runs and the value from the last run. Kept in memory only (resets when the
## game closes). Read with `Metrics.total("corsi", "max_span")` and `Metrics.last(...)`.

# Per mission: the results keys that appear on its results screen.
const TRACKED := {
	"corsi": ["max_span", "correct_trials", "total_trials", "corsi_score", "mean_accuracy"],
	"go_nogo": ["hits", "go_trials", "omissions", "commissions", "nogo_trials",
			"correct_rejections", "accuracy", "rt_mean_ms", "d_prime"],
	"dccs": ["accuracy", "pre_accuracy", "pre_rt_ms", "post_accuracy", "post_rt_ms",
			"mixed_accuracy", "mixed_rt_ms", "switch_cost_rt_ms", "mixing_cost_rt_ms",
			"perseverative_errors"],
	"cpt": ["hits", "targets", "omissions", "commissions", "d_prime", "criterion",
			"rt_mean_ms", "rt_sd_ms", "rt_cv"],
}
# A value of exactly 0 for these means "not measurable this run" (the screen shows n/a).
const ZERO_MEANS_NA: Array[String] = [
	"rt_mean_ms", "rt_sd_ms", "rt_cv", "pre_rt_ms", "post_rt_ms", "mixed_rt_ms",
	"switch_cost_rt_ms", "mixing_cost_rt_ms",
]

var _totals: Dictionary = {} # "mission.metric" -> float, the sum over all recorded runs
var _last: Dictionary = {} # "mission.metric" -> float, the most recent run
var _runs: Dictionary = {} # "mission.metric" -> int, how many runs contributed


## Adds a finished run's results. Metrics missing from `results` are ignored.
func record(mission_id: String, results: Dictionary) -> void:
	if not TRACKED.has(mission_id):
		return
	for metric: String in TRACKED[mission_id]:
		if not results.has(metric):
			continue
		var value := float(results[metric])
		if value == 0.0 and metric in ZERO_MEANS_NA:
			continue
		var key := _key(mission_id, metric)
		_totals[key] = float(_totals.get(key, 0.0)) + value
		_last[key] = value
		_runs[key] = int(_runs.get(key, 0)) + 1


## Sum of this metric over all recorded runs (0 if never recorded).
func total(mission_id: String, metric: String) -> float:
	return float(_totals.get(_key(mission_id, metric), 0.0))


## Value from the most recent run (0 if never recorded).
func last(mission_id: String, metric: String) -> float:
	return float(_last.get(_key(mission_id, metric), 0.0))


## How many runs added to this metric (use it to turn a total into an average).
func run_count(mission_id: String, metric: String) -> int:
	return int(_runs.get(_key(mission_id, metric), 0))


func clear() -> void:
	_totals.clear()
	_last.clear()
	_runs.clear()


func _key(mission_id: String, metric: String) -> String:
	return "%s.%s" % [mission_id, metric]
