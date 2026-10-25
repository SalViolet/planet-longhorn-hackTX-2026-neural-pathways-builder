class_name StoryConst
extends RefCounted
## Sizes, colors and thresholds for the story layer. Story text lives in StoryData.

# --- Dialogue box ---
const TYPEWRITER_CHARS_PER_SECOND := 45.0
const BOX_PADDING := 28
const BOX_SEPARATION := 12
const NAME_FONT_SIZE := 44
const TEXT_FONT_SIZE := 40
const TEXT_MIN_HEIGHT := 150.0
const BUTTON_MIN_SIZE := Vector2(240, 72)
const CONTINUE_TEXT := "Continue"
const SKIP_TEXT := "Skip"

# --- Dialogue polish ---
const BLIP_EVERY_CHARS := 2 # One typing sound per this many letters.
const BLIP_SECONDS := 0.07
const BLIP_MIX_RATE := 22050
const BLIP_VOLUME := 0.3
const BLIP_PITCH_JITTER := 0.08
const BOX_POP_SECONDS := 0.12
const BOX_POP_START_SCALE := 0.96
const CHOICE_BUTTON_MIN_SIZE := Vector2(1100, 76)
const MARKER_SIZE := Vector2(40, 36)
const MARKER_BOB_PIXELS := 6.0
const MARKER_BOB_SPEED := 6.0
const COLOR_MARKER := Color("c6ff3d")

# --- Stage animation ---
const ENTER_SECONDS := 0.5 # Characters slide in when they first appear.
const ENTER_DISTANCE := 260.0
const BLINK_PERIOD := 3.6
const BLINK_SECONDS := 0.14
const TALK_SPEED := 14.0 # Mouth flaps per second while a character is talking.
const SHAKE_SECONDS := 0.45
const SHAKE_PIXELS := 14.0
const PULSE_SECONDS := 0.9
const PULSE_GROW := 130.0
const PULSE_START_RADIUS := 34.0

# --- Hub ---
const HUB_MISSION_MIN_SIZE := Vector2(980, 124)
const HUB_SEPARATION := 20
const HUB_SMALL_BUTTON_SIZE := Vector2(300, 64)
const HUB_BAR_SIZE := Vector2(980, 22)
const HUB_PROGRESS_FORMAT := "Quest progress: %d of %d missions"
const HUB_SUBTITLE := "Choose your next mission"
const HUB_SUBTITLE_DONE := "Quest complete! Replay any mission."
const HUB_NEXT_MARK := "  (up next)"
const HUB_SUBTITLE_SKIPPED := "Play every game to finish the quest."
const HUB_SKIPPED_TEXT := "  (skipped)"

# --- How the elders react to a run (Corsi: max span reached; Go/No-Go: accuracy) ---
const BAND_GREAT_MIN_SPAN := 6
const BAND_GOOD_MIN_SPAN := 4
const BAND_GREAT_MIN_ACCURACY := 0.9 # Go/No-Go: share of trials answered correctly.
const BAND_GOOD_MIN_ACCURACY := 0.75
const BAND_GREAT_MIN_DPRIME := 3.5 # CPT: d-prime.
const BAND_GOOD_MIN_DPRIME := 2.0
const BAND_DEFAULT := "good"

# --- Placeholder stage art ---
const CHARACTER_SCALE := 1.15
const CHARACTER_DIM := 0.62 # Brightness of characters who are not speaking.
const BOB_SPEED := 5.0
const BOB_PIXELS := 6.0
const GROUND_LINE := 0.62 # Characters stand here (fraction of screen height).
const HORIZON_LINE := 0.56
const SEAM_SPACING := 240.0
const STAR_COUNT := 48

const COLOR_WALL := Color("1c1f3a")
const COLOR_WALL_SEAM := Color("2a2f55")
const COLOR_FLOOR := Color("2b2d52")
const COLOR_METAL := Color("565c8a")
const COLOR_HATCH := Color("3a4070")
const COLOR_HATCH_LIGHT := Color("2cf5c8")
const COLOR_PORTHOLE_SKY := Color("2a1b6e")
const COLOR_PLANET_RED := Color("b0405f")
const COLOR_PLANET_GREEN := Color("6fbf5a")
const COLOR_SKY_HORIZON := Color("5a2a8a")
const COLOR_GROUND := Color("a89cf0")
const COLOR_GROUND_LIGHT := Color("c9c4ff")
const COLOR_ROCK := Color("7a52d6")
const COLOR_ROCK_ICE := Color("b9c8ff")
const COLOR_HORN := Color("f3e6c8")
# Longhorn proportions (character units). Elders are tall with long horns; calves have a big head.
const ELDER_HEAD_Y := -262.0
const ELDER_HEAD_RADIUS := 78.0
const ELDER_MUZZLE_RADIUS := 44.0
const ELDER_EYE_RADIUS := 13.0
const CALF_BODY_SCALE := 0.78
const CALF_HEAD_Y := -212.0
const CALF_HEAD_RADIUS := 86.0
const CALF_MUZZLE_RADIUS := 48.0
const CALF_EYE_RADIUS := 17.0
const CALF_HORN_SCALE := 0.5
const COLOR_CALF_HIDE := Color("d9a066")
# The kid (player character): space suit, goggles on the head, gloves and boots.
const COLOR_KID_GLOVE := Color("f4f1ff")
const COLOR_KID_BOOT := Color("2a3358")
const COLOR_KID_BELT := Color("1f6b66")
const COLOR_KID_BUCKLE := Color("ffd27d")
const COLOR_KID_BADGE := Color("ffd27d")
const COLOR_KID_GOGGLE_STRAP := Color("2cf5c8")
const COLOR_KID_GOGGLE_LENS := Color("7dffe6")
const COLOR_KID_CHEEK := Color(1.0, 0.45, 0.5, 0.45)
const COLOR_EYE_WHITE := Color("ffffff")
const COLOR_EYE_DARK := Color("1a1330")
const COLOR_BEARD := Color("e8e4f0")
const COLOR_PANEL_DOT_OFF := Color("144a50")
const COLOR_PANEL_DOT_ON := Color("7dffe6")
const COLOR_NIGHT_TOP := Color("050a1f")
const COLOR_NIGHT_HORIZON := Color("16224a")
const COLOR_NIGHT_GROUND := Color("0f1a38")
const COLOR_MOON := Color("f1f0d8")
const COLOR_STREAM := Color(0.45, 0.65, 0.9, 0.35)
const COLOR_FENCE := Color("c9a46a")
const STREAM_LINES := 4
const MOON_RADIUS := 90.0
const PEN_WIDTH := 300.0
const PEN_HEIGHT := 190.0
