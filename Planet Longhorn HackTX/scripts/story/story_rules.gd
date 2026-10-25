class_name StoryRules
extends RefCounted
## The story's decisions, with no scene changes, so they can be tested directly.
## The first mission in StoryData.MISSIONS always comes first (it gets the kid out of the ship).
## After that the adaptive engine's scheduler picks. Once every playable mission has been
## played, the finale is due once.


static func playable_missions() -> Array[String]:
	var ids: Array[String] = []
	for entry: Dictionary in StoryData.MISSIONS:
		if StoryData.is_playable(String(entry["id"])):
			ids.append(String(entry["id"]))
	return ids


## The story scene before a mission plays until that mission has been completed once
## (its aftermath scene seen), even if the intro was seen before. So quitting halfway, or an old
## save, can never skip the story and drop the player straight into a task.
static func story_before_mission(mission_id: String) -> bool:
	var entry := StoryData.mission(mission_id)
	var intro := String(entry.get("intro_beat", ""))
	if intro == "":
		return false
	var outro := String(entry.get("outro_beat", ""))
	return not StoryProgress.has_seen(intro) or (outro != "" and not StoryProgress.has_seen(outro))


## True once every playable mission has been played and the finale has not been seen.
static func finale_due() -> bool:
	if StoryProgress.has_seen("finale"):
		return false
	for id in playable_missions():
		if StoryProgress.plays(id) == 0:
			return false
	return true


## Asks the scheduler for the next mission and remembers it in the save file.
static func choose_next_mission(last_id: String, rng: RandomNumberGenerator = null) -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	StoryProgress.set_next_mission(MissionScheduler.pick(playable_missions(), AdaptiveEngine.skill(), last_id, rng))


## The mission the hub points at.
static func next_mission_id() -> String:
	var first := String(StoryData.MISSIONS[0]["id"])
	if StoryProgress.plays(first) == 0:
		return first
	var stored := StoryProgress.next_mission()
	if stored != "" and StoryData.is_playable(stored):
		return stored
	choose_next_mission("")
	return StoryProgress.next_mission()
