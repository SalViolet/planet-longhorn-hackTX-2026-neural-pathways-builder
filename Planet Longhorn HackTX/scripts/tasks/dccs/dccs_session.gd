class_name DccsSession
extends RefCounted
## One DCCS run: pre-switch (colour), post-switch (shape), then mixed. Pure logic.
##
## Definitions:
## - Conflict trial: colour and shape point to different pens.
## - Switch trial: the rule differs from the trial before. Repeat trial: same rule.
## - Perseverative error: a wrong answer on a switch trial that matches what the
##   previous rule would have required.
## - Switch cost: mixed repeat -> mixed switch (RT up, accuracy down).
## - Mixing cost: single-rule blocks (pre + post) -> mixed repeat.
## RT figures use correct answers that were not flagged anticipatory.

const BLOCKS: Array[String] = ["pre", "post", "mixed"]

var _trials: Array[Dictionary] = []
var _next := 0
var _current: Dictionary = {}
var _records: Array[Dictionary] = []
var _anticipatory := 0
var _invalid := 0


func _init(params: Dictionary, rng: RandomNumberGenerator) -> void:
	var counts := {"pre": int(params["pre_trials"]), "post": int(params["post_trials"]), "mixed": int(params["mixed_trials"])}
	var previous := -1
	var number := 1
	for block in BLOCKS:
		var rules: Array[int] = []
		if block == "pre":
			rules.resize(counts[block])
			rules.fill(DccsStimulus.Rule.COLOR)
		elif block == "post":
			rules.resize(counts[block])
			rules.fill(DccsStimulus.Rule.SHAPE)
		else:
			rules = DccsSequence.rules(counts[block], float(params["switch_probability"]), previous, rng)
		var conflict_probability := float(params["conflict_probability"]) if block == "mixed" else 1.0
		var items := DccsSequence.stimuli(counts[block], conflict_probability, rng)
		for i in counts[block]:
			var rule: int = rules[i]
			var hue: int = items[i]["hue"]
			var shape: int = items[i]["shape"]
			_trials.append({
				"number": number,
				"block": block,
				"rule": rule,
				"previous_rule": previous,
				"switch": previous != -1 and previous != rule,
				"hue": hue,
				"shape": shape,
				"conflict": DccsStimulus.is_conflict(hue, shape),
				"correct_side": DccsStimulus.correct_side(hue, shape, rule),
			})
			previous = rule
			number += 1


func total_trials() -> int:
	return _trials.size()


## Trials already played, all blocks included.
func completed_trials() -> int:
	return _next


func has_next() -> bool:
	return _next < _trials.size()


## The block name if the next trial is the first of its block, otherwise "".
func next_block_start() -> String:
	if not has_next():
		return ""
	var block: String = _trials[_next]["block"]
	if _trials[_next]["block"] != "" and (_next == 0 or _trials[_next - 1]["block"] != block):
		return block
	return ""


func next_trial() -> Dictionary:
	_current = _trials[_next]
	_next += 1
	return _current


## side is a DccsStimulus.Pen, or -1 for no response. rt_ms < 0 means no response.
## valid = false leaves the trial out of the metrics. Returns {correct, outcome}.
func record(side: int, rt_ms: int, valid: bool = true) -> Dictionary:
	if not valid:
		_invalid += 1
		return {"correct": false, "outcome": "invalid"}
	var omission := side < 0
	var correct: bool = side == _current["correct_side"]
	var perseverative := false
	if not omission and not correct and _current["switch"]:
		perseverative = side == DccsStimulus.correct_side(_current["hue"], _current["shape"], _current["previous_rule"])
	var fast := not omission and TrialLogger.is_anticipatory(rt_ms)
	if fast:
		_anticipatory += 1
	_records.append({
		"block": _current["block"],
		"switch": _current["switch"],
		"correct": correct,
		"omission": omission,
		"perseverative": perseverative,
		"rt_ms": float(rt_ms) if correct and not fast else -1.0,
	})
	return {"correct": correct, "outcome": "omission" if omission else ("correct" if correct else "error")}


func get_results() -> Dictionary:
	var out := {}
	for block in BLOCKS:
		var rows := _rows(func(r: Dictionary) -> bool: return r["block"] == block)
		out[block + "_accuracy"] = _accuracy(rows)
		out[block + "_rt_ms"] = _mean_rt(rows)
	var mixed_switch := _rows(func(r: Dictionary) -> bool: return r["block"] == "mixed" and r["switch"])
	var mixed_repeat := _rows(func(r: Dictionary) -> bool: return r["block"] == "mixed" and not r["switch"])
	var single := _rows(func(r: Dictionary) -> bool: return r["block"] != "mixed")
	out["mixed_switch_accuracy"] = _accuracy(mixed_switch)
	out["mixed_repeat_accuracy"] = _accuracy(mixed_repeat)
	out["mixed_switch_rt_ms"] = _mean_rt(mixed_switch)
	out["mixed_repeat_rt_ms"] = _mean_rt(mixed_repeat)
	var has_switch_rt: bool = out["mixed_switch_rt_ms"] > 0.0 and out["mixed_repeat_rt_ms"] > 0.0
	var has_mixing_rt: bool = out["mixed_repeat_rt_ms"] > 0.0 and _mean_rt(single) > 0.0
	out["switch_cost_rt_ms"] = out["mixed_switch_rt_ms"] - out["mixed_repeat_rt_ms"] if has_switch_rt else 0.0
	out["switch_cost_accuracy"] = out["mixed_repeat_accuracy"] - out["mixed_switch_accuracy"] if not mixed_switch.is_empty() and not mixed_repeat.is_empty() else 0.0
	out["mixing_cost_rt_ms"] = out["mixed_repeat_rt_ms"] - _mean_rt(single) if has_mixing_rt else 0.0
	out["mixing_cost_accuracy"] = _accuracy(single) - out["mixed_repeat_accuracy"] if not single.is_empty() and not mixed_repeat.is_empty() else 0.0
	var all_rows := _records
	var correct := 0
	var omissions := 0
	var perseverative := 0
	for r in all_rows:
		correct += 1 if r["correct"] else 0
		omissions += 1 if r["omission"] else 0
		perseverative += 1 if r["perseverative"] else 0
	out["accuracy"] = float(correct) / all_rows.size() if not all_rows.is_empty() else 0.0
	out["total_trials"] = all_rows.size()
	out["omissions"] = omissions
	out["perseverative_errors"] = perseverative
	out["anticipatory_responses"] = _anticipatory
	out["invalid_trials"] = _invalid
	return out


func _rows(keep: Callable) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for r in _records:
		if keep.call(r):
			rows.append(r)
	return rows


static func _accuracy(rows: Array[Dictionary]) -> float:
	if rows.is_empty():
		return 0.0
	var correct := 0
	for r in rows:
		correct += 1 if r["correct"] else 0
	return float(correct) / rows.size()


static func _mean_rt(rows: Array[Dictionary]) -> float:
	var rts: Array[float] = []
	for r in rows:
		if r["rt_ms"] >= 0.0:
			rts.append(r["rt_ms"])
	return SignalDetection.mean(rts)
