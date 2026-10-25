class_name PointsConst
extends RefCounted
## Daily points: values, saved file and wording in one place.

const POINTS_PER_TASK := 100
const EXTRA_GOOD := 25 # Added to the 100 for a "good" run.
const EXTRA_GREAT := 50 # Added to the 100 for a "great" run.
const DAILY_BONUS := 500
# The tasks that count each day. Finishing a run counts, however it went.
const REQUIRED_TASKS: Array[String] = ["corsi", "go_nogo", "dccs", "cpt"]

const DEFAULT_PATH := "user://points.cfg" # Used when no profile is active.
const FILE_NAME := "points.cfg"

# --- Wording (the calves do the talking) ---
const OFFER_TASK_FORMAT := "Moo! %d points!" # Base points plus any extra for a good or great run.
const OFFER_BONUS_FORMAT := "All four done today!\n+%d bonus!"
const OFFER_EXTRA_GOOD_FORMAT := "Good herding! +%d"
const OFFER_EXTRA_GREAT_FORMAT := "Great herding! +%d"
const OFFER_REPEAT_TEXT := "Nice herding! Today's points for this one are already yours."
const OFFER_NONE_TEXT := ""
const SUMMARY_FORMAT := "Today: %d of %d done\nPoints: %d"
const SUMMARY_DONE_FORMAT := "All done today!\nPoints: %d"
const SUMMARY_HINT_FORMAT := "\nFinish all %d for +%d!"

# --- Look ---
const OFFER_CALF_SIZE := Vector2(200, 250)
const OFFER_CALF_SCALE := 0.5
const OFFER_FONT_SIZE := 32
const OFFER_TEXT_WIDTH := 320.0
const OFFER_SEPARATION := 8
const OFFER_COLOR := Color("ffd27d")
