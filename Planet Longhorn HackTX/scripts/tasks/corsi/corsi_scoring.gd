class_name CorsiScoring
extends RefCounted
## Scoring helpers. Pure functions.


static func is_correct(sequence: Array[int], response: Array[int]) -> bool:
	return sequence == response


## Share of positions where the tapped block matches the shown one (0-1).
static func position_accuracy(sequence: Array[int], response: Array[int]) -> float:
	if sequence.is_empty():
		return 0.0
	var hits := 0
	for i in mini(sequence.size(), response.size()):
		if sequence[i] == response[i]:
			hits += 1
	return float(hits) / float(sequence.size())


static func corsi_score(max_span: int, correct_trials: int) -> int:
	return max_span * correct_trials
