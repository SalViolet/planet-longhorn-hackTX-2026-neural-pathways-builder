extends GutTest

const MetricsScript := preload("res://scripts/metrics.gd")

var _m: Node


func before_each() -> void:
	_m = MetricsScript.new()
	add_child_autofree(_m)


func test_total_adds_up_and_last_is_latest() -> void:
	_m.record("corsi", {"max_span": 5, "corsi_score": 20})
	_m.record("corsi", {"max_span": 3, "corsi_score": 9})
	assert_eq(_m.total("corsi", "max_span"), 8.0)
	assert_eq(_m.last("corsi", "max_span"), 3.0)
	assert_eq(_m.total("corsi", "corsi_score"), 29.0)
	assert_eq(_m.run_count("corsi", "max_span"), 2)


func test_missions_are_separate() -> void:
	_m.record("go_nogo", {"hits": 10})
	_m.record("cpt", {"hits": 4})
	assert_eq(_m.total("go_nogo", "hits"), 10.0)
	assert_eq(_m.total("cpt", "hits"), 4.0)


func test_na_reaction_time_is_skipped_but_zero_counts_are_kept() -> void:
	_m.record("go_nogo", {"rt_mean_ms": 400.0, "omissions": 2})
	_m.record("go_nogo", {"rt_mean_ms": 0.0, "omissions": 0})
	assert_eq(_m.last("go_nogo", "rt_mean_ms"), 400.0)
	assert_eq(_m.run_count("go_nogo", "rt_mean_ms"), 1)
	assert_eq(_m.last("go_nogo", "omissions"), 0.0)
	assert_eq(_m.run_count("go_nogo", "omissions"), 2)


func test_unknown_mission_and_missing_keys_ignored() -> void:
	_m.record("nope", {"hits": 1})
	_m.record("cpt", {})
	assert_eq(_m.total("nope", "hits"), 0.0)
	assert_eq(_m.run_count("cpt", "hits"), 0)
