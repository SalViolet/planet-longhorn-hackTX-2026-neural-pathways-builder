class_name StoryFlow
extends RefCounted
## Decides which scene comes next in the story. Scenes hand over via these statics
## because change_scene can't pass arguments.
##
## Mission flow: intro beat (until the mission has been completed once) -> task -> results -> outro beat (first time) -> hub.
## The first mission is always the first in StoryData.MISSIONS (it gets the kid out of the ship).
## After that the adaptive engine's scheduler picks the next mission. Once every mission
## has been played, the finale plays once. The plot advances whichever mission is picked.

static var pending_beat := ""
static var pending_results: Dictionary = {}


static func begin_quest() -> void:
	if SceneTransition.is_changing():
		return
	var first := String(StoryData.MISSIONS[0]["id"])
	var outro := String(StoryData.mission(first)["outro_beat"])
	if StoryProgress.has_seen(outro):
		SceneTransition.change_scene(UIConst.SCENE_HUB)
	else:
		launch_mission(first)


static func launch_mission(mission_id: String) -> void:
	if SceneTransition.is_changing():
		return
	var entry := StoryData.mission(mission_id)
	if not StoryData.is_playable(mission_id):
		return
	if StoryRules.story_before_mission(mission_id):
		play_beat(String(entry["intro_beat"]))
	else:
		SceneTransition.change_scene(String(entry["scene"]))


static func play_beat(beat_id: String, results: Dictionary = {}) -> void:
	if SceneTransition.is_changing():
		return
	pending_beat = beat_id
	pending_results = results
	SceneTransition.change_scene(UIConst.SCENE_DIALOGUE)


static func finish_beat() -> void:
	if pending_beat == "" or SceneTransition.is_changing():
		return # Already finishing (e.g. a double press).
	var beat := pending_beat
	StoryProgress.mark_seen(beat)
	var next := StoryData.next_scene(beat)
	pending_beat = ""
	pending_results = {}
	if next == UIConst.SCENE_HUB or next == "":
		go_to_hub_or_finale()
	else:
		SceneTransition.change_scene(next)


## Called by a task's results screen when the player continues.
static func after_task(mission_id: String, results: Dictionary) -> void:
	if SceneTransition.is_changing():
		return # A double press must not count the mission twice.
	var tagged := results.duplicate()
	tagged["mission_id"] = mission_id
	StoryProgress.record_mission(mission_id, tagged)
	StoryRules.choose_next_mission(mission_id)
	var outro := String(StoryData.mission(mission_id).get("outro_beat", ""))
	if outro != "" and not StoryProgress.has_seen(outro):
		play_beat(outro, tagged)
	else:
		go_to_hub_or_finale()


## The player skipped a game (after the warning). It is not counted as played, so the quest
## cannot be finished without playing it. The scheduler is told it was "just played" so it is not
## picked again straight away.
static func skip_mission(mission_id: String) -> void:
	if SceneTransition.is_changing():
		return
	if mission_id != "":
		StoryProgress.record_skip(mission_id)
		StoryRules.choose_next_mission(mission_id)
	SceneTransition.change_scene(UIConst.SCENE_HUB)


static func go_to_hub_or_finale() -> void:
	if StoryRules.finale_due():
		play_beat("finale")
	else:
		SceneTransition.change_scene(UIConst.SCENE_HUB)
