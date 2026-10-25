extends GutTest
## DCCS logic only: stimuli, sequences, clock, session metrics. No nodes needed.

const SPEC := DccsConst.DEFAULT_PARAMS


func _rng(seed_value: int = 1) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _answer(trial: Dictionary) -> int:
	return trial["correct_side"]


func _wrong(trial: Dictionary) -> int:
	return DccsStimulus.Pen.RIGHT if trial["correct_side"] == DccsStimulus.Pen.LEFT else DccsStimulus.Pen.LEFT


# --- Spec values ---

func test_spec_values_match_the_design_doc() -> void:
	assert_eq(SPEC["pre_trials"], 12)
	assert_eq(SPEC["post_trials"], 12)
	assert_eq(SPEC["mixed_trials"], 32)
	assert_eq(SPEC["switch_probability"], 0.5)


# --- Stimuli and rules ---

func test_pen_targets_and_sorting_rules() -> void:
	# Left pen = blue star, right pen = orange round.
	assert_eq(DccsStimulus.correct_side(DccsStimulus.Hue.BLUE, DccsStimulus.Shape.STAR, DccsStimulus.Rule.COLOR), DccsStimulus.Pen.LEFT)
	assert_eq(DccsStimulus.correct_side(DccsStimulus.Hue.BLUE, DccsStimulus.Shape.STAR, DccsStimulus.Rule.SHAPE), DccsStimulus.Pen.LEFT)
	assert_eq(DccsStimulus.correct_side(DccsStimulus.Hue.ORANGE, DccsStimulus.Shape.ROUND, DccsStimulus.Rule.COLOR), DccsStimulus.Pen.RIGHT)
	assert_eq(DccsStimulus.correct_side(DccsStimulus.Hue.ORANGE, DccsStimulus.Shape.ROUND, DccsStimulus.Rule.SHAPE), DccsStimulus.Pen.RIGHT)
	assert_eq(DccsStimulus.correct_side(DccsStimulus.Hue.BLUE, DccsStimulus.Shape.ROUND, DccsStimulus.Rule.COLOR), DccsStimulus.Pen.LEFT)
	assert_eq(DccsStimulus.correct_side(DccsStimulus.Hue.BLUE, DccsStimulus.Shape.ROUND, DccsStimulus.Rule.SHAPE), DccsStimulus.Pen.RIGHT)
	assert_eq(DccsStimulus.correct_side(DccsStimulus.Hue.ORANGE, DccsStimulus.Shape.STAR, DccsStimulus.Rule.COLOR), DccsStimulus.Pen.RIGHT)
	assert_eq(DccsStimulus.correct_side(DccsStimulus.Hue.ORANGE, DccsStimulus.Shape.STAR, DccsStimulus.Rule.SHAPE), DccsStimulus.Pen.LEFT)


func test_conflict_items() -> void:
	assert_true(DccsStimulus.is_conflict(DccsStimulus.Hue.BLUE, DccsStimulus.Shape.ROUND))
	assert_true(DccsStimulus.is_conflict(DccsStimulus.Hue.ORANGE, DccsStimulus.Shape.STAR))
	assert_false(DccsStimulus.is_conflict(DccsStimulus.Hue.BLUE, DccsStimulus.Shape.STAR))
	assert_false(DccsStimulus.is_conflict(DccsStimulus.Hue.ORANGE, DccsStimulus.Shape.ROUND))


# --- Sequences ---

func test_mixed_rules_have_exactly_the_requested_switches() -> void:
	for seed_value in 100:
		var rules := DccsSequence.rules(32, 0.5, DccsStimulus.Rule.SHAPE, _rng(seed_value))
		var switches := 0
		var previous := DccsStimulus.Rule.SHAPE as int
		for rule in rules:
			switches += 1 if rule != previous else 0
			previous = rule
		assert_eq(rules.size(), 32)
		assert_eq(switches, 16, "seed %d" % seed_value)


func test_stimuli_have_exact_conflict_share_and_use_items_equally() -> void:
	var items := DccsSequence.stimuli(32, 0.5, _rng(3))
	var conflict := 0
	var blue_round := 0
	var blue_star := 0
	for item in items:
		conflict += 1 if DccsStimulus.is_conflict(item["hue"], item["shape"]) else 0
		blue_round += 1 if item["hue"] == DccsStimulus.Hue.BLUE and item["shape"] == DccsStimulus.Shape.ROUND else 0
		blue_star += 1 if item["hue"] == DccsStimulus.Hue.BLUE and item["shape"] == DccsStimulus.Shape.STAR else 0
	assert_eq(conflict, 16)
	assert_eq(blue_round, 8, "the two conflict items are balanced")
	assert_eq(blue_star, 8, "the two congruent items are balanced")
	for item in DccsSequence.stimuli(12, 1.0, _rng(4)):
		assert_true(DccsStimulus.is_conflict(item["hue"], item["shape"]), "pre/post blocks are all conflict")


# --- Clock ---

func test_clock_without_a_response() -> void:
	var P := DccsClock.Phase
	assert_eq(DccsClock.phase_at(0.0, 700, 4000, 600), P.CUE)
	assert_eq(DccsClock.phase_at(699.9, 700, 4000, 600), P.CUE)
	assert_eq(DccsClock.phase_at(700.0, 700, 4000, 600), P.STIMULUS)
	assert_eq(DccsClock.phase_at(4699.9, 700, 4000, 600), P.STIMULUS)
	assert_eq(DccsClock.phase_at(4700.0, 700, 4000, 600), P.ITI)
	assert_eq(DccsClock.phase_at(5299.9, 700, 4000, 600), P.ITI)
	assert_eq(DccsClock.phase_at(5300.0, 700, 4000, 600), P.DONE)


