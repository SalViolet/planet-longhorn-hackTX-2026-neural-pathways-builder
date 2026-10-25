extends GutTest
## Profile rules and the profile store. Uses its own temporary folders, never the real saves.

const TEST_INDEX := "user://test_profiles_index.cfg"
const TEST_ROOT := "user://test_profiles_root"


func before_each() -> void:
	ProfileStore.deactivate()
	ProfileStore.index_path = TEST_INDEX
	ProfileStore.root_dir = TEST_ROOT
	for p in ProfileStore.list():
		ProfileStore.delete(p["id"])
	DirAccess.remove_absolute(TEST_INDEX)
	ProfileStore.reload_from_disk()


func after_all() -> void:
	for p in ProfileStore.list():
		ProfileStore.delete(p["id"])
	DirAccess.remove_absolute(TEST_INDEX)
	DirAccess.remove_absolute(TEST_ROOT)
	ProfileStore.deactivate()
	ProfileStore.index_path = ProfileConst.INDEX_PATH
	ProfileStore.root_dir = ProfileConst.ROOT_DIR
	ProfileStore.reload_from_disk()


func _rng(seed_value: int = 1) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


# --- Rules ---

func test_names_are_tidied() -> void:
	assert_eq(ProfileRules.clean_name("  Nova  "), "Nova")
	assert_eq(ProfileRules.clean_name("Star    Kid"), "Star Kid", "runs of spaces become one")
	assert_eq(ProfileRules.clean_name("Zo\të\n"), "Zoë", "control characters are dropped, accents are kept")
	assert_eq(ProfileRules.clean_name("   "), "")


func test_name_validation() -> void:
	var none := PackedStringArray()
	assert_eq(ProfileRules.validate("Nova", none), "")
	assert_eq(ProfileRules.validate("   ", none), ProfileConst.ERROR_EMPTY)
	assert_eq(ProfileRules.validate("", none), ProfileConst.ERROR_EMPTY)
	assert_eq(ProfileRules.validate("a".repeat(12), none), "", "12 characters is allowed")
	assert_eq(ProfileRules.validate("a".repeat(13), none), ProfileConst.ERROR_TOO_LONG)
	assert_eq(ProfileRules.validate("nova", PackedStringArray(["Nova"])), ProfileConst.ERROR_TAKEN, "not case sensitive")
	assert_eq(ProfileRules.validate("  NOVA ", PackedStringArray(["Nova"])), ProfileConst.ERROR_TAKEN, "spaces ignored")
	var full := PackedStringArray()
	for i in ProfileConst.MAX_PROFILES:
		full.append("P%d" % i)
	assert_eq(ProfileRules.validate("New", full), ProfileConst.ERROR_FULL)


func test_colors_and_initials_and_ids() -> void:
	assert_eq(ProfileRules.next_free_color([] as Array[int]), 0)
	assert_eq(ProfileRules.next_free_color([0, 1] as Array[int]), 2)
	assert_eq(ProfileRules.next_free_color([0, 1, 2, 3, 4, 5] as Array[int]), 0, "all used: start again")
	assert_eq(ProfileRules.initial("nova"), "N")
	assert_eq(ProfileRules.initial(""), "")
	assert_true(ProfileRules.is_valid_id("a3f9c21b"))
	for bad in ["", "A3F9C21B", "a3f9c21", "a3f9c21bb", "../../etc", "a3f9c2 b", "zzzzzzzz"]:
		assert_false(ProfileRules.is_valid_id(bad), "'%s' is not a valid id" % bad)


# --- Store ---

func test_create_and_list() -> void:
	assert_eq(ProfileStore.count(), 0)
	var result := ProfileStore.create("  Nova ", 2, _rng())
	assert_true(result["ok"])
	assert_eq(result["profile"]["name"], "Nova")
	assert_eq(result["profile"]["color"], 2)
	assert_true(ProfileRules.is_valid_id(result["profile"]["id"]))
	ProfileStore.create("Sam", 0, _rng(2))
	var names: Array[String] = []
	for p in ProfileStore.list():
		names.append(p["name"])
	assert_eq(names, ["Nova", "Sam"] as Array[String], "kept in the order they were made")


func test_bad_names_are_refused_with_a_message() -> void:
	ProfileStore.create("Nova", 0, _rng())
	var dup := ProfileStore.create("nova", 1, _rng(3))
	assert_false(dup["ok"])
	assert_eq(dup["error"], ProfileConst.ERROR_TAKEN)
	assert_false(ProfileStore.create("", 0)["ok"])
	assert_eq(ProfileStore.count(), 1, "refused profiles are not added")


func test_there_is_a_limit_on_profiles() -> void:
	for i in ProfileConst.MAX_PROFILES:
		assert_true(ProfileStore.create("P%d" % i, 0, _rng(i + 10))["ok"])
	var extra := ProfileStore.create("One too many", 0, _rng(99))
	assert_false(extra["ok"])
	assert_eq(extra["error"], ProfileConst.ERROR_FULL)


func test_profiles_survive_a_restart() -> void:
	var id: String = ProfileStore.create("Nova", 3, _rng())["profile"]["id"]
	ProfileStore.activate(id)
	ProfileStore.reload_from_disk()
	assert_eq(ProfileStore.count(), 1)
	assert_eq(ProfileStore.get_profile(id)["name"], "Nova")
	assert_eq(ProfileStore.get_profile(id)["color"], 3)
	assert_eq(ProfileStore.last_id(), id, "the last player is remembered")


