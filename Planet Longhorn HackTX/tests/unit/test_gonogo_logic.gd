extends GutTest
## Go/No-Go logic only: sequence, clock, scoring, session. No nodes needed.

const SPEC := GoNoGoConst.DEFAULT_PARAMS


func _rng(seed_value: int = 1) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _longest_nogo_run(order: Array[bool]) -> int:
	var longest := 0
	var run := 0
	for is_go in order:
		run = 0 if is_go else run + 1
		longest = maxi(longest, run)
	return longest


# --- Spec values ---

func test_spec_values_match_the_design_doc() -> void:
	assert_eq(SPEC["fixation_ms"], 500)
	assert_eq(SPEC["stimulus_ms"], 500)
	assert_eq(SPEC["isi_min_ms"], 1000)
	assert_eq(SPEC["isi_max_ms"], 1500)
	assert_eq(SPEC["go_probability"], 0.75)
	assert_eq(SPEC["max_consecutive_nogo"], 3)
	assert_eq(SPEC["trials"], 60)
	assert_eq(SPEC["practice_trials"], 10)


# --- Sequence ---

func test_sequence_has_exact_counts_and_run_limit() -> void:
	for seed_value in 200:
		var order := GoNoGoSequence.generate(60, 0.75, 3, _rng(seed_value))
		assert_eq(order.size(), 60)
		assert_eq(order.count(true), 45, "seed %d: go count" % seed_value)
		assert_lte(_longest_nogo_run(order), 3, "seed %d: no-go run" % seed_value)


func test_practice_sequence_is_valid() -> void:
	var order := GoNoGoSequence.generate(10, 0.75, 3, _rng(5))
	assert_eq(order.size(), 10)
	assert_lte(_longest_nogo_run(order), 3)


func test_sequence_varies_with_the_seed() -> void:
	assert_ne(GoNoGoSequence.generate(60, 0.75, 3, _rng(1)), GoNoGoSequence.generate(60, 0.75, 3, _rng(2)))


func test_sequence_adds_go_trials_when_the_limit_makes_the_mix_impossible() -> void:
	# 10 trials, 20% go, max 1 no-go in a row can't work, so go trials are added.
	var order := GoNoGoSequence.generate(10, 0.2, 1, _rng(3))
	assert_eq(order.size(), 10)
	assert_lte(_longest_nogo_run(order), 1)


func test_isi_is_inside_the_jitter_range() -> void:
	var rng := _rng(9)
	var seen_low := false
	var seen_high := false
	for i in 500:
		var isi := GoNoGoSequence.isi_ms(1000, 1500, rng)
		assert_between(isi, 1000, 1500)
		seen_low = seen_low or isi < 1100
		seen_high = seen_high or isi > 1400
	assert_true(seen_low and seen_high, "ISI actually varies across the range")


# --- Clock ---

func test_clock_phases_and_boundaries() -> void:
	var P := GoNoGoClock.Phase
	assert_eq(GoNoGoClock.phase_at(0.0, 500, 500, 1200), P.FIXATION)
	assert_eq(GoNoGoClock.phase_at(499.9, 500, 500, 1200), P.FIXATION)
	assert_eq(GoNoGoClock.phase_at(500.0, 500, 500, 1200), P.STIMULUS)
	assert_eq(GoNoGoClock.phase_at(999.9, 500, 500, 1200), P.STIMULUS)
	assert_eq(GoNoGoClock.phase_at(1000.0, 500, 500, 1200), P.ISI)
	assert_eq(GoNoGoClock.phase_at(2199.9, 500, 500, 1200), P.ISI)
	assert_eq(GoNoGoClock.phase_at(2200.0, 500, 500, 1200), P.DONE)


# --- Scoring ---

