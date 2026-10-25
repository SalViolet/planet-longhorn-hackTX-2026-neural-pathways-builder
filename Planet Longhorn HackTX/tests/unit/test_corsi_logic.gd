extends GutTest
## Corsi logic only (sequence, scoring, session). No nodes needed.


func _new_session(start_span: int = 2) -> CorsiSession:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	return CorsiSession.new(start_span, CorsiConst.MAX_SPAN, CorsiConst.TRIALS_PER_SPAN, 9, rng)


func _wrong(seq: Array[int]) -> Array[int]:
	var bad := seq.duplicate()
	bad[0] = (bad[0] + 1) % 9
	return bad


func test_nine_block_positions() -> void:
	assert_eq(CorsiConst.BLOCK_POSITIONS.size(), 9)


func test_blocks_do_not_overlap() -> void:
	var p := CorsiConst.BLOCK_POSITIONS
	var min_dist := INF
	for i in p.size():
		for j in range(i + 1, p.size()):
			min_dist = minf(min_dist, p[i].distance_to(p[j]))
	assert_gt(min_dist, CorsiConst.BLOCK_SIZE * 1.2)


func test_blocks_fit_inside_board() -> void:
	var half := CorsiConst.BOARD_SIZE / 2.0 - Vector2.ONE * CorsiConst.BLOCK_SIZE / 2.0
	for v in CorsiConst.BLOCK_POSITIONS:
		assert_true(absf(v.x) <= half.x and absf(v.y) <= half.y, "block %s is off the board" % v)


func test_sequence_rules_over_many_draws() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var previous: Array[int] = []
	var bad := 0
	for n in 500:
		var length := 2 + n % 8
		var seq := CorsiSequence.generate(length, 9, previous, rng)
		if seq.size() != length or seq == previous:
			bad += 1
		for i in seq.size():
			if seq[i] < 0 or seq[i] > 8 or (i > 0 and seq[i] == seq[i - 1]):
				bad += 1
		previous = seq
	assert_eq(bad, 0, "length, range, no immediate repeat, never equals the previous sequence")


func test_perfect_run() -> void:
	var s := _new_session()
	var trials := 0
	while not s.is_finished():
		s.submit_response(s.next_sequence())
		trials += 1
	var r := s.get_results()
	assert_eq(trials, 16, "lengths 2 to 9, two trials each")
	assert_eq(r["max_span"], 9)
	assert_eq(r["correct_trials"], 16)
	assert_eq(r["corsi_score"], 144)


func test_two_wrong_at_first_span_ends_run() -> void:
	var s := _new_session()
	var trials := 0
	while not s.is_finished():
		s.submit_response(_wrong(s.next_sequence()))
		trials += 1
	var r := s.get_results()
	assert_eq(trials, 2)
	assert_eq(r["max_span"], 0)
	assert_eq(r["corsi_score"], 0)


func test_mixed_run() -> void:
	# Span 2: wrong, right. Span 3: right, wrong. Span 4: wrong, wrong -> end.
	var s := _new_session()
	for correct: bool in [false, true, true, false, false, false]:
		var seq := s.next_sequence()
		s.submit_response(seq if correct else _wrong(seq))
	var r := s.get_results()
	assert_true(s.is_finished())
	assert_eq(r["max_span"], 3)
	assert_eq(r["correct_trials"], 2)
	assert_eq(r["corsi_score"], 6)
	assert_eq(r["trial_spans"], [2, 2, 3, 3, 4, 4])
	assert_eq(r["trial_accuracy"].size(), 6)


func test_aborted_trial_is_not_scored_and_span_is_retried() -> void:
	var s := _new_session()
	s.next_sequence()
	s.abort_trial()
	assert_eq(s.current_span(), 2, "span unchanged")
	var seq := s.next_sequence()
	assert_eq(seq.size(), 2, "same length tried again")
	assert_eq(s.current_trial_number(), 2, "trial numbers stay unique")
	s.submit_response(seq)
	var r := s.get_results()
	assert_eq(r["total_trials"], 1, "only the finished trial is scored")
	assert_eq(r["invalid_trials"], 1)


func test_progress_moves_after_every_scored_trial() -> void:
	var s := _new_session(2)
	var total := float((CorsiConst.MAX_SPAN - 2 + 1) * CorsiConst.TRIALS_PER_SPAN)
	assert_eq(s.progress(2), 0.0)
	var seq := s.next_sequence()
	s.submit_response(seq)
	assert_almost_eq(s.progress(2), 1.0 / total, 0.0001)
	seq = s.next_sequence()
	s.submit_response(seq)
	assert_almost_eq(s.progress(2), 2.0 / total, 0.0001)


func test_aborted_trial_does_not_move_progress() -> void:
	var s := _new_session(2)
	s.next_sequence()
	s.abort_trial()
	assert_eq(s.progress(2), 0.0)
