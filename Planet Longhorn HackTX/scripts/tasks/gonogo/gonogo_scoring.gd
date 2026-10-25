class_name GoNoGoScoring
extends RefCounted
## Go/No-Go scoring helpers. Pure functions. The statistics live in SignalDetection.

enum Outcome { HIT, OMISSION, COMMISSION, CORRECT_REJECTION }


static func classify(is_go: bool, responded: bool) -> Outcome:
	if is_go:
		return Outcome.HIT if responded else Outcome.OMISSION
	return Outcome.COMMISSION if responded else Outcome.CORRECT_REJECTION


static func is_correct(outcome: Outcome) -> bool:
	return outcome == Outcome.HIT or outcome == Outcome.CORRECT_REJECTION


static func d_prime(hits: int, go_trials: int, commissions: int, nogo_trials: int) -> float:
	return SignalDetection.d_prime(hits, go_trials, commissions, nogo_trials)


static func inv_norm_cdf(p: float) -> float:
	return SignalDetection.inv_norm_cdf(p)


static func mean(values: Array[float]) -> float:
	return SignalDetection.mean(values)


static func sd(values: Array[float]) -> float:
	return SignalDetection.sd(values)
