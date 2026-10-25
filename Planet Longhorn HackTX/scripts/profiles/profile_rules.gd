class_name ProfileRules
extends RefCounted
## Rules for profile names and colors. Pure functions, no files.


## Trims the name, squeezes runs of spaces to one, and drops control characters.
static func clean_name(raw: String) -> String:
	var kept := ""
	for i in raw.length():
		if raw.unicode_at(i) >= 32:
			kept += raw[i]
	return " ".join(kept.strip_edges().split(" ", false))


## Returns "" if the name can be used, otherwise the message to show the player.
static func validate(raw_name: String, existing_names: PackedStringArray) -> String:
	var cleaned := clean_name(raw_name)
	if existing_names.size() >= ProfileConst.MAX_PROFILES:
		return ProfileConst.ERROR_FULL
	if cleaned.length() < ProfileConst.MIN_NAME_LENGTH:
		return ProfileConst.ERROR_EMPTY
	if cleaned.length() > ProfileConst.MAX_NAME_LENGTH:
		return ProfileConst.ERROR_TOO_LONG
	for existing in existing_names:
		if existing.to_lower() == cleaned.to_lower():
			return ProfileConst.ERROR_TAKEN
	return ""


## The first avatar color not used yet (falls back to the first color).
static func next_free_color(used: Array[int]) -> int:
	for i in ProfileConst.COLORS.size():
		if not used.has(i):
			return i
	return 0


static func initial(profile_name: String) -> String:
	return profile_name.substr(0, 1).to_upper()


## A profile id is 8 lowercase hex characters. Anything else is refused before touching folders.
static func is_valid_id(id: String) -> bool:
	if id.length() != 8:
		return false
	for i in id.length():
		if not "0123456789abcdef".contains(id[i]):
			return false
	return true
