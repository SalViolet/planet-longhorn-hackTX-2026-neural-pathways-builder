extends GutTest
## StoryData and StoryProgress (no nodes, no autoloads).


func before_each() -> void:
	StoryProgress.path = "user://test_progress.cfg"
	StoryProgress.reload_from_disk()
	StoryProgress.reset()


func after_all() -> void:
	DirAccess.remove_absolute("user://test_progress.cfg")
	StoryProgress.path = "user://progress.cfg"
	StoryProgress.reload_from_disk()


func _check_lines(lines: Array, where: String) -> void:
	for entry: Variant in lines:
		var line: Dictionary = entry
		assert_true(StoryData.SPEAKERS.has(line["speaker"]), "%s: unknown speaker" % where)
		assert_false(line.has("by_band"), "%s: unresolved band text" % where)
		if line.has("effect"):
			assert_true(["shake", "drums"].has(line["effect"]), "%s: unknown effect" % where)
		if line.has("choice"):
			var choice: Dictionary = line["choice"]
			assert_ne(String(choice["prompt"]), "", "%s: empty choice prompt" % where)
			assert_gte((choice["options"] as Array).size(), 2, "%s: a choice needs at least two options" % where)
			for option: Dictionary in choice["options"]:
				assert_ne(String(option["label"]), "", "%s: empty option label" % where)
				assert_gte((option["reply"] as Array).size(), 1, "%s: an option needs a reply" % where)
				_check_lines(option["reply"], where + " (reply)")
		else:
			assert_ne(String(line.get("text", "")), "", "%s: empty text" % where)


func test_every_line_has_a_known_speaker_and_text() -> void:
	for beat_id: String in StoryData.BEATS:
		for band in StoryData.BANDS:
			var results := {"max_span": {"great": 9, "good": 5, "tried": 2}[band]}
			_check_lines(StoryData.lines_for(beat_id, results), beat_id)


func test_every_speaker_has_a_voice_setting() -> void:
	for id: String in StoryData.SPEAKERS:
		assert_true(StoryData.SPEAKERS[id].has("voice_hz"), id)
	assert_eq(StoryData.SPEAKERS["narrator"]["voice_hz"], 0.0, "the narrator is silent")
	assert_ne(StoryData.SPEAKERS["elder_a"]["voice_hz"], StoryData.SPEAKERS["elder_b"]["voice_hz"], "elders sound different")


func test_all_story_text_has_balanced_tags_and_readable_words() -> void:
	for beat_id: String in StoryData.BEATS:
		for band in StoryData.BANDS:
			var results := {"max_span": {"great": 9, "good": 5, "tried": 2}[band]}
			for text in StoryData.all_texts(StoryData.lines_for(beat_id, results)):
				assert_true(StoryText.is_balanced(text), "%s: unbalanced tags in '%s'" % [beat_id, text])
				assert_ne(StoryText.plain(text).strip_edges(), "", "%s: no visible words" % beat_id)


func test_choice_labels_are_plain_text_because_buttons_do_not_show_markup() -> void:
	for beat_id: String in StoryData.BEATS:
		for entry: Dictionary in StoryData.BEATS[beat_id]["lines"]:
			if entry.has("choice"):
				for option: Dictionary in entry["choice"]["options"]:
					assert_eq(StoryText.plain(option["label"]), option["label"], "%s: '%s'" % [beat_id, option["label"]])


func test_every_mission_intro_and_the_finale_have_a_choice() -> void:
	for beat_id in ["arrival", "herd_intro", "dccs_intro", "cpt_intro", "finale"]:
		var found := false
		for entry: Dictionary in StoryData.BEATS[beat_id]["lines"]:
			found = found or entry.has("choice")
		assert_true(found, beat_id)


