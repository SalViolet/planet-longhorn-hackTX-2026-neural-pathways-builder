class_name ReportStats
extends RefCounted
## Small descriptive statistics for the progress report. Pure logic.

enum Trend { TOO_FEW, HIGHER, LOWER, SIMILAR }


static func mean(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v in values:
		total += v
	return total / values.size()


## Sample standard deviation (0 with fewer than two values).
static func sd(values: Array[float]) -> float:
	if values.size() < 2:
		return 0.0
	var m := mean(values)
	var total := 0.0
	for v in values:
		total += (v - m) * (v - m)
	return sqrt(total / (values.size() - 1))


## Compares the earlier half of the runs with the later half (oldest first).
static func trend(values: Array[float]) -> Trend:
	if values.size() < ReportConst.MIN_RUNS_FOR_TREND:
		return Trend.TOO_FEW
	var half := values.size() / 2
	var earlier := mean(values.slice(0, half))
	var later := mean(values.slice(values.size() - half))
	var change := later - earlier
	var scale := maxf(absf(earlier), 0.000001)
	if absf(change) / scale < ReportConst.TREND_CHANGE_FRACTION:
		return Trend.SIMILAR
	return Trend.HIGHER if change > 0.0 else Trend.LOWER


static func trend_text(t: Trend) -> String:
	match t:
		Trend.HIGHER:
			return "Higher in later runs"
		Trend.LOWER:
			return "Lower in later runs"
		Trend.SIMILAR:
			return "Similar across runs"
	return "Too few runs for a trend"


## Values of one metric across runs, oldest first, leaving out "not measurable" zeros.
static func series(runs: Array, key: String) -> Array[float]:
	var out: Array[float] = []
	for run: Dictionary in runs:
		var metrics: Dictionary = run["metrics"]
		if not metrics.has(key):
			continue
		var v := float(metrics[key])
		if v == 0.0 and key in ReportConst.ZERO_MEANS_NA:
			continue
		out.append(v)
	return out


## Runs grouped by calendar day: {"2026-03-01": [run, ...]}, days in order, runs oldest first.
static func group_by_day(runs: Array) -> Dictionary:
	var days := {}
	for run: Dictionary in runs:
		var day := String(run["time"]).substr(0, 10)
		if not days.has(day):
			days[day] = []
		(days[day] as Array).append(run)
	var keys := days.keys()
	keys.sort()
	var ordered := {}
	for key in keys:
		ordered[key] = days[key]
	return ordered