func test_each_profile_has_its_own_progress_and_difficulty() -> void:
	var a: String = ProfileStore.create("Ana", 0, _rng(1))["profile"]["id"]
	var b: String = ProfileStore.create("Ben", 1, _rng(2))["profile"]["id"]
	assert_true(ProfileStore.activate(a))
	assert_eq(ProfileStore.active_profile()["name"], "Ana")
	StoryProgress.mark_seen("arrival")
	StoryProgress.record_mission("corsi", {"max_span": 6})
	var start := AdaptiveEngine.level("go_nogo")
	var good := {"difficulty_level": start, "accuracy": 0.95, "d_prime": 3.5, "total_trials": 60, "invalid_trials": 0}
	AdaptiveEngine.record_run("go_nogo", good)
	AdaptiveEngine.record_run("go_nogo", good)
	var ana_level := AdaptiveEngine.level("go_nogo")
	assert_gt(ana_level, start, "Ana's good first run placed her above the start level")

	assert_true(ProfileStore.activate(b))
	assert_false(StoryProgress.has_seen("arrival"), "Ben has seen nothing")
	assert_eq(StoryProgress.plays("corsi"), 0)
	assert_eq(AdaptiveEngine.level("go_nogo"), start, "Ben starts at the start level")
	assert_false(AdaptiveEngine.skill().has_played("inhibition"))

	assert_true(ProfileStore.activate(a))
	assert_true(StoryProgress.has_seen("arrival"), "Ana's progress is still there")
	assert_eq(StoryProgress.best_span("corsi"), 6)
	assert_eq(AdaptiveEngine.level("go_nogo"), ana_level, "and her level is still there")


func test_trial_logs_go_to_the_active_profiles_folder_without_the_name() -> void:
	var id: String = ProfileStore.create("Nova", 0, _rng())["profile"]["id"]
	ProfileStore.activate(id)
	assert_eq(TrialLogger.log_dir, ProfileStore.data_dir(id).path_join("trial_logs"))
	var log := TrialLogger.new()
	log.begin("corsi")
	log.log_trial(1, {"span": 2}, [1, 2], {"taps": [1, 2]}, true, 500)
	var path := log.save_csv()
	assert_true(path.begins_with(TEST_ROOT), "saved inside the profile folder")
	assert_false(FileAccess.get_file_as_string(path).contains("Nova"), "the nickname is not in the data")
	assert_false(path.contains("Nova"), "or in the file path")
	for file in ["progress.cfg", "adaptive.cfg"]:
		StoryProgress.mark_seen("x")
		AdaptiveEngine.save()
		assert_false(FileAccess.get_file_as_string(ProfileStore.data_dir(id).path_join(file)).contains("Nova"), file)


func test_deleting_removes_the_profile_and_all_its_data() -> void:
	var id: String = ProfileStore.create("Nova", 0, _rng())["profile"]["id"]
	ProfileStore.activate(id)
	StoryProgress.mark_seen("arrival")
	var log := TrialLogger.new()
	log.begin("corsi")
	var path := log.save_csv()
	assert_true(FileAccess.file_exists(path))
	var other: String = ProfileStore.create("Sam", 1, _rng(5))["profile"]["id"]
	ProfileStore.activate(other)
	StoryProgress.mark_seen("arrival")

	ProfileStore.delete(id)
	assert_eq(ProfileStore.count(), 1)
	assert_true(ProfileStore.get_profile(id).is_empty())
	assert_false(DirAccess.dir_exists_absolute(ProfileStore.data_dir(id)), "the folder is gone")
	assert_false(FileAccess.file_exists(path), "and so are the logs")
	assert_true(DirAccess.dir_exists_absolute(ProfileStore.data_dir(other)), "other profiles are untouched")
	assert_true(StoryProgress.has_seen("arrival"), "the active profile still works")


func test_deleting_the_active_profile_returns_to_guest_paths() -> void:
	var id: String = ProfileStore.create("Nova", 0, _rng())["profile"]["id"]
	ProfileStore.activate(id)
	ProfileStore.delete(id)
	assert_eq(ProfileStore.active_id(), "")
	assert_eq(StoryProgress.path, StoryProgress.DEFAULT_PATH)
	assert_eq(AdaptiveEngine.path, AdaptiveConst.SKILL_PATH)
	assert_eq(TrialLogger.log_dir, TrialLogger.DEFAULT_LOG_DIR)


func test_delete_refuses_ids_that_could_point_outside_the_profiles_folder() -> void:
	var marker := "user://test_profiles_marker.txt"
	var file := FileAccess.open(marker, FileAccess.WRITE)
	file.store_string("keep me")
	file.close()
	ProfileStore.create("Nova", 0, _rng())
	for bad in ["../test_profiles_marker.txt", "..", "", "/", "a3f9c21b/../.."]:
		ProfileStore.delete(bad)
	assert_true(FileAccess.file_exists(marker), "nothing outside was deleted")
	assert_eq(ProfileStore.count(), 1)
	DirAccess.remove_absolute(marker)


func test_activating_an_unknown_profile_does_nothing() -> void:
	assert_false(ProfileStore.activate("deadbeef"))
	assert_eq(ProfileStore.active_id(), "")
	assert_eq(StoryProgress.path, StoryProgress.DEFAULT_PATH)


func test_a_damaged_index_file_does_not_crash_loading() -> void:
	var file := FileAccess.open(TEST_INDEX, FileAccess.WRITE)
	file.store_string("[data]\nprofiles=[{\"id\": \"../bad\", \"name\": \"X\"}, 5, {\"id\": \"a3f9c21b\"}]\n[state]\nlast_id=\"nope\"\n")
	file.close()
	ProfileStore.reload_from_disk()
	assert_eq(ProfileStore.count(), 0, "entries with a bad id or no name are ignored")
	assert_eq(ProfileStore.last_id(), "")