func test_a_choice_changes_flavor_but_every_option_leads_back_to_the_same_story() -> void:
	# The lines after the choice are shared; each option only adds its own short reply.
	for beat_id in ["arrival", "herd_intro", "dccs_intro", "cpt_intro", "finale"]:
		for entry: Dictionary in StoryData.BEATS[beat_id]["lines"]:
			if entry.has("choice"):
				var sizes := {}
				for option: Dictionary in entry["choice"]["options"]:
					sizes[(option["reply"] as Array).size()] = true
				assert_eq(sizes.size(), 1, "%s: options have replies of the same length, so pacing is the same" % beat_id)


func test_story_text_helpers() -> void:
	assert_eq(StoryText.plain("Hello [wave]big[/wave] [color=#ffd27d]world[/color]!"), "Hello big world!")
	assert_eq(StoryText.plain("No tags"), "No tags")
	assert_true(StoryText.is_balanced("[wave]a [color=#fff]b[/color] c[/wave]"))
	assert_true(StoryText.is_balanced("plain"))
	assert_false(StoryText.is_balanced("[wave]never closed"))
	assert_false(StoryText.is_balanced("[wave][color=#fff]crossed[/wave][/color]"))
	assert_false(StoryText.is_balanced("closed first[/wave]"))


func test_band_lines_cover_every_band() -> void:
	for beat_id: String in StoryData.BEATS:
		for entry: Dictionary in StoryData.BEATS[beat_id]["lines"]:
			if entry.has("by_band"):
				for band in StoryData.BANDS:
					assert_true(entry["by_band"].has(band), "%s missing %s" % [beat_id, band])


func test_beats_lead_to_existing_scenes_and_set_the_stage() -> void:
	for beat_id: String in StoryData.BEATS:
		assert_true(FileAccess.file_exists(StoryData.next_scene(beat_id)), beat_id)
		var first: Dictionary = StoryData.BEATS[beat_id]["lines"][0]
		assert_true(first.has("stage") and first.has("actors"), "%s: first line sets the stage" % beat_id)


func test_unknown_beat_gives_no_lines() -> void:
	assert_true(StoryData.lines_for("nope").is_empty())


func test_corsi_bands() -> void:
	assert_eq(StoryData.performance_band({"max_span": 9}), "great")
	assert_eq(StoryData.performance_band({"max_span": 6}), "great")
	assert_eq(StoryData.performance_band({"max_span": 5}), "good")
	assert_eq(StoryData.performance_band({"max_span": 4}), "good")
	assert_eq(StoryData.performance_band({"max_span": 3}), "tried")
	assert_eq(StoryData.performance_band({"max_span": 0}), "tried")
	assert_eq(StoryData.performance_band({}), "good", "no results defaults to good")


func test_gonogo_bands_use_accuracy() -> void:
	assert_eq(StoryData.performance_band({"accuracy": 1.0}), "great")
	assert_eq(StoryData.performance_band({"accuracy": 0.9}), "great")
	assert_eq(StoryData.performance_band({"accuracy": 0.8}), "good")
	assert_eq(StoryData.performance_band({"accuracy": 0.75}), "good")
	assert_eq(StoryData.performance_band({"accuracy": 0.5}), "tried")


func test_herd_plot_is_the_same_for_every_band() -> void:
	var great := StoryData.lines_for("herd_after", {"accuracy": 0.95})
	var tried := StoryData.lines_for("herd_after", {"accuracy": 0.4})
	assert_eq(great.size(), tried.size())
	assert_ne(great[0]["text"], tried[0]["text"])


func test_all_four_missions_are_playable() -> void:
	for id in ["corsi", "go_nogo", "dccs", "cpt"]:
		assert_true(StoryData.is_playable(id), id)
	assert_eq(StoryRules.playable_missions().size(), 4)


