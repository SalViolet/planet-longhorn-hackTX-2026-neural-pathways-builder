class_name DifficultyLadders
extends RefCounted
## What each difficulty level means for each task, and how to judge a finished run.
## Level 0 is the easiest. "start" is the level a new player begins on.
## Level values are merged over the task's default params.

const LADDERS := {
	"corsi": {
		"start": 0,
		"levels": [
			{"start_span": 2},
			{"start_span": 3},
			{"start_span": 4},
			{"start_span": 5},
		],
	},
	"go_nogo": {
		"start": 1, # Level 1 is the spec values.
		"levels": [
			{"stimulus_ms": 700, "isi_min_ms": 1200, "isi_max_ms": 1700, "go_probability": 0.70},
			{"stimulus_ms": 500, "isi_min_ms": 1000, "isi_max_ms": 1500, "go_probability": 0.75},
			{"stimulus_ms": 400, "isi_min_ms": 900, "isi_max_ms": 1300, "go_probability": 0.80},
			{"stimulus_ms": 350, "isi_min_ms": 800, "isi_max_ms": 1100, "go_probability": 0.80},
			{"stimulus_ms": 300, "isi_min_ms": 700, "isi_max_ms": 1000, "go_probability": 0.85},
		],
	},
	"dccs": {
		"start": 1,
		"levels": [
			{"cue_ms": 900, "response_timeout_ms": 5000},
			{"cue_ms": 700, "response_timeout_ms": 4000},
			{"cue_ms": 500, "response_timeout_ms": 3000},
			{"cue_ms": 350, "response_timeout_ms": 2200},
			{"cue_ms": 250, "response_timeout_ms": 1600},
		],
	},
	"cpt": {
		"start": 1, # Level 1 is the spec values.
		"levels": [
			{"trial_ms": 2200, "target_probability": 0.12},
			{"trial_ms": 2000, "target_probability": 0.10},
			{"trial_ms": 1800, "target_probability": 0.09},
			{"trial_ms": 1600, "target_probability": 0.08},
			{"trial_ms": 1400, "target_probability": 0.07},
		],
	},
}


static func has_mission(mission_id: String) -> bool:
	return LADDERS.has(mission_id)


static func start_level(mission_id: String) -> int:
	return int(LADDERS[mission_id]["start"])


static func max_level(mission_id: String) -> int:
	return (LADDERS[mission_id]["levels"] as Array).size() - 1


## The params for a level, plus "difficulty_level" so the run can report it back.
static func params_for(mission_id: String, level: int) -> Dictionary:
	if not LADDERS.has(mission_id):
		return {}
	var levels: Array = LADDERS[mission_id]["levels"]
	var params: Dictionary = levels[clampi(level, 0, levels.size() - 1)].duplicate()
	params["difficulty_level"] = clampi(level, 0, levels.size() - 1)
	return params


## Was the run too easy (SUCCESS), too hard (FAILURE) or about right (NEUTRAL)?
static func judge(mission_id: String, results: Dictionary, level: int) -> int:
	var good := Staircase.Outcome.SUCCESS
	var poor := Staircase.Outcome.FAILURE
	var neutral := Staircase.Outcome.NEUTRAL
	match mission_id:
		"corsi":
			var start_span := int(params_for(mission_id, level)["start_span"])
			var span := int(results.get("max_span", 0))
			if span >= start_span + AdaptiveConst.CORSI_SUCCESS_MARGIN:
				return good
			return poor if span < start_span else neutral
		"go_nogo":
			var accuracy := float(results.get("accuracy", 0.0))
			if accuracy >= AdaptiveConst.GONOGO_SUCCESS_ACCURACY:
				return good
			return poor if accuracy < AdaptiveConst.GONOGO_FAILURE_ACCURACY else neutral
		"dccs":
			var mixed := float(results.get("mixed_accuracy", 0.0))
			if mixed >= AdaptiveConst.DCCS_SUCCESS_ACCURACY:
				return good
			return poor if mixed < AdaptiveConst.DCCS_FAILURE_ACCURACY else neutral
		"cpt":
			var d_prime := float(results.get("d_prime", 0.0))
			if d_prime >= AdaptiveConst.CPT_SUCCESS_DPRIME:
				return good
			return poor if d_prime < AdaptiveConst.CPT_FAILURE_DPRIME else neutral
	return neutral


## How many levels the first finished run moves the player from the level it was played at:
## +2 for a great run, +1 for a good one, 0 for in between, -1 for a poor one, -2 for a very poor one.
static func placement_delta(mission_id: String, results: Dictionary, level: int) -> int:
	var outcome := judge(mission_id, results, level)
	var great := AdaptiveConst.PLACEMENT_GREAT_STEP
	var good := AdaptiveConst.PLACEMENT_GOOD_STEP
	match mission_id:
		"corsi":
			var start_span := int(params_for(mission_id, level)["start_span"])
			if outcome == Staircase.Outcome.SUCCESS:
				return great if int(results.get("max_span", 0)) >= start_span + AdaptiveConst.CORSI_GREAT_MARGIN else good
			return -good if outcome == Staircase.Outcome.FAILURE else 0
		"go_nogo":
			return _tiered(outcome, float(results.get("accuracy", 0.0)),
					AdaptiveConst.GONOGO_GREAT_ACCURACY, AdaptiveConst.GONOGO_VERY_POOR_ACCURACY)
		"dccs":
			return _tiered(outcome, float(results.get("mixed_accuracy", 0.0)),
					AdaptiveConst.DCCS_GREAT_ACCURACY, AdaptiveConst.DCCS_VERY_POOR_ACCURACY)
		"cpt":
			return _tiered(outcome, float(results.get("d_prime", 0.0)),
					AdaptiveConst.CPT_GREAT_DPRIME, AdaptiveConst.CPT_VERY_POOR_DPRIME)
	return 0


## The level a player is placed at after their first finished run.
static func placement_level(mission_id: String, results: Dictionary, level: int) -> int:
	return clampi(level + placement_delta(mission_id, results, level), 0, max_level(mission_id))


static func _tiered(outcome: int, value: float, great_at: float, very_poor_below: float) -> int:
	var great := AdaptiveConst.PLACEMENT_GREAT_STEP
	var good := AdaptiveConst.PLACEMENT_GOOD_STEP
	if outcome == Staircase.Outcome.SUCCESS:
		return great if value >= great_at else good
	if outcome == Staircase.Outcome.FAILURE:
		return -great if value < very_poor_below else -good
	return 0
