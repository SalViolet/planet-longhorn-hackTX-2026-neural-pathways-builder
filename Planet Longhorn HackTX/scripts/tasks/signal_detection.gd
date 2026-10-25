class_name SignalDetection
extends RefCounted
## Signal-detection maths shared by the Go/No-Go and CPT tasks. Pure functions.

# Acklam's rational approximation of the inverse normal CDF (error about 1e-9).
const _A: Array[float] = [-39.69683028665376, 220.9460984245205, -275.9285104469687,
		138.357751867269, -30.66479806614716, 2.506628277459239]
const _B: Array[float] = [-54.47609879822406, 161.5858368580409, -155.6989798598866,
		66.80131188771972, -13.28068155288572]
const _C: Array[float] = [-0.007784894002430293, -0.3223964580411365, -2.400758277161838,
		-2.549732539343734, 4.374664141464968, 2.938163982698783]
const _D: Array[float] = [0.007784695709041462, 0.3224671290700398, 2.445134137142996,
		3.754408661907416]
const _P_LOW := 0.02425


## d-prime with the log-linear correction: add 0.5 to each count and 1 to each total,
## so perfect or zero rates don't give infinite values.
static func d_prime(hits: int, signal_trials: int, false_alarms: int, noise_trials: int) -> float:
	return inv_norm_cdf(_hit_rate(hits, signal_trials)) - inv_norm_cdf(_false_alarm_rate(false_alarms, noise_trials))


## Response criterion c (log-linear corrected). Positive = cautious, negative = trigger-happy.
static func criterion(hits: int, signal_trials: int, false_alarms: int, noise_trials: int) -> float:
	return -0.5 * (inv_norm_cdf(_hit_rate(hits, signal_trials)) + inv_norm_cdf(_false_alarm_rate(false_alarms, noise_trials)))


static func inv_norm_cdf(p: float) -> float:
	if p <= 0.0 or p >= 1.0:
		return INF if p >= 1.0 else -INF
	if p < _P_LOW:
		return _tail(sqrt(-2.0 * log(p)))
	if p > 1.0 - _P_LOW:
		return -_tail(sqrt(-2.0 * log(1.0 - p)))
	var q := p - 0.5
	var r := q * q
	return (((((_A[0] * r + _A[1]) * r + _A[2]) * r + _A[3]) * r + _A[4]) * r + _A[5]) * q \
			/ (((((_B[0] * r + _B[1]) * r + _B[2]) * r + _B[3]) * r + _B[4]) * r + 1.0)


static func mean(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v in values:
		total += v
	return total / values.size()


## Sample standard deviation (n - 1). Zero when there are fewer than two values.
static func sd(values: Array[float]) -> float:
	if values.size() < 2:
		return 0.0
	var m := mean(values)
	var squares := 0.0
	for v in values:
		squares += (v - m) * (v - m)
	return sqrt(squares / (values.size() - 1))


## Coefficient of variation (sd / mean). Zero when the mean is zero.
static func cv(values: Array[float]) -> float:
	var m := mean(values)
	return sd(values) / m if m > 0.0 else 0.0


static func _hit_rate(hits: int, signal_trials: int) -> float:
	return (hits + 0.5) / (signal_trials + 1.0)


static func _false_alarm_rate(false_alarms: int, noise_trials: int) -> float:
	return (false_alarms + 0.5) / (noise_trials + 1.0)


static func _tail(q: float) -> float:
	return (((((_C[0] * q + _C[1]) * q + _C[2]) * q + _C[3]) * q + _C[4]) * q + _C[5]) \
			/ ((((_D[0] * q + _D[1]) * q + _D[2]) * q + _D[3]) * q + 1.0)
