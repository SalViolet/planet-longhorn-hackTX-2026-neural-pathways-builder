extends GutTest
## TaskConst and TrialLogger.


func test_us_to_ms_rounds() -> void:
	assert_eq(TaskConst.us_to_ms(0), 0)
	assert_eq(TaskConst.us_to_ms(1499), 1)
	assert_eq(TaskConst.us_to_ms(1500), 2)
	assert_eq(TaskConst.us_to_ms(250000), 250)


func test_anticipatory_threshold() -> void:
	assert_true(TrialLogger.is_anticipatory(0))
	assert_true(TrialLogger.is_anticipatory(99))
	assert_false(TrialLogger.is_anticipatory(100))
	assert_false(TrialLogger.is_anticipatory(450))
	assert_false(TrialLogger.is_anticipatory(-1), "no response is not anticipatory")


func test_csv_header_and_rows() -> void:
	var log := TrialLogger.new()
	log.begin("corsi")
	log.log_trial(1, {"span": 2}, [1, 2], {"taps": [1, 2]}, true, 512, true)
	log.log_trial(2, {"span": 2}, [3, 4], {"taps": []}, false, -1, false, TaskConst.REASON_FOCUS_LOST)
	var lines := log.to_csv().strip_edges().split("\n")
	assert_eq(lines.size(), 3, "header plus two rows")
	assert_eq(lines[0], "task,trial,params,stimulus,response,correct,rt_ms,valid,anticipatory,invalid_reason")
	assert_true(lines[1].begins_with("corsi,1,\"{\"\"span\"\":2}\""), "json is quoted and escaped")
	assert_true(lines[1].ends_with(",1,512,1,0,"), "valid row")
	assert_true(lines[2].ends_with(",0,,0,0,window_focus_lost"), "invalid row: blank rt, reason kept")


func test_fast_response_is_flagged_not_dropped() -> void:
	var log := TrialLogger.new()
	log.begin("x")
	log.log_trial(1, {}, 1, 1, true, 60, true)
	assert_eq(log.row_count(), 1)
	assert_true(log.to_csv().strip_edges().split("\n")[1].ends_with(",1,60,1,1,"))


func test_criterion_and_cv_match_reference_values() -> void:
	# Reference values from Python's statistics.NormalDist().inv_cdf.
	assert_almost_eq(SignalDetection.criterion(45, 45, 0, 15), -0.216082, 1e-4)
	assert_almost_eq(SignalDetection.criterion(30, 45, 5, 15), -0.009267, 1e-4)
	assert_almost_eq(SignalDetection.d_prime(15, 15, 0, 135), 4.543154, 1e-4)
	assert_almost_eq(SignalDetection.cv([400.0, 500.0, 600.0] as Array[float]), 0.2, 1e-9)
	assert_eq(SignalDetection.cv([] as Array[float]), 0.0)


func test_music_target_volume() -> void:
	const MusicScript := preload("res://scripts/music.gd")
	assert_eq(MusicScript.target_db(false, true), UIConst.MUSIC_DB)
	assert_eq(MusicScript.target_db(true, true), UIConst.MUSIC_TASK_DB)
	assert_lt(UIConst.MUSIC_TASK_DB, UIConst.MUSIC_DB - 10.0, "a lot quieter during tasks")
	assert_eq(MusicScript.target_db(false, false), UIConst.MUSIC_SILENT_DB)
	assert_eq(MusicScript.target_db(true, false), UIConst.MUSIC_SILENT_DB)
