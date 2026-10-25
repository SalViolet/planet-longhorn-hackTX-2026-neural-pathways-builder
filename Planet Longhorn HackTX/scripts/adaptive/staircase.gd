class_name Staircase
extends RefCounted
## A difficulty staircase run once per task run (for example 2-down/1-up: two good
## runs in a row make it harder, one poor run makes it easier). Higher level = harder.

enum Outcome { FAILURE = -1, NEUTRAL = 0, SUCCESS = 1 }

var level: int
## False until the first finished run has placed the player (see place()).
var placed := false
var _max_level: int
var _harder_after: int
var _easier_after: int
var _success_streak := 0
var _failure_streak := 0


func _init(start_level: int, max_level: int,
		harder_after_successes: int = AdaptiveConst.HARDER_AFTER_SUCCESSES,
		easier_after_failures: int = AdaptiveConst.EASIER_AFTER_FAILURES) -> void:
	_max_level = max_level
	level = clampi(start_level, 0, max_level)
	_harder_after = harder_after_successes
	_easier_after = easier_after_failures


## Sets the level straight from the first run's performance, then the normal up/down rule takes over.
func place(new_level: int) -> void:
	level = clampi(new_level, 0, _max_level)
	placed = true
	_success_streak = 0
	_failure_streak = 0


func update(outcome: int) -> void:
	if outcome == Outcome.SUCCESS:
		_failure_streak = 0
		_success_streak += 1
		if _success_streak >= _harder_after:
			level = mini(level + 1, _max_level)
			_success_streak = 0
	elif outcome == Outcome.FAILURE:
		_success_streak = 0
		_failure_streak += 1
		if _failure_streak >= _easier_after:
			level = maxi(level - 1, 0)
			_failure_streak = 0
	else:
		_success_streak = 0
		_failure_streak = 0


func to_dict() -> Dictionary:
	return {"level": level, "placed": placed, "success_streak": _success_streak, "failure_streak": _failure_streak}


func load_dict(data: Dictionary) -> void:
	level = clampi(int(data.get("level", level)), 0, _max_level)
	placed = bool(data.get("placed", false))
	_success_streak = int(data.get("success_streak", 0))
	_failure_streak = int(data.get("failure_streak", 0))
