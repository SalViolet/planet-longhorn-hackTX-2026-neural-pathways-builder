extends GutTest
## CPT logic only: sequence, clock, session metrics, time bins. No nodes needed.

const SPEC := CptConst.DEFAULT_PARAMS


func _rng(seed_value: int = 1) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _session(trials: int = 150, seed_value: int = 1) -> CptSession:
	return CptSession.new(trials, SPEC["target_probability"], _rng(seed_value))


# --- Spec values ---

func test_spec_values_match_the_design_doc() -> void:
	assert_eq(SPEC["stimulus_ms"], 250)
	assert_eq(SPEC["trial_ms"], 2000)
	assert_eq(SPEC["target_probability"], 0.10)
	assert_eq(SPEC["duration_ms"], 300000, "5 minutes")
	assert_eq(SPEC["duration_ms"] / SPEC["trial_ms"], 150)
	assert_eq(CptConst.DEV_TRIALS, 30)
	assert_between(CptConst.GLYPH_COUNT, 8, 10, "8-10 glyphs")


# --- Sequence ---

func test_sequence_has_exact_target_count_and_valid_glyphs() -> void:
	for seed_value in 100:
		var glyphs := CptSequence.generate(150, 0.10, _rng(seed_value))
		assert_eq(glyphs.size(), 150)
		assert_eq(glyphs.count(CptConst.TARGET_GLYPH), 15, "seed %d" % seed_value)
		for g in glyphs:
			assert_between(g, 0, CptConst.GLYPH_COUNT - 1)


func test_targets_are_never_adjacent_and_glyphs_never_repeat() -> void:
	for seed_value in 100:
		var glyphs := CptSequence.generate(150, 0.10, _rng(seed_value))
		for i in range(1, glyphs.size()):
			assert_ne(glyphs[i], glyphs[i - 1], "seed %d trial %d repeats" % [seed_value, i])


func test_dev_mode_sequence() -> void:
	var glyphs := CptSequence.generate(30, 0.10, _rng(5))
	assert_eq(glyphs.size(), 30)
	assert_eq(glyphs.count(CptConst.TARGET_GLYPH), 3)


func test_target_count_is_capped_when_adjacency_would_be_forced() -> void:
	var glyphs := CptSequence.generate(5, 0.9, _rng(2))
	assert_lte(glyphs.count(CptConst.TARGET_GLYPH), 3, "at most every other trial")
	for i in range(1, glyphs.size()):
		assert_false(glyphs[i] == CptConst.TARGET_GLYPH and glyphs[i - 1] == CptConst.TARGET_GLYPH)


func test_targets_appear_all_through_the_run() -> void:
	var glyphs := CptSequence.generate(150, 0.10, _rng(11))
	for third in 3:
		var chunk := glyphs.slice(third * 50, third * 50 + 50)
		assert_gt(chunk.count(CptConst.TARGET_GLYPH), 0, "third %d has a target" % third)


# --- Clock ---

func test_clock_trial_grid_and_stimulus_window() -> void:
	assert_eq(CptClock.trial_index(0.0, 2000), 0)
	assert_eq(CptClock.trial_index(1999.9, 2000), 0)
	assert_eq(CptClock.trial_index(2000.0, 2000), 1)
	assert_eq(CptClock.trial_index(299999.0, 2000), 149)
	assert_eq(CptClock.trial_index(300000.0, 2000), 150, "the run is over")
	assert_almost_eq(CptClock.within_ms(4500.0, 2000), 500.0, 1e-9)
	assert_true(CptClock.stimulus_visible(0.0, 2000, 250))
	assert_true(CptClock.stimulus_visible(249.9, 2000, 250))
	assert_false(CptClock.stimulus_visible(250.0, 2000, 250))
	assert_false(CptClock.stimulus_visible(1999.9, 2000, 250))
	assert_true(CptClock.stimulus_visible(2000.0, 2000, 250), "next trial's glyph")


func test_clock_does_not_drift_over_a_whole_run() -> void:
	# Even with a frame time that never lines up with the grid, trial i is always due at i * 2000 ms.
	var due_wrong := 0
	var elapsed := 0.0
	var seen := 0
	while elapsed < 300000.0:
		var idx := CptClock.trial_index(elapsed, 2000)
		if idx < seen or idx > seen + 1:
			due_wrong += 1
		seen = idx
		elapsed += 16.7
	assert_eq(due_wrong, 0)
	assert_eq(seen, 149)


