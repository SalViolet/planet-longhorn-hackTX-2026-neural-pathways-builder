class_name GoNoGoSession
extends RefCounted
## One Go/No-Go run: the practice trials, then the main trials. Pure logic.
## Practice and invalid trials are kept out of the metrics.

var _trials: Array[Dictionary] = []
var _practice_count: int
var _next := 0
var _current: Dictionary = {}

var _hits := 0
var _omissions := 0
var _commissions := 0
var _correct_rejections := 0
var _hit_rts: Array[float] = [] # Hits that were not flagged anticipatory.
var _anticipatory := 0
var _invalid := 0


func _init(params: Dictionary, rng: RandomNumberGenerator) -> void:
	_practice_count = int(params["practice_trials"])
	var number := 1
	for block in [[_practice_count, true], [int(params["trials"]), false]]:
		var order := GoNoGoSequence.generate(int(block[0]), float(params["go_probability"]),
				int(params["max_consecutive_nogo"]), rng)
		for is_go in order:
			_trials.append({
				"number": number,
				"is_go": is_go,
				"practice": block[1],
				"isi_ms": GoNoGoSequence.isi_ms(int(params["isi_min_ms"]), int(params["isi_max_ms"]), rng),
			})
			number += 1


func total_trials() -> int:
	return _trials.size()


## Leaves out any practice trials not yet played. Does nothing once the main trials began.
func skip_practice() -> void:
	_next = maxi(_next, _practice_count)


## Trials already played, practice included.
func completed_trials() -> int:
	return _next


func has_next() -> bool:
	return _next < _trials.size()


## True when the next trial is the first main trial and there was practice before it.
func next_is_first_main_trial() -> bool:
	return _practice_count > 0 and _next == _practice_count and has_next()


func next_trial() -> Dictionary:
	_current = _trials[_next]
	_next += 1
	return _current


## Scores the current trial. rt_ms < 0 means no response. valid = false leaves the
## trial out of the metrics (window lost focus, player left). Returns outcome and correct.
func record(responded: bool, rt_ms: int, valid: bool = true) -> Dictionary:
	var outcome := GoNoGoScoring.classify(_current["is_go"], responded)
	if not valid:
		_invalid += 1
		return {"outcome": outcome, "correct": false}
	if _current["practice"]:
		return {"outcome": outcome, "correct": GoNoGoScoring.is_correct(outcome)}
	match outcome:
		GoNoGoScoring.Outcome.HIT:
			_hits += 1
			if TrialLogger.is_anticipatory(rt_ms):
				_anticipatory += 1
			else:
				_hit_rts.append(rt_ms)
		GoNoGoScoring.Outcome.OMISSION:
			_omissions += 1
		GoNoGoScoring.Outcome.COMMISSION:
			_commissions += 1
			if TrialLogger.is_anticipatory(rt_ms):
				_anticipatory += 1
		GoNoGoScoring.Outcome.CORRECT_REJECTION:
			_correct_rejections += 1
	return {"outcome": outcome, "correct": GoNoGoScoring.is_correct(outcome)}


func get_results() -> Dictionary:
	var go_trials := _hits + _omissions
	var nogo_trials := _commissions + _correct_rejections
	var scored := go_trials + nogo_trials
	return {
		"hits": _hits,
		"omissions": _omissions,
		"commissions": _commissions,
		"correct_rejections": _correct_rejections,
		"go_trials": go_trials,
		"nogo_trials": nogo_trials,
		"total_trials": scored,
		"accuracy": float(_hits + _correct_rejections) / scored if scored > 0 else 0.0,
		"hit_rate": float(_hits) / go_trials if go_trials > 0 else 0.0,
		"commission_rate": float(_commissions) / nogo_trials if nogo_trials > 0 else 0.0,
		"rt_mean_ms": GoNoGoScoring.mean(_hit_rts),
		"rt_sd_ms": GoNoGoScoring.sd(_hit_rts),
		"d_prime": GoNoGoScoring.d_prime(_hits, go_trials, _commissions, nogo_trials),
		"anticipatory_responses": _anticipatory,
		"invalid_trials": _invalid,
	}
