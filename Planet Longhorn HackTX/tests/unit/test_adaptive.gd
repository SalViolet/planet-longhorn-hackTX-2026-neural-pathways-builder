extends GutTest
## Staircase, difficulty ladders, skill model, mission scheduler and the engine's saved file.

const O := Staircase.Outcome


func before_each() -> void:
	AdaptiveEngine.path = "user://test_adaptive.cfg"
	AdaptiveEngine.reset()


func after_all() -> void:
	DirAccess.remove_absolute("user://test_adaptive.cfg")
	AdaptiveEngine.path = AdaptiveConst.SKILL_PATH
	AdaptiveEngine.reload_from_disk()


func _rng(seed_value: int = 1) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


# --- Staircase ---

func test_two_down_one_up() -> void:
	var s := Staircase.new(2, 4)
	s.update(O.SUCCESS)
	assert_eq(s.level, 2, "one good run is not enough")
	s.update(O.SUCCESS)
	assert_eq(s.level, 3, "two good runs in a row make it harder")
	s.update(O.FAILURE)
	assert_eq(s.level, 2, "one poor run makes it easier")


func test_neutral_run_breaks_a_streak() -> void:
	var s := Staircase.new(1, 4)
	s.update(O.SUCCESS)
	s.update(O.NEUTRAL)
	s.update(O.SUCCESS)
	assert_eq(s.level, 1, "the streak was broken")
	s.update(O.SUCCESS)
	assert_eq(s.level, 2)


func test_staircase_stays_inside_its_levels() -> void:
	var s := Staircase.new(0, 2)
	s.update(O.FAILURE)
	assert_eq(s.level, 0, "cannot go below 0")
	for i in 10:
		s.update(O.SUCCESS)
	assert_eq(s.level, 2, "cannot go above the top level")
	assert_eq(Staircase.new(99, 3).level, 3, "start level is clamped")


func test_staircase_round_trips_through_a_dict() -> void:
	var s := Staircase.new(1, 4)
	s.update(O.SUCCESS)
	var copy := Staircase.new(0, 4)
	copy.load_dict(s.to_dict())
	assert_eq(copy.level, 1)
	copy.update(O.SUCCESS)
	assert_eq(copy.level, 2, "the success streak was saved too")


# --- Ladders ---

func test_every_mission_has_a_ladder_with_sensible_levels() -> void:
	for mission_id: String in AdaptiveConst.MISSION_DOMAINS:
		assert_true(DifficultyLadders.has_mission(mission_id), mission_id)
		var start := DifficultyLadders.start_level(mission_id)
		assert_between(start, 0, DifficultyLadders.max_level(mission_id))
		for level in DifficultyLadders.max_level(mission_id) + 1:
			assert_eq(DifficultyLadders.params_for(mission_id, level)["difficulty_level"], level)


func test_spec_levels_match_the_task_defaults() -> void:
	var gng := DifficultyLadders.params_for("go_nogo", DifficultyLadders.start_level("go_nogo"))
	for key: String in ["stimulus_ms", "isi_min_ms", "isi_max_ms", "go_probability"]:
		assert_eq(gng[key], GoNoGoConst.DEFAULT_PARAMS[key], "go_nogo %s" % key)
	var cpt := DifficultyLadders.params_for("cpt", DifficultyLadders.start_level("cpt"))
	assert_eq(cpt["trial_ms"], CptConst.DEFAULT_PARAMS["trial_ms"])
	assert_eq(cpt["target_probability"], CptConst.DEFAULT_PARAMS["target_probability"])
	var corsi := DifficultyLadders.params_for("corsi", DifficultyLadders.start_level("corsi"))
	assert_eq(corsi["start_span"], CorsiConst.DEFAULT_PARAMS["start_span"])


