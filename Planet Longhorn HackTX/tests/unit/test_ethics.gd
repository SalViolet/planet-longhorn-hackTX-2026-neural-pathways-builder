extends GutTest
## Guard rails from the design doc: the game never claims to diagnose or train the brain,
## and nothing leaves the device. These scan the game's own scripts and scenes.

const SCAN_DIRS: Array[String] = ["res://scripts", "res://scenes"]

# Wording the game must never use about itself or its players.
const BANNED_PHRASES: Array[String] = [
	"diagnos", "brain train", "train your brain", "train the brain", "brain game",
	"clinical", "disorder", "adhd", "autis", "dyslex", "therapy", "treatment",
	"cure ", "improves your memory", "boost your iq", "iq score",
]

# Anything that could send data off the device.
const NETWORK_WORDS: Array[String] = [
	"HTTPRequest", "HTTPClient", "WebSocket", "ENetMultiplayer", "StreamPeerTCP", "PacketPeerUDP",
	"TCPServer", "UDPServer", "OS.shell_open", "JavaScriptBridge", "MultiplayerAPI", "WebRTC",
]


func _files(dir_path: String, extensions: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for sub in DirAccess.get_directories_at(dir_path):
		out.append_array(_files(dir_path.path_join(sub), extensions))
	for file in DirAccess.get_files_at(dir_path):
		if file.get_extension() in extensions:
			out.append(dir_path.path_join(file))
	return out


func _all_game_files() -> Array[String]:
	var out: Array[String] = []
	for dir_path in SCAN_DIRS:
		out.append_array(_files(dir_path, ["gd", "tscn"]))
	return out


func test_the_scan_finds_the_game_files() -> void:
	assert_gt(_all_game_files().size(), 40, "the scan is looking in the right places")


# The report's fixed wording says what the game is NOT ("not a diagnosis"), so it is the one
# file allowed to contain these two words. test_report_wording_only_denies checks it.
const NEGATION_FILE := "res://scripts/reports/report_text.gd"
const NEGATION_PHRASES: Array[String] = ["diagnos", "clinical"]


func test_no_claims_to_diagnose_or_train() -> void:
	for path in _all_game_files():
		var text := FileAccess.get_file_as_string(path).to_lower()
		for phrase in BANNED_PHRASES:
			if path == NEGATION_FILE and phrase in NEGATION_PHRASES:
				continue
			assert_false(text.contains(phrase), "%s contains '%s'" % [path, phrase])


func test_report_wording_only_denies() -> void:
	var text := FileAccess.get_file_as_string(NEGATION_FILE).to_lower()
	assert_true(text.contains("not a diagnosis"), "the report says it is not a diagnosis")
	assert_true(text.contains("not a clinical or psychological assessment"))
	for line in text.split("\n"):
		if line.contains("diagnos") and not line.contains("not a diagnosis") and not line.begins_with("##") and not line.begins_with("#"):
			fail_test("a line in the report wording mentions diagnosis without denying it: %s" % line)


func test_no_network_code() -> void:
	for path in _all_game_files():
		var text := FileAccess.get_file_as_string(path)
		for word in NETWORK_WORDS:
			assert_false(text.contains(word), "%s uses %s" % [path, word])


func test_trial_log_has_no_personal_identifiers() -> void:
	for column in TrialLogger.COLUMNS:
		for banned in ["name", "email", "birth", "age", "address", "phone", "player", "user"]:
			assert_false(column.contains(banned), "column '%s' looks like an identifier" % column)


func test_project_does_not_ask_for_network_permission() -> void:
	var settings := FileAccess.get_file_as_string("res://project.godot")
	assert_false(settings.contains("INTERNET"), "no internet permission in project settings")
	assert_false(settings.contains("[network]"), "no network settings")
