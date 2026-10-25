class_name TrialLogger
extends RefCounted
## Collects one row per trial and writes them as CSV into the active profile's trial_logs folder.
## Free of node dependencies so it can be tested directly.

const DEFAULT_LOG_DIR := "user://trial_logs" # Used when no profile is active.
const COLUMNS: PackedStringArray = [
	"task", "trial", "params", "stimulus", "response", "correct", "rt_ms", "valid",
	"anticipatory", "invalid_reason",
]

## Where CSVs are saved. ProfileStore points this at the active profile's folder.
static var log_dir := DEFAULT_LOG_DIR

var task_name: String = ""
var _rows: Array[PackedStringArray] = []


func begin(new_task_name: String) -> void:
	task_name = new_task_name
	_rows.clear()


## params, stimulus and response are stored as JSON. rt_ms < 0 means "no response" and is left blank.
## A response faster than TaskConst.ANTICIPATORY_RT_MS is flagged "anticipatory" but kept.
## Give invalid_reason when valid is false (for example TaskConst.REASON_FOCUS_LOST).
func log_trial(trial_number: int, params: Dictionary, stimulus: Variant, response: Variant,
		correct: bool, rt_ms: int, valid: bool = true, invalid_reason: String = "") -> void:
	_rows.append(PackedStringArray([
		task_name,
		str(trial_number),
		JSON.stringify(params),
		JSON.stringify(stimulus),
		JSON.stringify(response),
		"1" if correct else "0",
		str(rt_ms) if rt_ms >= 0 else "",
		"1" if valid else "0",
		"1" if is_anticipatory(rt_ms) else "0",
		invalid_reason,
	]))


static func is_anticipatory(rt_ms: int) -> bool:
	return rt_ms >= 0 and rt_ms < TaskConst.ANTICIPATORY_RT_MS


func row_count() -> int:
	return _rows.size()


func to_csv() -> String:
	var lines := PackedStringArray([_join(COLUMNS)])
	for row in _rows:
		lines.append(_join(row))
	return "\n".join(lines) + "\n"


## Returns the saved path, or "" if the file could not be written.
func save_csv() -> String:
	DirAccess.make_dir_recursive_absolute(log_dir)
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "%s/%s_%s.csv" % [log_dir, task_name, stamp]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write %s (error %d)" % [path, FileAccess.get_open_error()])
		return ""
	file.store_string(to_csv())
	return path


static func csv_escape(value: String) -> String:
	if value.contains(",") or value.contains("\"") or value.contains("\n"):
		return "\"%s\"" % value.replace("\"", "\"\"")
	return value


static func _join(fields: PackedStringArray) -> String:
	var escaped := PackedStringArray()
	for field in fields:
		escaped.append(csv_escape(field))
	return ",".join(escaped)