func test_ladders_get_harder_step_by_step() -> void:
	var previous_stimulus := 10000
	for level in DifficultyLadders.max_level("go_nogo") + 1:
		var stimulus: int = DifficultyLadders.params_for("go_nogo", level)["stimulus_ms"]
		assert_lt(stimulus, previous_stimulus, "go_nogo level %d is quicker" % level)
		previous_stimulus = stimulus
	var previous_timeout := 10000
	for level in DifficultyLadders.max_level("dccs") + 1:
		var timeout: int = DifficultyLadders.params_for("dccs", level)["response_timeout_ms"]
		assert_lt(timeout, previous_timeout)
		previous_timeout = timeout
	var previous_span := 0
	for level in DifficultyLadders.max_level("corsi") + 1:
		var span: int = DifficultyLadders.params_for("corsi", level)["start_span"]
		assert_gt(span, previous_span)
		previous_span = span


func test_params_for_clamps_the_level_and_ignores_unknown_missions() -> void:
	assert_eq(DifficultyLadders.params_for("cpt", 99)["difficulty_level"], DifficultyLadders.max_level("cpt"))
	assert_eq(DifficultyLadders.params_for("nope", 1), {})


func test_judging_runs() -> void:
	# Corsi at start span 2: reaching 4+ is good, failing the first length is poor.
	assert_eq(DifficultyLadders.judge("corsi", {"max_span": 4}, 0), O.SUCCESS)
	assert_eq(DifficultyLadders.judge("corsi", {"max_span": 3}, 0), O.NEUTRAL)
	assert_eq(DifficultyLadders.judge("corsi", {"max_span": 2}, 0), O.NEUTRAL)
	assert_eq(DifficultyLadders.judge("corsi", {"max_span": 0}, 0), O.FAILURE)
	assert_eq(DifficultyLadders.judge("corsi", {"max_span": 4}, 2), O.NEUTRAL, "start span 4: 4 is only the start")
	assert_eq(DifficultyLadders.judge("corsi", {"max_span": 3}, 2), O.FAILURE)
	assert_eq(DifficultyLadders.judge("go_nogo", {"accuracy": 0.95}, 1), O.SUCCESS)
	assert_eq(DifficultyLadders.judge("go_nogo", {"accuracy": 0.8}, 1), O.NEUTRAL)
	assert_eq(DifficultyLadders.judge("go_nogo", {"accuracy": 0.6}, 1), O.FAILURE)
	assert_eq(DifficultyLadders.judge("dccs", {"mixed_accuracy": 0.95}, 1), O.SUCCESS)
	assert_eq(DifficultyLadders.judge("dccs", {"mixed_accuracy": 0.5}, 1), O.FAILURE)
	assert_eq(DifficultyLadders.judge("cpt", {"d_prime": 4.0}, 1), O.SUCCESS)
	assert_eq(DifficultyLadders.judge("cpt", {"d_prime": 1.0}, 1), O.FAILURE)


# --- Skill model ---

func test_first_run_replaces_the_prior_and_later_runs_blend() -> void:
	var m := SkillModel.new()
	assert_eq(m.get_skill("memory"), 0.5, "prior")
	assert_false(m.has_played("memory"))
	m.update("memory", 0.9)
	assert_almost_eq(m.get_skill("memory"), 0.9, 1e-9)
	m.update("memory", 0.3) # rate = max(0.3, 1/2) = 0.5
	assert_almost_eq(m.get_skill("memory"), 0.6, 1e-9)
	m.update("memory", 0.0) # rate = max(0.3, 1/3) = 1/3
	assert_almost_eq(m.get_skill("memory"), 0.4, 1e-9)
	for i in 10:
		m.update("memory", 1.0)
	assert_lte(m.get_skill("memory"), 1.0)
	assert_eq(m.plays("memory"), 13)


