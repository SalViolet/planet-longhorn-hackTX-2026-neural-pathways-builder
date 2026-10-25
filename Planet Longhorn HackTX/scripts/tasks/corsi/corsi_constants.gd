class_name CorsiConst
extends RefCounted
## Corsi block-tapping: rules, layout, timings and visuals in one place.

const TASK_NAME := "corsi"
const MISSION_ID := "corsi" # Matches the mission id in StoryData.

# --- Rules ---
const MAX_SPAN := 9
const TRIALS_PER_SPAN := 2
const DEFAULT_PARAMS := {
	"start_span": 2,
	"item_duration_ms": 1000,
	"gap_ms": 250,
}

# --- Timing (ms) ---
const PRE_TRIAL_MS := 1000
const INTER_TRIAL_MS := 900
const TAP_HIGHLIGHT_MS := 250

# --- Layout ---
# Block centers relative to the board center. Irregular on purpose; keep them
# at least BLOCK_SIZE apart (the logic test checks this).
const BOARD_SIZE := Vector2(1500, 800)
const BLOCK_SIZE := 150.0
const BLOCK_POSITIONS: Array[Vector2] = [
	Vector2(-560, -250), Vector2(-180, -300), Vector2(260, -260),
	Vector2(600, -170), Vector2(-400, -20), Vector2(60, 10),
	Vector2(430, 150), Vector2(-250, 260), Vector2(150, 300),
]
const INITIAL_FOCUS_BLOCK := 5 # Where keyboard/gamepad focus starts for each response.

# --- Drum stone drawing ---
const COLOR_STONE_RIM := Color("2b2438")
const COLOR_STONE_FACE := Color("3a3149")
const COLOR_STONE_FACE_LIT := Color("7dffe6")
const COLOR_STONE_RING := Color("1d1829")
const COLOR_STONE_EDGE := Color("5c4a7a")
const COLOR_STONE_EDGE_LIT := Color("c8fff4")
const COLOR_STONE_HIGHLIGHT := Color(1.0, 1.0, 1.0, 0.12)
const COLOR_STONE_GLOW := Color(0.17, 0.96, 0.78, 0.16)
const STONE_FACE_RATIO := 0.78 # Drum top, as a share of the stone radius.
const STONE_RING_RATIO := 0.6
const STONE_HIGHLIGHT_RATIO := 0.88
const GLOW_LAYERS := 4
const GLOW_STEP := 0.14
const EDGE_WIDTH := 3.0
const ARC_SEGMENTS := 64
const FOCUS_RING_SCALE := 1.28
const FOCUS_RING_WIDTH := 5.0

# --- Drum sound (generated; the same thump for every stone) ---
const DRUM_MIX_RATE := 22050
const DRUM_SECONDS := 0.4
const DRUM_START_HZ := 190.0
const DRUM_END_HZ := 70.0
const DRUM_PITCH_DECAY := 25.0 # Per second.
const DRUM_AMP_DECAY := 9.0
const DRUM_NOISE_AMOUNT := 0.25 # Short click at the start of the hit.
const DRUM_NOISE_DECAY := 80.0
const DRUM_VOLUME := 0.8
const DRUM_POLYPHONY := 4

# --- HUD ---
const STATUS_WATCH := "WATCH"
const STATUS_REPEAT := "REPEAT"
const STATUS_NONE := ""
const RESULTS_TEXT_MIN_WIDTH := 760.0