func test_classification() -> void:
	var O := GoNoGoScoring.Outcome
	assert_eq(GoNoGoScoring.classify(true, true), O.HIT)
	assert_eq(GoNoGoScoring.classify(true, false), O.OMISSION)
	assert_eq(GoNoGoScoring.classify(false, true), O.COMMISSION)
	assert_eq(GoNoGoScoring.classify(false, false), O.CORRECT_REJECTION)
	assert_true(GoNoGoScoring.is_correct(O.HIT) and GoNoGoScoring.is_correct(O.CORRECT_REJECTION))
	assert_false(GoNoGoScoring.is_correct(O.OMISSION) or GoNoGoScoring.is_correct(O.COMMISSION))


func test_inverse_normal_matches_reference_values() -> void:
	# Reference values from Python's statistics.NormalDist().inv_cdf.
	assert_almost_eq(GoNoGoScoring.inv_norm_cdf(0.5), 0.0, 1e-6)
	assert_almost_eq(GoNoGoScoring.inv_norm_cdf(0.975), 1.959964, 1e-5)
	assert_almost_eq(GoNoGoScoring.inv_norm_cdf(0.99), 2.326348, 1e-5)
	assert_almost_eq(GoNoGoScoring.inv_norm_cdf(0.2), -0.841621, 1e-5)
	assert_almost_eq(GoNoGoScoring.inv_norm_cdf(0.001), -3.090232, 1e-5)


func test_d_prime_is_log_linear_corrected() -> void:
	assert_almost_eq(GoNoGoScoring.d_prime(45, 45, 0, 15), 4.157627, 1e-4, "perfect run is finite")
	assert_almost_eq(GoNoGoScoring.d_prime(30, 45, 5, 15), 0.823034, 1e-4)
	assert_almost_eq(GoNoGoScoring.d_prime(0, 45, 15, 15), -4.157627, 1e-4, "all wrong is finite")
	assert_almost_eq(GoNoGoScoring.d_prime(23, 45, 8, 15), -0.051163, 1e-4, "roughly chance")


func test_mean_and_sample_sd() -> void:
	var values: Array[float] = [400.0, 500.0, 600.0]
	assert_almost_eq(GoNoGoScoring.mean(values), 500.0, 1e-9)
	assert_almost_eq(GoNoGoScoring.sd(values), 100.0, 1e-9)
	var none: Array[float] = []
	assert_eq(GoNoGoScoring.mean(none), 0.0)
	assert_eq(GoNoGoScoring.sd([300.0] as Array[float]), 0.0, "one value has no spread")


# --- Session ---

func _fast_params(trials: int, practice: int) -> Dictionary:
	var p := SPEC.duplicate()
	p["trials"] = trials
	p["practice_trials"] = practice
	return p


func test_session_has_practice_then_main_trials_numbered_in_order() -> void:
	var s := GoNoGoSession.new(_fast_params(60, 10), _rng(4))
	var practice := 0
	var main := 0
	var last_number := 0
	while s.has_next():
		var t := s.next_trial()
		assert_eq(t["number"], last_number + 1)
		last_number = t["number"]
		assert_between(t["isi_ms"], 1000, 1500)
		if t["practice"]:
			practice += 1
			assert_eq(main, 0, "practice comes first")
		else:
			main += 1
		s.record(true, 400)
	assert_eq(practice, 10)
	assert_eq(main, 60)


func test_break_is_offered_once_before_the_first_main_trial() -> void:
	var s := GoNoGoSession.new(_fast_params(5, 3), _rng(4))
	var breaks := 0
	while s.has_next():
		if s.next_is_first_main_trial():
			breaks += 1
			assert_eq(s.next_trial()["practice"], false)
		else:
			s.next_trial()
		s.record(true, 400)
	assert_eq(breaks, 1)
	var no_practice := GoNoGoSession.new(_fast_params(5, 0), _rng(4))
	assert_false(no_practice.next_is_first_main_trial(), "no break when there is no practice")