func test_results_map_to_scores_and_domains() -> void:
	assert_almost_eq(TaskScores.score("corsi", {"max_span": 9}), 1.0, 1e-9)
	assert_almost_eq(TaskScores.score("corsi", {"max_span": 0}), 0.0, 1e-9)
	assert_almost_eq(TaskScores.score("go_nogo", {"d_prime": 2.0}), 0.5, 1e-9)
	assert_almost_eq(TaskScores.score("go_nogo", {"d_prime": 9.0}), 1.0, 1e-9, "clamped")
	assert_almost_eq(TaskScores.score("dccs", {"mixed_accuracy": 0.8}), 0.8, 1e-9)
	assert_almost_eq(TaskScores.score("cpt", {"d_prime": -1.0}), 0.0, 1e-9, "clamped")
	var m := SkillModel.new()
	m.record_results("go_nogo", {"d_prime": 4.0})
	assert_almost_eq(m.get_skill("inhibition"), 1.0, 1e-9)
	assert_eq(m.plays("memory"), 0, "only its own domain moves")


# --- Scheduler ---

func test_weaker_domains_get_more_weight_and_repeats_less() -> void:
	var m := SkillModel.new()
	m.update("memory", 0.9)
	m.update("inhibition", 0.2)
	m.update("flexibility", 0.5)
	m.update("attention", 0.5)
	assert_gt(MissionScheduler.weight("go_nogo", m, ""), MissionScheduler.weight("corsi", m, ""))
	assert_lt(MissionScheduler.weight("go_nogo", m, "go_nogo"), MissionScheduler.weight("go_nogo", m, ""))
	var fresh := SkillModel.new()
	m.update("attention", 0.5)
	assert_gt(MissionScheduler.weight("cpt", fresh, ""), MissionScheduler.weight("cpt", m, ""), "unplayed gets a bonus")


func test_scheduler_favours_the_weakest_but_still_varies() -> void:
	var m := SkillModel.new()
	m.update("memory", 0.95)
	m.update("inhibition", 0.15)
	m.update("flexibility", 0.7)
	m.update("attention", 0.7)
	var candidates: Array[String] = ["corsi", "go_nogo", "dccs", "cpt"]
	var rng := _rng(42)
	var counts := {"corsi": 0, "go_nogo": 0, "dccs": 0, "cpt": 0}
	for i in 2000:
		counts[MissionScheduler.pick(candidates, m, "", rng)] += 1
	for id: String in counts:
		assert_gt(counts[id], 0, "%s is still picked sometimes" % id)
	assert_gt(counts["go_nogo"], counts["corsi"] * 2, "the weakest domain comes up much more than the strongest")
	assert_gt(counts["go_nogo"], counts["dccs"])


func test_scheduler_edge_cases() -> void:
	var m := SkillModel.new()
	assert_eq(MissionScheduler.pick([] as Array[String], m, "", _rng()), "")
	assert_eq(MissionScheduler.pick(["cpt"] as Array[String], m, "cpt", _rng()), "cpt", "only one choice")
	var rng := _rng(7)
	var again := 0
	for i in 400:
		again += 1 if MissionScheduler.pick(["corsi", "dccs"] as Array[String], m, "corsi", rng) == "corsi" else 0
	assert_lt(again, 200, "the mission just played is picked less than half the time")


# --- Engine and saved file ---

func test_new_players_start_on_the_start_levels() -> void:
	for mission_id: String in AdaptiveConst.MISSION_DOMAINS:
		assert_eq(AdaptiveEngine.level(mission_id), DifficultyLadders.start_level(mission_id), mission_id)
		assert_eq(AdaptiveEngine.params_for(mission_id)["difficulty_level"], DifficultyLadders.start_level(mission_id))
	assert_eq(AdaptiveEngine.params_for("nope"), {})
	assert_eq(AdaptiveEngine.level("nope"), -1)


