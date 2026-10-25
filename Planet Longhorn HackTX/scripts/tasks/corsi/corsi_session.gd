class_name CorsiSession
extends RefCounted
## Span progression for one Corsi run. Pure logic, no nodes or timing.
## Each length gets `trials_per_span` trials. If at least one is correct the
## length goes up by one; if all are wrong, or the max span is done, the run ends.

var _rng: RandomNumberGenerator
var _block_count: int
var _max_span: int
var _trials_per_span: int

var _span: int
var _trial_in_span := 0
var _correct_in_span := 0
var _trial_number := 0
var _finished := false
var _aborted_trials := 0

var _sequence: Array[int] = []
var _max_span_reached := 0 # Longest length with at least one correct trial.
var _correct_trials := 0
var _trial_accuracy: Array[float] = []
var _trial_spans: Array[int] = []


func _init(start_span: int, max_span: int, trials_per_span: int, block_count: int,
		rng: RandomNumberGenerator) -> void:
	_span = start_span
	_max_span = max_span
	_trials_per_span = trials_per_span
	_block_count = block_count
	_rng = rng


func is_finished() -> bool:
	return _finished


func current_span() -> int:
	return _span


## Share (0-1) of the longest possible run that is done, counted in scored trials, so the bar
## moves after every trial. A run can end early (all wrong in a length), then it jumps to full.
func progress(first_span: int) -> float:
	var lengths := _max_span - clampi(first_span, 1, _max_span) + 1
	return clampf(float(_trial_accuracy.size()) / float(lengths * _trials_per_span), 0.0, 1.0)


## 1-based number of the trial in progress (after next_sequence()).
func current_trial_number() -> int:
	return _trial_number


func next_sequence() -> Array[int]:
	assert(not _finished, "next_sequence() called after the run ended")
	var previous := _sequence
	_sequence = CorsiSequence.generate(_span, _block_count, previous, _rng)
	_trial_number += 1
	return _sequence.duplicate()


## Scores the response to the current sequence and advances the span rules.
func submit_response(response: Array[int]) -> bool:
	var correct := CorsiScoring.is_correct(_sequence, response)
	_trial_spans.append(_span)
	_trial_accuracy.append(CorsiScoring.position_accuracy(_sequence, response))
	if correct:
		_correct_trials += 1
		_correct_in_span += 1
	_trial_in_span += 1
	if _trial_in_span >= _trials_per_span:
		_end_span()
	return correct


## The window lost focus or the player left mid-trial. The trial is not scored and the
## span does not change, so the same length is tried again with a fresh sequence.
func abort_trial() -> void:
	_aborted_trials += 1


func get_results() -> Dictionary:
	var total := 0.0
	for a in _trial_accuracy:
		total += a
	return {
		"max_span": _max_span_reached,
		"correct_trials": _correct_trials,
		"corsi_score": CorsiScoring.corsi_score(_max_span_reached, _correct_trials),
		"total_trials": _trial_accuracy.size(),
		"invalid_trials": _aborted_trials,
		"trial_accuracy": _trial_accuracy.duplicate(),
		"trial_spans": _trial_spans.duplicate(),
		"mean_accuracy": total / float(_trial_accuracy.size()) if not _trial_accuracy.is_empty() else 0.0,
	}


func _end_span() -> void:
	if _correct_in_span >= 1:
		_max_span_reached = _span
		if _span >= _max_span:
			_finished = true
		else:
			_span += 1
	else:
		_finished = true
	_trial_in_span = 0
	_correct_in_span = 0
