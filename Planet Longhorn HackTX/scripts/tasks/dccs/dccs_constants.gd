class_name DccsConst
extends RefCounted
## DCCS (sorting day): spec values, visuals and text in one place.
## Spec values (block sizes, switch probability) come from the design doc. The timing values
## (cue, timeout, ITI) are my starting choices, since the spec does not give them: tune them.

const TASK_NAME := "dccs"
const MISSION_ID := "dccs" # Matches the mission id in StoryData.

const DEFAULT_PARAMS := {
	"pre_trials": 12,
	"post_trials": 12,
	"mixed_trials": 32,
	"switch_probability": 0.5,
	"conflict_probability": 0.5, # Share of conflict trials in the mixed block. Pre and post blocks are all conflict.
	"cue_ms": 700,
	"response_timeout_ms": 4000,
	"iti_ms": 600,
}

# Gifts are shuffled for real, but never more than this many identical gifts in a row.
const MAX_SAME_STIMULUS_IN_ROW := 3
const SHUFFLE_ATTEMPTS := 200

const LEAD_IN_MS := 800 # Blank pause after Start, and after an aborted trial.

# --- Text (shown only outside trials) ---
const HEADING_TEXT := "SORTING DAY"
const BLOCK_TEXT := {
	"pre": "Sort each gift into the pen with the SAME COLOR.\nBlue goes left, orange goes right.\n\nPush the pen button (the card in the pen), or press the left and right arrow keys.",
	"post": "New rule!\nNow sort by SHAPE.\nStars go left, round gifts go right.",
	"mixed": "Now the rule can change.\nCheck the sign above each gift:\ncolor drops mean COLOR, shapes mean SHAPE.",
}
const START_TEXT := "Start"
const CONTINUE_TEXT := "Continue"
const OVERLAY_TEXT_MIN_WIDTH := 1000.0
const RESULTS_TEXT_MIN_WIDTH := 860.0

# --- Drawing (character units, scaled by screen height / 1080) ---
const SCREEN_UNIT_HEIGHT := 1080.0
const COLOR_BLUE := Color("3b82f6") # Blue and orange stay easy to tell apart for colour-blind players.
const COLOR_ORANGE := Color("ff9f1c")
const COLOR_CARD := Color("f4f1ff")
const COLOR_CARD_EDGE := Color("5a4a7a")
const COLOR_FENCE := Color("c9a46a")
const COLOR_FENCE_DARK := Color("8a6a3a")
const COLOR_CUE_LINE := Color("d8fff4")
const CARD_SIZE := 230.0
const STIMULUS_SCALE := 1.0
const PEN_X := 0.2 # Pen centers as a fraction of screen width.
const PEN_Y := 0.62
const PEN_SIZE := Vector2(520, 520)
const PEN_TARGET_SCALE := 0.62
# The pens are push buttons: the card sinks by BUTTON_DEPTH when pressed.
const BUTTON_DEPTH := 18.0
const PRESS_FLASH_MS := 160
const PEN_FILL := 0.25
const PEN_FILL_HOVER := 0.4
const PEN_FILL_PRESSED := 0.55
const COLOR_BUTTON_SIDE := Color("5a4a7a")
const STIMULUS_Y := 0.4
const CUE_Y := 0.16
const CUE_BIG_SCALE := 1.0
const CUE_SMALL_SCALE := 0.45
const STAR_POINTS := 5
const STAR_INNER_RATIO := 0.45