func test_first_run_places_the_player_then_two_good_runs_make_it_harder() -> void:
	var start := AdaptiveEngine.level("go_nogo")
	assert_false(AdaptiveEngine.is_placed("go_nogo"))
	var great := {"accuracy": 0.97, "d_prime": 3.5, "total_trials": 60, "invalid_trials": 0}
	great["difficulty_level"] = start
	AdaptiveEngine.record_run("go_nogo", great)
	assert_true(AdaptiveEngine.is_placed("go_nogo"))
	assert_eq(AdaptiveEngine.level("go_nogo"), start + 2, "a great first run is placed two levels up")
	var good := {"accuracy": 0.9, "d_prime": 3.5, "total_trials": 60, "invalid_trials": 0}
	good["difficulty_level"] = AdaptiveEngine.level("go_nogo")
	AdaptiveEngine.record_run("go_nogo", good)
	assert_eq(AdaptiveEngine.level("go_nogo"), start + 2, "after placement one good run is not enough")
	AdaptiveEngine.record_run("go_nogo", good)
	assert_eq(AdaptiveEngine.level("go_nogo"), start + 3, "two good runs in a row make it harder")
	assert_true(AdaptiveEngine.skill().has_played("inhibition"))
	AdaptiveEngine.reload_from_disk() # Force a re-read from disk.
	assert_eq(AdaptiveEngine.level("go_nogo"), start + 3, "level survives a restart")
	assert_true(AdaptiveEngine.is_placed("go_nogo"), "and so does the fact that the player was placed")
	assert_almost_eq(AdaptiveEngine.skill().get_skill("inhibition"), 3.5 / 4.0, 1e-6, "skill survives a restart")


func test_after_placement_one_poor_run_makes_a_task_easier() -> void:
	var start := AdaptiveEngine.level("dccs")
	AdaptiveEngine.record_run("dccs", {"difficulty_level": start, "mixed_accuracy": 0.8, "total_trials": 56, "invalid_trials": 0})
	assert_eq(AdaptiveEngine.level("dccs"), start, "an in-between first run is placed where it was played")
	AdaptiveEngine.record_run("dccs", {"difficulty_level": start, "mixed_accuracy": 0.4, "total_trials": 56, "invalid_trials": 0})
	assert_eq(AdaptiveEngine.level("dccs"), start - 1)


func test_a_poor_first_run_is_placed_lower() -> void:
	var start := AdaptiveEngine.level("cpt")
	AdaptiveEngine.record_run("cpt", {"difficulty_level": start, "d_prime": 0.3, "total_trials": 150, "invalid_trials": 0})
	assert_eq(AdaptiveEngine.level("cpt"), maxi(start - 2, 0), "a very poor first run is placed two levels down")


func test_placement_by_performance() -> void:
	# Corsi at level 0 (start span 2): span 6+ is great, 4-5 good, 2-3 in between, below 2 poor.
	assert_eq(DifficultyLadders.placement_delta("corsi", {"max_span": 7}, 0), 2)
	assert_eq(DifficultyLadders.placement_delta("corsi", {"max_span": 5}, 0), 1)
	assert_eq(DifficultyLadders.placement_delta("corsi", {"max_span": 3}, 0), 0)
	assert_eq(DifficultyLadders.placement_delta("corsi", {"max_span": 0}, 0), -1)
	assert_eq(DifficultyLadders.placement_delta("go_nogo", {"accuracy": 0.97}, 1), 2)
	assert_eq(DifficultyLadders.placement_delta("go_nogo", {"accuracy": 0.9}, 1), 1)
	assert_eq(DifficultyLadders.placement_delta("go_nogo", {"accuracy": 0.8}, 1), 0)
	assert_eq(DifficultyLadders.placement_delta("go_nogo", {"accuracy": 0.6}, 1), -1)
	assert_eq(DifficultyLadders.placement_delta("go_nogo", {"accuracy": 0.4}, 1), -2)
	assert_eq(DifficultyLadders.placement_delta("dccs", {"mixed_accuracy": 0.99}, 1), 2)
	assert_eq(DifficultyLadders.placement_delta("dccs", {"mixed_accuracy": 0.92}, 1), 1)
	assert_eq(DifficultyLadders.placement_delta("dccs", {"mixed_accuracy": 0.45}, 1), -2)
	assert_eq(DifficultyLadders.placement_delta("cpt", {"d_prime": 4.5}, 1), 2)
	assert_eq(DifficultyLadders.placement_delta("cpt", {"d_prime": 3.8}, 1), 1)
	assert_eq(DifficultyLadders.placement_delta("cpt", {"d_prime": 2.5}, 1), 0)
	assert_eq(DifficultyLadders.placement_delta("cpt", {"d_prime": 1.5}, 1), -1)
	assert_eq(DifficultyLadders.placement_delta("cpt", {"d_prime": 0.5}, 1), -2)


