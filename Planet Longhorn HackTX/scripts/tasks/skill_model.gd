class_name SkillModel
extends RefCounted
## A 0-1 skill estimate per domain (memory, inhibition, flexibility, attention),
## built only from the player's own results. Each run blends into the estimate:
## the first run replaces the prior, later runs count for at least MIN_LEARNING_RATE.

var _estimates: Dictionary = {}
var _plays: Dictionary = {}


func get_skill(domain: String) -> float:
	return float(_estimates.get(domain, AdaptiveConst.PRIOR_SKILL))


func plays(domain: String) -> int:
	return int(_plays.get(domain, 0))


func has_played(domain: String) -> bool:
	return plays(domain) > 0


func record_results(mission_id: String, results: Dictionary) -> void:
	var domain := AdaptiveConst.domain_of(mission_id)
	if domain != "":
		update(domain, TaskScores.score(mission_id, results))


func update(domain: String, score: float) -> void:
	var n := plays(domain)
	var rate := maxf(AdaptiveConst.MIN_LEARNING_RATE, 1.0 / (n + 1.0))
	_estimates[domain] = lerpf(get_skill(domain), clampf(score, 0.0, 1.0), rate)
	_plays[domain] = n + 1


func to_dict() -> Dictionary:
	return {"estimates": _estimates.duplicate(), "plays": _plays.duplicate()}


func load_dict(data: Dictionary) -> void:
	_estimates = (data.get("estimates", {}) as Dictionary).duplicate()
	_plays = (data.get("plays", {}) as Dictionary).duplicate()
