class_name ProfileConst
extends RefCounted
## Player profiles: limits, colors, paths and text in one place.

const MAX_PROFILES := 8
const MIN_NAME_LENGTH := 1
const MAX_NAME_LENGTH := 12

const INDEX_PATH := "user://profiles.cfg"
const ROOT_DIR := "user://profiles" # One folder per profile, named by a random code.

# Avatars, picked when a profile is created. A profile saves the avatar's number (its
# "color" field, from when this was just a colour). Kids wear space suits; calves are young longhorns.
const AVATARS: Array[Dictionary] = [
	{"kind": "kid", "suit": Color("2cb5c8"), "skin": Color("f2c8a0"), "hair": Color("3b2a22"), "style": "bangs", "goggles": true},
	{"kind": "kid", "suit": Color("ff9f1c"), "skin": Color("c68642"), "hair": Color("1a1a1a"), "style": "round", "goggles": false},
	{"kind": "kid", "suit": Color("b44cff"), "skin": Color("f5d5b8"), "hair": Color("e8b84a"), "style": "spiky", "goggles": true},
	{"kind": "kid", "suit": Color("ff5fa8"), "skin": Color("8d5524"), "hair": Color("2b1a14"), "style": "puffs", "goggles": false},
	{"kind": "calf", "suit": Color("d9a066")},
	{"kind": "calf", "suit": Color("8c6aa8")},
]
const AVATAR_BACKGROUND_DARKEN := 0.55
const AVATAR_CALF_SCALE := 0.0048 # Calf size relative to the portrait radius.

# Colors behind each avatar's number are the same list as before.
const COLORS: Array[Color] = [
	Color("2cf5c8"), Color("ff9f1c"), Color("b44cff"),
	Color("ff5fa8"), Color("3b82f6"), Color("c6ff3d"),
]

# --- Text ---
const HEADING_TEXT := "WHO'S PLAYING?"
const NEW_HEADING_TEXT := "NEW PLAYER"
const NEW_HINT_TEXT := "Type a nickname (not your full name), then pick your avatar."
const NAME_PLACEHOLDER := "Nickname"
const NEW_BUTTON_TEXT := "New player"
const FULL_BUTTON_TEXT := "Players full"
const BACK_TEXT := "Back"
const CREATE_TEXT := "Create"
const CANCEL_TEXT := "Cancel"
const DELETE_TEXT := "Delete"
const KEEP_TEXT := "Keep"
const CONFIRM_FORMAT := "Delete %s and all of their progress?\nThis cannot be undone."
const ERROR_EMPTY := "Please type a nickname."
const ERROR_TOO_LONG := "That nickname is too long."
const ERROR_TAKEN := "That nickname is already used."
const ERROR_FULL := "There are too many players. Delete one first."
const PLAYER_LABEL_FORMAT := "Player: %s"
const SWITCH_TEXT := "Switch player"
const SAMPLE_NOTE_FONT_SIZE := 26
const SAMPLE_TEXT := "Add sample player"
const SAMPLE_HINT := "Adds a player called Sample with made-up play, to try the report and points."

# --- Sizes ---
const BADGE_SIZE := 84.0
const ROW_BUTTON_MIN_SIZE := Vector2(560, 96)
const DELETE_BUTTON_MIN_SIZE := Vector2(220, 96)
const LIST_MIN_SIZE := Vector2(980, 340)
const PANEL_MIN_WIDTH := 980.0
const ROW_SEPARATION := 20
const SWATCH_SIZE := 120.0 # The avatar picker buttons.
const SWATCH_SELECTED_BORDER := 8
const SWATCH_RADIUS := 60
const SWATCH_INSET := 12
const HUB_LABEL_MARGIN := 24.0
const SWITCH_BUTTON_SIZE := Vector2(300, 64)
const COLOR_BADGE_TEXT := Color("0a1220")
const COLOR_ERROR := Color("ff8fa3")
