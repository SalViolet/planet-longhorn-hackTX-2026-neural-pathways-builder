class_name TaskConst
extends RefCounted
## Values shared by every task.

const USEC_PER_MS := 1000
const ANTICIPATORY_RT_MS := 100 # Responses faster than this are flagged, never deleted.

# Thin progress bar at the top of a task. It only steps between trials; nothing animates.
# Turn it off here if it turns out to be a distraction. CPT never shows it.
const SHOW_PROGRESS_BAR := true
const PROGRESS_BAR_HEIGHT := 12.0
const PROGRESS_BAR_MARGIN := 24.0

# Skipping a game. The corner button is small, dim and never changes, and Esc / the gamepad's
# back button do the same. Either one only opens a warning when the player asks for it.
const SHOW_SKIP_BUTTON := true
const SKIP_BUTTON_TEXT := "Skip"
const SKIP_BUTTON_SIZE := Vector2(170, 56)
const SKIP_BUTTON_FONT_SIZE := 28
const SKIP_BUTTON_ALPHA := 0.55
const SKIP_BUTTON_TOP := 56.0
const SKIP_HEADING := "SKIP THIS GAME?"
const SKIP_WARNING := "Your progress in this game will be lost, and it will not count toward finishing the quest.\nYou will have to play it later."
const SKIP_KEEP_TEXT := "Keep playing"
const SKIP_CONFIRM_TEXT := "Skip game"
const SKIP_PANEL_MIN_WIDTH := 1000.0

# Gentle cue after a response: green glow when right, orange glow when not around the screen edge and a low soft tone.
# Never words, never over the middle of the screen, shown on the response only.
const COLOR_MISTAKE := Color(1.0, 0.55, 0.15, 0.8)
const COLOR_CORRECT := Color(0.25, 0.9, 0.4, 0.8)
const TOO_SLOW_TEXT := "Too slow!"
const TEXT_RIGHT := "Right!"
const TEXT_TRY_AGAIN := "Not that one"
# Feedback text sits in a fixed line at the top of the screen (not a popup), under the progress bar.
const FEEDBACK_FONT_SIZE := 56
const FEEDBACK_TEXT_TOP := 56.0
const MISTAKE_CUE_MS := 700
const MISTAKE_CUE_BANDS := 8
const MISTAKE_CUE_BAND_WIDTH := 14.0
const MISTAKE_TONE_HZ := 196.0
const MISTAKE_TONE_SECONDS := 0.35
const MISTAKE_TONE_RATE := 22050
const MISTAKE_TONE_DECAY := 7.0
const MISTAKE_TONE_VOLUME := 0.35

# The big push button for one-tap tasks (Go/No-Go, CPT).
const PAD_SIZE := Vector2(560, 160)
const PAD_BOTTOM_MARGIN := 60.0
const PAD_DEPTH := 16.0
const PAD_RADIUS := 36
const PAD_FLASH_MS := 160
const PAD_FONT_SIZE := 56
const COLOR_PAD_SIDE := Color("1f3d44")
const COLOR_PAD_TEXT := Color("0b1a1f")

# Why a trial was logged as invalid.
const REASON_FOCUS_LOST := "window_focus_lost"
const REASON_PLAYER_EXIT := "player_exit"
const REASON_SKIP_PROMPT := "skip_prompt" # The player opened the skip warning mid-trial.
const REASON_FRAME_SKIPPED := "frame_skipped" # A very long frame jumped over the whole trial.


static func us_to_ms(microseconds: int) -> int:
	return roundi(float(microseconds) / USEC_PER_MS)