func test_placement_stays_on_the_ladder() -> void:
	assert_eq(DifficultyLadders.placement_level("go_nogo", {"accuracy": 0.99}, 4), 4, "cannot go above the top")
	assert_eq(DifficultyLadders.placement_level("go_nogo", {"accuracy": 0.2}, 0), 0, "cannot go below 0")
	assert_eq(DifficultyLadders.placement_level("corsi", {"max_span": 9}, 2), 3, "Corsi's ladder tops out at level 3")


func test_staircase_place_and_persist() -> void:
	var s := Staircase.new(1, 4)
	assert_false(s.placed)
	s.update(O.SUCCESS)
	s.place(3)
	assert_true(s.placed)
	assert_eq(s.level, 3)
	s.update(O.SUCCESS)
	assert_eq(s.level, 3, "placing clears the streak: one success is not enough")
	var copy := Staircase.new(0, 4)
	copy.load_dict(s.to_dict())
	assert_true(copy.placed)
	assert_eq(copy.level, 3)


func test_level_text_for_results_screens() -> void:
	var start := AdaptiveEngine.level("go_nogo")
	var run := {"difficulty_level": start, "accuracy": 0.97, "d_prime": 3.5, "total_trials": 60, "invalid_trials": 0}
	AdaptiveEngine.record_run("go_nogo", run)
	assert_eq(AdaptiveEngine.level_text("go_nogo", run), "Level up! You are now level %d" % (start + 3))
	var steady := {"difficulty_level": AdaptiveEngine.level("go_nogo"), "accuracy": 0.8}
	assert_eq(AdaptiveEngine.level_text("go_nogo", steady), "Level %d" % (start + 3))
	var easier := {"difficulty_level": AdaptiveEngine.level("go_nogo") + 1, "accuracy": 0.8}
	assert_eq(AdaptiveEngine.level_text("go_nogo", easier), "Next time will be a little easier (level %d)" % (start + 3))
	assert_eq(AdaptiveEngine.level_text("go_nogo", {"difficulty_level": -1}), "", "dev runs show no level")
	assert_eq(AdaptiveEngine.level_text("nope", {"difficulty_level": 1}), "")


func test_dev_runs_and_unreliable_runs_do_not_move_the_engine() -> void:
	var start := AdaptiveEngine.level("go_nogo")
	AdaptiveEngine.record_run("go_nogo", {"difficulty_level": -1, "accuracy": 0.2, "total_trials": 60})
	assert_eq(AdaptiveEngine.level("go_nogo"), start, "run without a level (dev mode)")
	AdaptiveEngine.record_run("go_nogo", {"difficulty_level": start, "accuracy": 0.2, "d_prime": 0.0, "total_trials": 40, "invalid_trials": 20})
	assert_eq(AdaptiveEngine.level("go_nogo"), start, "too many invalid trials")
	assert_false(AdaptiveEngine.skill().has_played("inhibition"))
	AdaptiveEngine.record_run("nope", {"difficulty_level": 1})
	assert_eq(AdaptiveEngine.level("nope"), -1)