func test_practice_trials_are_not_scored() -> void:
	var s := GoNoGoSession.new(_fast_params(0, 10), _rng(4))
	while s.has_next():
		s.next_trial()
		s.record(true, 400)
	var r := s.get_results()
	assert_eq(r["total_trials"], 0)
	assert_eq(r["hits"] + r["commissions"], 0)


func test_perfect_run_metrics() -> void:
	var s := GoNoGoSession.new(_fast_params(60, 0), _rng(11))
	var rt := 400
	while s.has_next():
		var t := s.next_trial()
		if t["is_go"]:
			s.record(true, rt)
			rt += 1
		else:
			s.record(false, -1)
	var r := s.get_results()
	assert_eq(r["hits"], 45)
	assert_eq(r["correct_rejections"], 15)
	assert_eq(r["omissions"] + r["commissions"], 0)
	assert_eq(r["accuracy"], 1.0)
	assert_almost_eq(r["d_prime"], 4.157627, 1e-4)
	assert_almost_eq(r["rt_mean_ms"], 400.0 + 44.0 / 2.0, 1e-6)
	assert_gt(r["rt_sd_ms"], 0.0)


func test_error_counts() -> void:
	# Respond to everything: all go trials are hits, all no-go trials are commission errors.
	var s := GoNoGoSession.new(_fast_params(60, 0), _rng(12))
	while s.has_next():
		s.next_trial()
		s.record(true, 450)
	var r := s.get_results()
	assert_eq(r["hits"], 45)
	assert_eq(r["commissions"], 15)
	assert_eq(r["correct_rejections"], 0)
	assert_almost_eq(r["commission_rate"], 1.0, 1e-9)
	# Respond to nothing: all go trials are omissions.
	var q := GoNoGoSession.new(_fast_params(60, 0), _rng(12))
	while q.has_next():
		q.next_trial()
		q.record(false, -1)
	var r2 := q.get_results()
	assert_eq(r2["omissions"], 45)
	assert_eq(r2["correct_rejections"], 15)
	assert_eq(r2["rt_mean_ms"], 0.0)


func test_anticipatory_hits_are_counted_but_left_out_of_rt_stats() -> void:
	var s := GoNoGoSession.new(_fast_params(60, 0), _rng(13))
	var first := true
	while s.has_next():
		var t := s.next_trial()
		if t["is_go"]:
			s.record(true, 50 if first else 500)
			first = false
		else:
			s.record(false, -1)
	var r := s.get_results()
	assert_eq(r["hits"], 45, "the fast response is still a hit")
	assert_eq(r["anticipatory_responses"], 1)
	assert_almost_eq(r["rt_mean_ms"], 500.0, 1e-9, "RT stats skip the flagged response")


func test_invalid_trials_are_excluded() -> void:
	var s := GoNoGoSession.new(_fast_params(10, 0), _rng(14))
	s.next_trial()
	s.record(false, -1, false)
	while s.has_next():
		s.next_trial()
		s.record(true, 400)
	var r := s.get_results()
	assert_eq(r["invalid_trials"], 1)
	assert_eq(r["total_trials"], 9)


func test_completed_trials_counts_practice_and_main() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var params := GoNoGoConst.DEFAULT_PARAMS.duplicate()
	var s := GoNoGoSession.new(params, rng)
	assert_eq(s.completed_trials(), 0)
	s.next_trial()
	s.record(true, 400)
	assert_eq(s.completed_trials(), 1)
	assert_eq(s.total_trials(), int(params["practice_trials"]) + int(params["trials"]))


func test_skip_practice_jumps_to_first_main_trial() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var s := GoNoGoSession.new(GoNoGoConst.DEFAULT_PARAMS.duplicate(), rng)
	s.skip_practice()
	assert_false(s.next_trial()["practice"])
	s.skip_practice() # Already in the main trials: no effect.
	assert_eq(s.completed_trials(), int(GoNoGoConst.DEFAULT_PARAMS["practice_trials"]) + 1)
