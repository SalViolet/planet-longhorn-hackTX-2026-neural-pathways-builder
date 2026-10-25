class_name CptConst
extends RefCounted
## CPT (night watch): spec values, visuals and text in one place.
## Nothing on screen changes during a run except the glyph itself.

const TASK_NAME := "cpt"
const MISSION_ID := "cpt" # Matches the mission id in StoryData.

# Default run: 5 minutes = duration_ms / trial_ms trials. Pass "trials" to fix the count instead.
const DEFAULT_PARAMS := {
	"duration_ms": 300000,
	"stimulus_ms": 250,
	"trial_ms": 2000,
	"target_probability": 0.10,
}
const DEV_TRIALS := 30 # Dev mode: a short run for testing (shown in debug builds only).

const GLYPH_COUNT := 9 # Glyph ids 0-7 are eight different-looking cows; the last id is the thief, a cow in a ski mask.
const TARGET_GLYPH := 8
const TIME_BINS := 5 # Results are also reported in this many equal slices of the run.
const LEAD_IN_MS := 1500 # Quiet pause after Start, and after the window comes back.

# --- Text (shown only outside the run) ---
const HEADING_TEXT := "NIGHT WATCH"
const PAD_TEXT := "FLASHLIGHT!"
const COLOR_PAD := Color("ffe27a")
const INSTRUCTIONS_TEXT := "Guard the herd by the quiet stream.\nCows will wander by in the dark. Ignore them.\nShine your flashlight ONLY when you see the cow in the ski mask.\n\nPush the big button, or press Space."
const START_TEXT := "Start watch"
const DEV_START_TEXT := "Quick test (30 trials)"
const OVERLAY_TEXT_MIN_WIDTH := 1000.0
const RESULTS_TEXT_MIN_WIDTH := 900.0

# --- Drawing (units, scaled by screen height / 1080) ---
const SCREEN_UNIT_HEIGHT := 1080.0
const GLYPH_RADIUS := 110.0
const COLOR_GLYPH := Color("cfe4ff")
const COLOR_EYE_HOLE := Color("1a1330")
# The flashlight beam shown when the player pushes the button.
const BEAM_MS := 250
const BEAM_ORIGIN_FROM_BOTTOM := 230.0
const BEAM_BASE := 70.0
const BEAM_SPREAD := 1.7
const COLOR_BEAM := Color(1.0, 0.95, 0.6, 0.28)
const COLOR_FIXATION := Color(1.0, 1.0, 1.0, 0.35)
const FIXATION_RADIUS := 7.0
const COLOR_STREAM := Color(0.45, 0.65, 0.9, 0.18)
const STREAM_LINES := 5
const STREAM_TOP := 0.72 # Fraction of screen height where the stream starts.
const STREAM_SPACING := 0.045
const STREAM_STEPS := 48
const STREAM_WAVE_PERIOD := 160.0
const STREAM_WAVE_HEIGHT := 14.0
const STREAM_LINE_WIDTH := 5.0