# --- Session metrics ---

func test_perfect_run() -> void:
	var s := _session()
	for i in 150:
		if s.is_target(i):
			s.record(i, true, 450)
		else:
			s.record(i, false, -1)
	var r := s.get_results()
	assert_eq(r["hits"], 15)
	assert_eq(r["correct_rejections"], 135)
	assert_eq(r["omissions"] + r["commissions"], 0)
	assert_eq(r["targets"], 15)
	assert_eq(r["total_trials"], 150)
	assert_almost_eq(r["d_prime"], 4.543154, 1e-4)
	assert_almost_eq(r["criterion"], SignalDetection.criterion(15, 15, 0, 135), 1e-9)
	assert_almost_eq(r["rt_mean_ms"], 450.0, 1e-9)
	assert_eq(r["rt_sd_ms"], 0.0)
	assert_eq(r["rt_cv"], 0.0)


func test_misses_and_false_alarms() -> void:
	var s := _session()
	var targets_seen := 0
	var false_alarms := 0
	for i in 150:
		if s.is_target(i):
			targets_seen += 1
			s.record(i, targets_seen <= 12, 500) # Misses the last 3 targets.
		else:
			false_alarms += 1
			s.record(i, false_alarms <= 20, 400) # Taps on the first 20 non-targets.
	var r := s.get_results()
	assert_eq(r["hits"], 12)
	assert_eq(r["omissions"], 3)
	assert_eq(r["commissions"], 20)
	assert_almost_eq(r["d_prime"], 1.809707, 1e-4)
	assert_almost_eq(r["criterion"], 0.128432, 1e-4)
	assert_almost_eq(r["commission_rate"], 20.0 / 135.0, 1e-9)


func test_rt_sd_and_cv() -> void:
	var s := _session()
	var rts := [400, 500, 600]
	var k := 0
	for i in 150:
		if s.is_target(i) and k < 3:
			s.record(i, true, rts[k])
			k += 1
		else:
			s.record(i, false, -1)
	var r := s.get_results()
	assert_almost_eq(r["rt_mean_ms"], 500.0, 1e-9)
	assert_almost_eq(r["rt_sd_ms"], 100.0, 1e-9)
	assert_almost_eq(r["rt_cv"], 0.2, 1e-9)


func test_results_come_in_five_equal_time_bins() -> void:
	var s := _session()
	# Catch every target in the first half of the run, none after.
	for i in 150:
		s.record(i, s.is_target(i) and i < 75, 500)
	var r := s.get_results()
	var bins: Array = r["bins"]
	assert_eq(bins.size(), 5)
	var targets := 0
	for b in bins:
		targets += b["targets"]
	assert_eq(targets, 15, "every target lands in exactly one bin")
	assert_eq(bins[0]["hit_rate"], 1.0)
	assert_eq(bins[1]["hit_rate"], 1.0)
	assert_eq(bins[4]["hit_rate"], 0.0)
	assert_eq(bins[4]["hits"], 0)


func test_bin_boundaries_are_even_for_the_dev_run() -> void:
	var s := _session(30, 3)
	for i in 30:
		s.record(i, false, -1)
	var total := 0
	for b: Dictionary in s.get_results()["bins"]:
		total += b["omissions"]
	assert_eq(total, 3, "all three dev-run targets are counted once")


func test_anticipatory_hits_are_kept_but_left_out_of_rt() -> void:
	var s := _session()
	var first := true
	for i in 150:
		if s.is_target(i):
			s.record(i, true, 60 if first else 500)
			first = false
		else:
			s.record(i, false, -1)
	var r := s.get_results()
	assert_eq(r["hits"], 15)
	assert_eq(r["anticipatory_responses"], 1)
	assert_almost_eq(r["rt_mean_ms"], 500.0, 1e-9)


func test_invalid_trials_are_excluded() -> void:
	var s := _session()
	for i in 150:
		if i == 10:
			s.record(i, false, -1, false)
		else:
			s.record(i, s.is_target(i), 500)
	var r := s.get_results()
	assert_eq(r["invalid_trials"], 1)
	assert_eq(r["total_trials"], 149)
