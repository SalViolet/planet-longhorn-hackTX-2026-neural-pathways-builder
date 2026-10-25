class_name UIConst
extends RefCounted
## Single place for palette, sizes, durations and paths. Edit here to retheme.

# --- Scene paths ---
const SCENE_START := "res://scenes/start_screen.tscn"
const SCENE_PROFILES := "res://scenes/profiles/profile_select.tscn"
const SCENE_HUB := "res://scenes/hub.tscn"
const SCENE_CORSI := "res://scenes/tasks/corsi_task.tscn"
const SCENE_GONOGO := "res://scenes/tasks/gonogo_task.tscn"
const SCENE_DCCS := "res://scenes/tasks/dccs_task.tscn"
const SCENE_CPT := "res://scenes/tasks/cpt_task.tscn"
const SCENE_DIALOGUE := "res://scenes/story/dialogue_scene.tscn"

# --- Palette (alien-tech: deep space + teal/violet, lime focus) ---
const COLOR_SPACE_TOP := Color("12062a")
const COLOR_SPACE_BOTTOM := Color("031f26")
const COLOR_NEBULA_TEAL := Color(0.05, 0.62, 0.6, 0.28)
const COLOR_NEBULA_PURPLE := Color(0.5, 0.15, 0.8, 0.26)
const COLOR_STAR := Color("d8fff4")
const COLOR_FADE := Color("02030a")
const COLOR_DIMMER := Color(0.0, 0.0, 0.03, 0.7)

const COLOR_ACCENT := Color("2cf5c8")
const COLOR_ACCENT_ALT := Color("b44cff")
const COLOR_FOCUS := Color("c6ff3d")
const COLOR_TEXT := Color("d8fff4")
const COLOR_TEXT_DIM := Color("7fb5ab")
const COLOR_TEXT_DISABLED := Color("46635e")
const COLOR_TITLE_GLOW := Color("2cf5c8")

const COLOR_PANEL_FILL := Color(0.04, 0.09, 0.12, 0.92)
const COLOR_PANEL_BORDER := Color("1f6b66")
const COLOR_BUTTON_NORMAL := Color(0.05, 0.13, 0.16, 0.9)
const COLOR_BUTTON_HOVER := Color(0.08, 0.24, 0.27, 0.95)
const COLOR_BUTTON_PRESSED := Color(0.1, 0.4, 0.42, 1.0)
const COLOR_BUTTON_DISABLED := Color(0.05, 0.08, 0.09, 0.7)
const COLOR_SLIDER_TRACK := Color(0.08, 0.18, 0.2, 1.0)

# --- Typography ---
const FONT_SIZE_BODY := 36
const FONT_SIZE_BUTTON := 40
const FONT_SIZE_TITLE := 140
const FONT_SIZE_SUBTITLE := 40
const FONT_SIZE_HEADING := 56
const FONT_SIZE_VERSION := 24
const TITLE_OUTLINE_SIZE := 14

# --- Widget sizes ---
const CORNER_RADIUS := 14
const BORDER_WIDTH := 3
const FOCUS_BORDER_WIDTH := 5
const GLOW_SIZE := 12
const BUTTON_PADDING := 16
const BUTTON_MIN_SIZE := Vector2(480, 96)
const MENU_SEPARATION := 28
const PANEL_PADDING := 48
const PANEL_SEPARATION := 36
const SETTINGS_PANEL_MIN_SIZE := Vector2(900, 0)
const SLIDER_MIN_WIDTH := 420.0
const SLIDER_TRACK_THICKNESS := 14
const SLIDER_GRABBER_RADIUS := 20
const SCREEN_MARGIN := 24

# --- Timing (seconds) ---
const FADE_IN_SECONDS := 0.8
const FADE_OUT_SECONDS := 0.45
const TITLE_PULSE_SECONDS := 2.4
const TITLE_GLOW_MIN_ALPHA := 0.25
const TITLE_GLOW_MAX_ALPHA := 0.85
const TITLE_PULSE_SCALE := 1.02

# --- Music (decibels; -80 is silent) ---
const MUSIC_PATH := "res://audio/lofi_positive.mp3"
const MUSIC_DB := -12.0 # Menus and story.
const MUSIC_TASK_DB := -34.0 # During the four tasks: a lot quieter.
const MUSIC_SILENT_DB := -60.0
const MUSIC_FADE_DB_PER_SECOND := 30.0

# --- Settings defaults ---
const DEFAULT_MASTER_VOLUME := 0.8
const DEFAULT_MUSIC_ON := true

# --- Space background ---
const NEBULA_DRIFT_SPEED := 0.05
const NEBULA_DRIFT_AMOUNT := 0.03
const NEBULA_TEXTURE_SIZE := 256
const STAR_TWINKLE_SPEED := 1.6
# Per layer: star count, drift speed (px/s at 1920 wide), size (px), max alpha.
# Far layers are slower, smaller and dimmer to read as parallax.
const STAR_LAYERS := [
	{"count": 160, "speed": 6.0, "size": 2.0, "alpha": 0.45},
	{"count": 90, "speed": 16.0, "size": 3.0, "alpha": 0.7},
	{"count": 40, "speed": 34.0, "size": 4.5, "alpha": 0.95},
]
# Per blob: center (0-1), radius (fraction of width), color, drift phase.
const NEBULA_BLOBS := [
	{"center": Vector2(0.25, 0.35), "radius": 0.5, "color": COLOR_NEBULA_PURPLE, "phase": 0.0},
	{"center": Vector2(0.75, 0.6), "radius": 0.55, "color": COLOR_NEBULA_TEAL, "phase": 2.1},
	{"center": Vector2(0.5, 0.9), "radius": 0.4, "color": COLOR_NEBULA_PURPLE, "phase": 4.2},
]
