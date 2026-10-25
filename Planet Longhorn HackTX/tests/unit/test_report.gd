extends GutTest
## The progress report: statistics, history file, and the HTML it produces.

var _dir := "user://test_report"


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(_dir)
	RunHistory.path = _dir.path_join("history.json")
	if FileAccess.file_exists(RunHistory.path):
		DirAccess.remove_absolute(RunHistory.path)


func after_each() -> void:
	if FileAccess.file_exists(RunHistory.path):
		DirAccess.remove_absolute(RunHistory.path)
	DirAccess.remove_absolute(_dir)
	RunHistory.path = ReportConst.GUEST_HISTORY_PATH


func _run(mission: String, time: String, metrics: Dictionary) -> Dictionary:
	return {"mission": mission, "time": time, "metrics": metrics, "bins": []}


func test_mean_and_sd() -> void:
	var v: Array[float] = [2.0, 4.0, 6.0]
	assert_almost_eq(ReportStats.mean(v), 4.0, 0.0001)
	assert_almost_eq(ReportStats.sd(v), 2.0, 0.0001)
	assert_eq(ReportStats.sd([1.0] as Array[float]), 0.0)


func test_trend_needs_enough_runs_and_detects_direction() -> void:
	assert_eq(ReportStats.trend([1.0, 2.0] as Array[float]), ReportStats.Trend.TOO_FEW)
	assert_eq(ReportStats.trend([1.0, 1.0, 2.0, 2.0] as Array[float]), ReportStats.Trend.HIGHER)
	assert_eq(ReportStats.trend([2.0, 2.0, 1.0, 1.0] as Array[float]), ReportStats.Trend.LOWER)
	assert_eq(ReportStats.trend([5.0, 5.0, 5.0, 5.1] as Array[float]), ReportStats.Trend.SIMILAR)


func test_series_skips_not_measurable_zero_times() -> void:
	var runs := [_run("cpt", "2026-01-01T10:00:00", {"rt_mean_ms": 400.0, "hits": 0}),
			_run("cpt", "2026-01-02T10:00:00", {"rt_mean_ms": 0.0, "hits": 0})]
	assert_eq(ReportStats.series(runs, "rt_mean_ms").size(), 1)
	assert_eq(ReportStats.series(runs, "hits").size(), 2)


func test_history_round_trip_keeps_numbers_only() -> void:
	RunHistory.record("go_nogo", {"accuracy": 0.9, "hits": 20, "trial_accuracy": [0.5], "bins": []}, "2026-01-01T10:00:00")
	RunHistory.record("go_nogo", {"accuracy": 0.8}, "2026-01-02T10:00:00")
	var runs := RunHistory.load_all()
	assert_eq(runs.size(), 2)
	assert_eq(runs[0]["mission"], "go_nogo")
	assert_true((runs[0]["metrics"] as Dictionary).has("accuracy"))
	assert_false((runs[0]["metrics"] as Dictionary).has("trial_accuracy"))


func test_history_missing_file_is_empty() -> void:
	assert_eq(RunHistory.load_all().size(), 0)


func _data(runs: Array) -> Dictionary:
	return {"name": "Sam <b>", "generated": "2026-02-01T09:00:00", "runs": runs,
			"levels": {"corsi": {"level": 1, "max": 3}}, "skips": {"cpt": 1}}


func test_report_has_the_expected_sections_and_escapes_the_name() -> void:
	var runs := [
		_run("corsi", "2026-01-01T10:00:00", {"max_span": 4, "difficulty_level": 0, "total_trials": 6}),
		_run("corsi", "2026-01-03T10:00:00", {"max_span": 5, "difficulty_level": 1, "total_trials": 8}),
	]
	var html := ReportBuilder.build(_data(runs))
	for heading in ["Identifying details", "Purpose and limits of this report", "Tasks given",
			"Data quality", "Results by task", "Overview by domain", "Notes for the reviewing professional", "Glossary"]:
		assert_true(html.contains(heading), heading)
	assert_true(html.contains("not a diagnosis"))
	assert_true(html.contains("Sam &lt;b&gt;"))
	assert_false(html.contains("Sam <b>"))
	assert_true(html.contains("2026-01-01 to 2026-01-03"))
	assert_true(html.contains("Longest span"))


func test_report_with_no_runs_still_builds() -> void:
	var html := ReportBuilder.build(_data([]))
	assert_true(html.contains("Not played yet."))
	assert_true(html.contains("No runs recorded"))


func test_report_has_no_norm_scores_or_diagnosis_claims() -> void:
	var html := ReportBuilder.build(_data([_run("corsi", "2026-01-01T10:00:00", {"max_span": 4})])).to_lower()
	for word in ["<th>percentile", "<th>standard score", "t-score", "impaired", "deficit", "abnormal"]:
		assert_false(html.contains(word), word)


func test_format_value() -> void:
	assert_eq(ReportBuilder.format_value(0.856, "percent"), "86%")
	assert_eq(ReportBuilder.format_value(412.4, "ms"), "412 ms")
	assert_eq(ReportBuilder.format_value(1.234, "score"), "1.23")
	assert_eq(ReportBuilder.format_value(5.0, "count"), "5")


func test_group_by_day_orders_days_and_keeps_run_order() -> void:
	var runs := [_run("corsi", "2026-01-02T10:00:00", {"max_span": 4}),
			_run("cpt", "2026-01-01T09:00:00", {"hits": 3}),
			_run("corsi", "2026-01-02T11:00:00", {"max_span": 6})]
	var days := ReportStats.group_by_day(runs.duplicate())
	assert_eq(days.keys(), ["2026-01-01", "2026-01-02"])
	assert_eq((days["2026-01-02"] as Array).size(), 2)


func test_daily_csv_averages_the_day() -> void:
	var runs := [_run("corsi", "2026-01-02T10:00:00", {"max_span": 4}),
			_run("corsi", "2026-01-02T11:00:00", {"max_span": 6})]
	var csv := ReportBuilder.daily_csv(runs)
	assert_true(csv.begins_with("date,task,runs_that_day,metric,day_average"))
	assert_true(csv.contains("2026-01-02,corsi,2,max_span,5"))


func test_report_has_day_by_day_sections() -> void:
	var runs := [_run("corsi", "2026-01-01T10:00:00", {"max_span": 4, "total_trials": 6}),
			_run("go_nogo", "2026-01-01T10:10:00", {"accuracy": 0.8, "total_trials": 60}),
			_run("corsi", "2026-01-02T10:00:00", {"max_span": 5, "total_trials": 8})]
	var html := ReportBuilder.build(_data(runs))
	assert_true(html.contains("Day by day"))
	assert_true(html.contains("Day average"))


func test_points_tally_per_day() -> void:
	var runs := [_run("corsi", "2026-01-01T10:00:00", {"max_span": 7}),
			_run("corsi", "2026-01-01T10:05:00", {"max_span": 7}),
			_run("dccs", "2026-01-02T10:00:00", {"mixed_accuracy": 0.5})]
	var tally := PointsRules.tally(runs)
	assert_eq(tally["2026-01-01"]["points"], 150) # Great run once; the repeat earns nothing.
	assert_eq(tally["2026-01-02"]["points"], 100)
