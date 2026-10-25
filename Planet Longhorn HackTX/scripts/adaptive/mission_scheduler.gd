class_name MissionScheduler
extends RefCounted
## Picks the next mission: weighted toward the weakest domains, with some randomness.
## Pure logic: pass in the RNG so tests can seed it.


## Weight of one mission: low skill, never played, and not just played all raise it.
static func weight(mission_id: String, skill: SkillModel, last_id: String) -> float:
	var domain := AdaptiveConst.domain_of(mission_id)
	var w := (1.0 - skill.get_skill(domain)) + AdaptiveConst.WEIGHT_FLOOR
	if not skill.has_played(domain):
		w += AdaptiveConst.NOVELTY_BONUS
	if mission_id == last_id:
		w *= AdaptiveConst.REPEAT_PENALTY
	return w


static func pick(candidates: Array[String], skill: SkillModel, last_id: String,
		rng: RandomNumberGenerator) -> String:
	if candidates.is_empty():
		return ""
	var weights: Array[float] = []
	var total := 0.0
	for id in candidates:
		var w := weight(id, skill, last_id)
		weights.append(w)
		total += w
	var roll := rng.randf() * total
	for i in candidates.size():
		roll -= weights[i]
		if roll <= 0.0:
			return candidates[i]
	return candidates[candidates.size() - 1]
