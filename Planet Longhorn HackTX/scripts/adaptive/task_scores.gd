class_name TaskScores
extends RefCounted
## Turns a finished run into one 0-1 score for its skill domain. Pure functions.


static func score(mission_id: String, results: Dictionary) -> float:
	match mission_id:
		"corsi":
			return clamp01(float(results.get("max_span", 0)) / CorsiConst.MAX_SPAN)
		"go_nogo", "cpt":
			return clamp01(float(results.get("d_prime", 0.0)) / AdaptiveConst.SCORE_DPRIME_MAX)
		"dccs":
			return clamp01(float(results.get("mixed_accuracy", results.get("accuracy", 0.0))))
	return 0.0


static func clamp01(value: float) -> float:
	return clampf(value, 0.0, 1.0)
