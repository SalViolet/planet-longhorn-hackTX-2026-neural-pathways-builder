class_name GoNoGoConst
extends RefCounted
## Go/No-Go (herd rescue): spec values, visuals and text in one place.
## Spec values are starting points to tune in playtesting.

const TASK_NAME := "gonogo"
const MISSION_ID := "go_nogo" # Matches the mission id in StoryData.

const DEFAULT_PARAMS := {
	"trials": 60,
	"practice_trials": 10,
	"fixation_ms": 500,
	"stimulus_ms": 500,
	"isi_min_ms": 1000,
	"isi_max_ms": 1500,
	"go_probability": 0.75,
	"max_consecutive_nogo": 3,
}

const LEAD_IN_MS := 800 # Blank pause after Start, and after an aborted trial.

# --- Text (shown only outside trials) ---
const HEADING_TEXT := "HERD THE CALVES"
const INSTRUCTIONS_TEXT := "Tap when you see a friendly calf.\nDo NOT tap the snakes!\n\nPush the big button, or press Space."
const BREAK_HEADING_TEXT := "PRACTICE DONE"
const BREAK_TEXT := "Now for the real roundup.\nSame rules: calves yes, snakes no."
const START_PRACTICE_TEXT := "Start practice"
const PAD_TEXT := "HERD!"
const COLOR_PAD := Color("2cf5c8")
const START_MAIN_TEXT := "Start roundup"
const SKIP_PRACTICE_TEXT := "Skip practice"
const OVERLAY_TEXT_MIN_WIDTH := 900.0
const RESULTS_TEXT_MIN_WIDTH := 760.0

# --- Stimulus drawing (character units, about 340 tall; scaled by screen height / 1080) ---
const SCREEN_UNIT_HEIGHT := 1080.0
const FIXATION_ARM := 42.0
const FIXATION_WIDTH := 7.0
const COLOR_FIXATION := Color(1.0, 1.0, 1.0, 0.85)

const CALF_SCALE := 1.15 # Calf size relative to the screen unit.
const CALF_FEET_OFFSET := 175.0 # Where the calf's feet are, below the center (screen units).
const COLOR_EYE := Color("1a1330")

const COLOR_SNAKE_BODY := Color("2f9e44")
const COLOR_SNAKE_PATTERN := Color("a6e22e")
const COLOR_SNAKE_EYE := Color("ffe66d")
const COLOR_SNAKE_ANGER := Color("d6336c")
const SNAKE_CENTER_SHIFT := -45.0 # Moves the snake left so head and tail balance around the center.
const SNAKE_STEPS := 40
const SNAKE_HALF_LENGTH := 150.0
const SNAKE_WAVE_PERIOD := 40.0
const SNAKE_WAVE_HEIGHT := 50.0
const SNAKE_BODY_WIDTH := 46.0
const SNAKE_PATTERN_WIDTH := 16.0
