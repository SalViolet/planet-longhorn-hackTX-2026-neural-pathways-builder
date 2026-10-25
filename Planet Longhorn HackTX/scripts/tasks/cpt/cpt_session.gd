class_name CptSession
extends RefCounted
## One CPT run. Pure logic: the glyph order, scoring and the metrics, including the
## results in time bins. RT figures use hits that were not flagged anticipatory.

var _glyphs: Array[int]
var _rows: Array[Dictionary] = []
var _anticipatory := 0
var _invalid := 0


func _init(trial_count: int, target_probability: float, rng: RandomNumberGenerator) -> void:
	_glyphs = CptSequence.generate(trial_count, target_probability, rng)


func trial_count() -> int:
	return _glyphs.size()


func glyph_at(index: int) -> int:
	return _glyphs[index]


func is_target(index: int) -> bool:
	return _glyphs[index] == CptConst.TARGET_GLYPH


## rt_ms < 0 means no response. valid = false leaves the trial out of the metrics.
## Returns {outcome, correct}; outcome is a GoNoGoScoring.Outcome (hit, omission, ...).
func record(index: int, responded: bool, rt_ms: int, valid: bool = true) -> Dictionary:
	var outcome := GoNoGoScoring.classify(is_target(index), responded)
	if not valid:
		_invalid += 1
		return {"outcome": outcome, "correct": false}
	var fast := responded and TrialLogger.is_anticipatory(rt_ms)
	if fast:
		_anticipatory += 1
	_rows.append({
		"bin": mini(CptConst.TIME_BINS - 1, index * CptConst.TIME_BINS / _glyphs.size()),
		"outcome": outcome,
		"rt_ms": float(rt_ms) if outcome == GoNoGoScoring.Outcome.HIT and not fast else -1.0,
	})
	return {"outcome": outcome, "correct": GoNoGoScoring.is_correct(outcome)}


func get_results() -> Dictionary:
	var totals := _count(_rows)
	var rts := _hit_rts(_rows)
	var targets: int = totals["hits"] + totals["omissions"]
	var non_targets: int = totals["commissions"] + totals["correct_rejections"]
	var bins: Array[Dictionary] = []
	for b in CptConst.TIME_BINS:
		var rows: Array[Dictionary] = []
		for r in _rows:
			if r["bin"] == b:
				rows.append(r)
		var c := _count(rows)
		var bin_targets: int = c["hits"] + c["omissions"]
		bins.append({
			"hits": c["hits"],
			"omissions": c["omissions"],
			"commissions": c["commissions"],
			"targets": bin_targets,
			"hit_rate": float(c["hits"]) / bin_targets if bin_targets > 0 else 0.0,
			"rt_mean_ms": SignalDetection.mean(_hit_rts(rows)),
		})
	return {
		"hits": totals["hits"],
		"omissions": totals["omissions"],
		"commissions": totals["commissions"],
		"correct_rejections": totals["correct_rejections"],
		"targets": targets,
		"total_trials": _rows.size(),
		"hit_rate": float(totals["hits"]) / targets if targets > 0 else 0.0,
		"commission_rate": float(totals["commissions"]) / non_targets if non_targets > 0 else 0.0,
		"d_prime": SignalDetection.d_prime(totals["hits"], targets, totals["commissions"], non_targets),
		"criterion": SignalDetection.criterion(totals["hits"], targets, totals["commissions"], non_targets),
		"rt_mean_ms": SignalDetection.mean(rts),
		"rt_sd_ms": SignalDetection.sd(rts),
		"rt_cv": SignalDetection.cv(rts),
		"bins": bins,
		"anticipatory_responses": _anticipatory,
		"invalid_trials": _invalid,
	}


static func _count(rows: Array[Dictionary]) -> Dictionary:
	var c := {"hits": 0, "omissions": 0, "commissions": 0, "correct_rejections": 0}
	for r in rows:
		match r["outcome"]:
			GoNoGoScoring.Outcome.HIT:
				c["hits"] += 1
			GoNoGoScoring.Outcome.OMISSION:
				c["omissions"] += 1
			GoNoGoScoring.Outcome.COMMISSION:
				c["commissions"] += 1
			GoNoGoScoring.Outcome.CORRECT_REJECTION:
				c["correct_rejections"] += 1
	return c


static func _hit_rts(rows: Array[Dictionary]) -> Array[float]:
	var rts: Array[float] = []
	for r in rows:
		if r["rt_ms"] >= 0.0:
			rts.append(r["rt_ms"])
	return rts