func test_clock_after_a_response_goes_straight_to_the_iti() -> void:
	var P := DccsClock.Phase
	assert_eq(DccsClock.phase_at(1300.0, 700, 4000, 600, 1200.0), P.ITI)
	assert_eq(DccsClock.phase_at(1799.9, 700, 4000, 600, 1200.0), P.ITI)
	assert_eq(DccsClock.phase_at(1800.0, 700, 4000, 600, 1200.0), P.DONE)


# --- Session structure ---

func test_session_blocks_rules_and_switch_flags() -> void:
	var s := DccsSession.new(SPEC, _rng(7))
	assert_eq(s.total_trials(), 56)
	var counts := {"pre": 0, "post": 0, "mixed": 0}
	var starts: Array[String] = []
	var mixed_switches := 0
	var mixed_conflicts := 0
	var number := 0
	while s.has_next():
		var block_start := s.next_block_start()
		if block_start != "":
			starts.append(block_start)
		var t := s.next_trial()
		number += 1
		assert_eq(t["number"], number)
		counts[t["block"]] += 1
		if t["block"] == "pre":
			assert_eq(t["rule"], DccsStimulus.Rule.COLOR)
			assert_true(t["conflict"])
			assert_false(t["switch"], "no switch inside the pre block")
		elif t["block"] == "post":
			assert_eq(t["rule"], DccsStimulus.Rule.SHAPE)
			assert_true(t["conflict"])
			assert_eq(t["switch"], t["number"] == 13, "only the first post trial is a switch")
		else:
			mixed_switches += 1 if t["switch"] else 0
			mixed_conflicts += 1 if t["conflict"] else 0
		assert_eq(t["correct_side"], DccsStimulus.correct_side(t["hue"], t["shape"], t["rule"]))
		s.record(_answer(t), 600)
	assert_eq(counts, {"pre": 12, "post": 12, "mixed": 32})
	assert_eq(starts, ["pre", "post", "mixed"] as Array[String], "each block announces itself once")
	assert_eq(mixed_switches, 16)
	assert_eq(mixed_conflicts, 16)


# --- Metrics ---

func test_perfect_run_and_costs_from_known_reaction_times() -> void:
	# pre/post 500 ms, mixed repeat 600 ms, mixed switch 800 ms.
	var s := DccsSession.new(SPEC, _rng(8))
	while s.has_next():
		var t := s.next_trial()
		var rt := 500
		if t["block"] == "mixed":
			rt = 800 if t["switch"] else 600
		s.record(_answer(t), rt)
	var r := s.get_results()
	assert_eq(r["accuracy"], 1.0)
	assert_eq(r["total_trials"], 56)
	assert_eq(r["pre_accuracy"], 1.0)
	assert_eq(r["mixed_accuracy"], 1.0)
	assert_almost_eq(r["pre_rt_ms"], 500.0, 1e-9)
	assert_almost_eq(r["mixed_repeat_rt_ms"], 600.0, 1e-9)
	assert_almost_eq(r["mixed_switch_rt_ms"], 800.0, 1e-9)
	assert_almost_eq(r["switch_cost_rt_ms"], 200.0, 1e-9)
	assert_almost_eq(r["mixing_cost_rt_ms"], 100.0, 1e-9)
	assert_eq(r["perseverative_errors"], 0)
	assert_eq(r["omissions"], 0)


func test_perseverative_errors_only_count_wrong_answers_on_switch_trials() -> void:
	var s := DccsSession.new(SPEC, _rng(9))
	var persevered := 0
	var other_errors := 0
	while s.has_next():
		var t := s.next_trial()
		if t["block"] == "post" and t["switch"]:
			s.record(_wrong(t), 700) # Sorted by the old (colour) rule.
			persevered += 1
		elif t["block"] == "mixed" and not t["switch"] and other_errors == 0:
			s.record(_wrong(t), 700) # Wrong on a repeat trial: an error, but not perseverative.
			other_errors += 1
		else:
			s.record(_answer(t), 600)
	var r := s.get_results()
	assert_eq(r["perseverative_errors"], persevered)
	assert_eq(r["total_trials"], 56)
	assert_almost_eq(r["accuracy"], 54.0 / 56.0, 1e-9)


func test_omissions_are_counted_and_not_perseverative() -> void:
	var s := DccsSession.new(SPEC, _rng(10))
	while s.has_next():
		s.next_trial()
		s.record(-1, -1)
	var r := s.get_results()
	assert_eq(r["omissions"], 56)
	assert_eq(r["accuracy"], 0.0)
	assert_eq(r["perseverative_errors"], 0)
	assert_eq(r["pre_rt_ms"], 0.0)
	assert_eq(r["switch_cost_rt_ms"], 0.0, "no RT data gives a zero cost, not an error")


func test_anticipatory_and_invalid_trials() -> void:
	var s := DccsSession.new(SPEC, _rng(11))
	var first := true
	while s.has_next():
		var t := s.next_trial()
		if first:
			s.record(_answer(t), 50) # Fast but correct: counted correct, flagged, left out of RT stats.
			first = false
		elif t["number"] == 2:
			s.record(-1, -1, false) # Window lost focus.
		else:
			s.record(_answer(t), 500)
	var r := s.get_results()
	assert_eq(r["anticipatory_responses"], 1)
	assert_eq(r["invalid_trials"], 1)
	assert_eq(r["total_trials"], 55)
	assert_eq(r["accuracy"], 1.0)
	assert_almost_eq(r["pre_rt_ms"], 500.0, 1e-9)
