extends GutTest
## Daily points and the sample data.

var _path := "user://test_points.cfg"


func before_each() -> void:
	PointsStore.path = _path
	PointsStore.reload_from_disk()
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(_path)
	PointsStore.reload_from_disk()


func after_each() -> void:
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(_path)
	PointsStore.path = PointsConst.DEFAULT_PATH
	PointsStore.reload_from_disk()


func test_each_required_task_earns_100_once_per_day() -> void:
	var first := PointsStore.record_completion("corsi", "2026-05-01")
	assert_eq(first["task_points"], 100)
	assert_eq(first["bonus"], 0)
	var again := PointsStore.record_completion("corsi", "2026-05-01")
	assert_eq(again["task_points"], 0)
	assert_true(again["repeat"])
	assert_eq(PointsStore.total(), 100)


func test_finishing_all_four_adds_the_500_bonus_once() -> void:
	for id in ["corsi", "go_nogo", "dccs"]:
		assert_eq(PointsStore.record_completion(id, "2026-05-01")["bonus"], 0)
	var last := PointsStore.record_completion("cpt", "2026-05-01")
	assert_eq(last["bonus"], 500)
	assert_eq(PointsStore.total(), 900)
	assert_eq(PointsStore.record_completion("cpt", "2026-05-01")["bonus"], 0)
	assert_eq(PointsStore.total(), 900)


func test_a_new_day_starts_fresh_but_keeps_the_total() -> void:
	PointsStore.record_completion("corsi", "2026-05-01")
	assert_eq(PointsStore.done_on("2026-05-02").size(), 0)
	assert_eq(PointsStore.record_completion("corsi", "2026-05-02")["task_points"], 100)
	assert_eq(PointsStore.total(), 200)


func test_unknown_task_earns_nothing() -> void:
	assert_eq(PointsRules.award([], "nope")["task_points"], 0)


func test_points_survive_a_reload() -> void:
	PointsStore.record_completion("dccs", "2026-05-01")
	PointsStore.reload_from_disk()
	assert_eq(PointsStore.total(), 100)
	assert_true("dccs" in PointsStore.done_on("2026-05-01"))


func test_max_per_day_is_1100() -> void:
	assert_eq(PointsRules.max_per_day(), 1100)


func test_good_and_great_runs_add_an_extra_but_finishing_always_earns_the_base() -> void:
	assert_eq(PointsRules.award([], "corsi", "tried")["task_points"], 100)
	assert_eq(PointsRules.award([], "corsi", "good")["task_points"], 125)
	assert_eq(PointsRules.award([], "corsi", "great")["task_points"], 150)
	assert_eq(PointsRules.award([], "corsi", "great")["extra"], 50)


func test_repeat_play_earns_no_extra() -> void:
	PointsStore.record_completion("dccs", "2026-05-01", "tried")
	var again := PointsStore.record_completion("dccs", "2026-05-01", "great")
	assert_eq(again["task_points"], 0)
	assert_eq(PointsStore.total(), 100)


func test_total_includes_extras_and_bonus() -> void:
	PointsStore.record_completion("corsi", "2026-05-01", "great")
	PointsStore.record_completion("go_nogo", "2026-05-01", "good")
	PointsStore.record_completion("dccs", "2026-05-01", "tried")
	var last := PointsStore.record_completion("cpt", "2026-05-01", "great")
	assert_eq(last["bonus"], 500)
	assert_eq(PointsStore.total(), 150 + 125 + 100 + 150 + 500)


func test_sample_runs_are_deterministic_and_leave_two_tasks_for_today() -> void:
	var now := 1790000000
	var a := SampleData.build_runs(now, 14, _rng(5))
	var b := SampleData.build_runs(now, 14, _rng(5))
	assert_eq(a, b)
	var today := Time.get_datetime_string_from_unix_time(now).substr(0, 10)
	var todays := a.filter(func(r: Dictionary) -> bool: return String(r["time"]).begins_with(today))
	assert_eq(todays.size(), SampleData.TODAY_TASKS.size())
	var state := SampleData.points_state(a)
	assert_eq(state["done"].size(), 2)
	assert_gt(int(state["total"]), 200)


func test_sample_report_builds() -> void:
	var runs := SampleData.build_runs(1790000000, 14, _rng(9))
	var html := ReportBuilder.build({"name": "Sample", "generated": "2026-10-01T10:00:00", "runs": runs,
			"levels": {}, "skips": {}})
	assert_true(html.contains("Longest span"))
	assert_true(html.contains("Hit rate by time block"))


func _rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r