func test_bands_are_judged_by_the_missions_own_score() -> void:
	assert_eq(StoryData.performance_band({"mission_id": "dccs", "mixed_accuracy": 0.95}), "great")
	assert_eq(StoryData.performance_band({"mission_id": "dccs", "mixed_accuracy": 0.8}), "good")
	assert_eq(StoryData.performance_band({"mission_id": "dccs", "mixed_accuracy": 0.5}), "tried")
	assert_eq(StoryData.performance_band({"mission_id": "cpt", "d_prime": 4.0}), "great")
	assert_eq(StoryData.performance_band({"mission_id": "cpt", "d_prime": 2.5}), "good")
	assert_eq(StoryData.performance_band({"mission_id": "cpt", "d_prime": 0.5}), "tried")


func test_every_mission_story_keeps_the_same_plot_for_every_band() -> void:
	for beat in ["dccs_after", "cpt_after"]:
		var mission := "dccs" if beat == "dccs_after" else "cpt"
		var great := StoryData.lines_for(beat, {"mission_id": mission, "mixed_accuracy": 0.99, "d_prime": 4.5})
		var tried := StoryData.lines_for(beat, {"mission_id": mission, "mixed_accuracy": 0.1, "d_prime": 0.0})
		assert_eq(great.size(), tried.size(), beat)
		assert_ne(great[0]["text"], tried[0]["text"], beat)


func test_mission_stories_do_not_depend_on_play_order() -> void:
	# No beat may point at another mission's story ("tomorrow is...", "next the herd...").
	# (The finale's "I'll visit again tomorrow" is a goodbye, not a pointer to a mission.)
	for beat_id: String in ["corsi_after", "herd_intro", "herd_after", "dccs_intro", "dccs_after", "cpt_intro", "cpt_after"]:
		for text in StoryData.all_texts(StoryData.lines_for(beat_id, {"max_span": 5})):
			assert_false(text.to_lower().contains("tomorrow"), "%s: %s" % [beat_id, text])


func test_the_story_always_comes_before_a_mission_that_has_not_been_completed() -> void:
	assert_true(StoryRules.story_before_mission("corsi"), "fresh save")
	StoryProgress.mark_seen("arrival")
	assert_true(StoryRules.story_before_mission("corsi"), "intro seen, but Corsi never completed: the story plays again")
	StoryProgress.mark_seen("corsi_after")
	assert_false(StoryRules.story_before_mission("corsi"), "completed once: straight to the task")
	assert_true(StoryRules.story_before_mission("dccs"), "a different mission has its own story")
	assert_false(StoryRules.story_before_mission("nope"), "unknown mission")


func test_skipping_is_remembered_but_never_counts_as_played() -> void:
	assert_eq(StoryProgress.skips("dccs"), 0)
	StoryProgress.record_skip("dccs")
	StoryProgress.record_skip("dccs")
	assert_eq(StoryProgress.skips("dccs"), 2)
	assert_eq(StoryProgress.plays("dccs"), 0, "a skipped game is not a played game")
	StoryProgress.reload_from_disk()
	assert_eq(StoryProgress.skips("dccs"), 2, "saved")


func test_the_ending_needs_every_game_played_so_skipping_one_blocks_it() -> void:
	for id in ["corsi", "go_nogo", "cpt"]:
		StoryProgress.record_mission(id, {})
	StoryProgress.record_skip("dccs")
	assert_false(StoryRules.finale_due(), "three played and one skipped is not enough")
	StoryProgress.record_mission("dccs", {})
	assert_true(StoryRules.finale_due(), "playing the skipped game finishes the quest")


func test_finale_is_due_only_after_every_mission_has_been_played() -> void:
	assert_false(StoryRules.finale_due())
	for id in ["corsi", "go_nogo", "dccs"]:
		StoryProgress.record_mission(id, {})
	assert_false(StoryRules.finale_due(), "one mission left")
	StoryProgress.record_mission("cpt", {})
	assert_true(StoryRules.finale_due())
	StoryProgress.mark_seen("finale")
	assert_false(StoryRules.finale_due(), "plays once")


func test_the_first_mission_always_comes_first_then_the_scheduler_picks() -> void:
	assert_eq(StoryRules.next_mission_id(), "corsi")
	StoryProgress.record_mission("corsi", {})
	var picked := StoryRules.next_mission_id()
	assert_true(StoryData.is_playable(picked))
	assert_eq(StoryRules.next_mission_id(), picked, "the choice is remembered, not re-rolled on every visit")
	StoryRules.choose_next_mission("corsi", _rng_for_tests(3))
	assert_eq(StoryProgress.next_mission(), StoryRules.next_mission_id())


func test_the_scheduler_choice_follows_the_players_weakest_domain() -> void:
	AdaptiveEngine.path = "user://test_story_adaptive.cfg"
	AdaptiveEngine.reset()
	StoryProgress.record_mission("corsi", {})
	AdaptiveEngine.skill().update("memory", 0.95)
	AdaptiveEngine.skill().update("inhibition", 0.1)
	AdaptiveEngine.skill().update("flexibility", 0.9)
	AdaptiveEngine.skill().update("attention", 0.9)
	var counts := {}
	var rng := _rng_for_tests(5)
	for i in 300:
		StoryRules.choose_next_mission("corsi", rng)
		var pick := StoryProgress.next_mission()
		counts[pick] = int(counts.get(pick, 0)) + 1
	assert_gt(int(counts.get("go_nogo", 0)), 120, "the weak inhibition domain is picked most")
	DirAccess.remove_absolute("user://test_story_adaptive.cfg")
	AdaptiveEngine.path = AdaptiveConst.SKILL_PATH
	AdaptiveEngine.reload_from_disk()


func _rng_for_tests(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_plot_length_is_the_same_for_every_band() -> void:
	var great := StoryData.lines_for("corsi_after", {"max_span": 8})
	var tried := StoryData.lines_for("corsi_after", {"max_span": 1})
	assert_eq(great.size(), tried.size())
	assert_ne(great[1]["text"], tried[1]["text"], "only the elder's reaction differs")


func test_missions_are_consistent() -> void:
	var ids := {}
	for entry: Dictionary in StoryData.MISSIONS:
		ids[entry["id"]] = true
		for key in ["intro_beat", "outro_beat"]:
			assert_true(entry[key] == "" or StoryData.BEATS.has(entry[key]), "%s %s" % [entry["id"], key])
		if entry["scene"] != "":
			assert_true(FileAccess.file_exists(entry["scene"]), "%s scene" % entry["id"])
	assert_eq(ids.size(), StoryData.MISSIONS.size(), "mission ids are unique")


func test_progress_counts_keeps_best_and_persists() -> void:
	assert_false(StoryProgress.has_seen("arrival"))
	StoryProgress.mark_seen("arrival")
	StoryProgress.record_mission("corsi", {"max_span": 5, "corsi_score": 40})
	StoryProgress.record_mission("corsi", {"max_span": 3, "corsi_score": 10})
	assert_eq(StoryProgress.plays("corsi"), 2)
	assert_eq(StoryProgress.best_span("corsi"), 5)
	assert_eq(StoryProgress.best_score("corsi"), 40)
	StoryProgress.record_mission("go_nogo", {"accuracy": 0.82})
	StoryProgress.record_mission("go_nogo", {"accuracy": 0.7})
	assert_eq(StoryProgress.best_accuracy_percent("go_nogo"), 82)
	StoryProgress.record_mission("cpt", {"d_prime": 3.46})
	StoryProgress.record_mission("cpt", {"d_prime": 1.0})
	assert_eq(StoryProgress.best_dprime_x10("cpt"), 35)
	StoryProgress.set_next_mission("dccs")
	assert_eq(StoryProgress.next_mission(), "dccs")
	StoryProgress.reload_from_disk() # Force a re-read from disk.
	assert_true(StoryProgress.has_seen("arrival"))
	assert_eq(StoryProgress.best_span("corsi"), 5)
	StoryProgress.reset()
	assert_false(StoryProgress.has_seen("arrival"))
