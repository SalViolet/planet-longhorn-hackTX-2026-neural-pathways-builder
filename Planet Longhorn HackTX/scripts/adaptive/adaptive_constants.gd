class_name AdaptiveConst
extends RefCounted
## Settings for the adaptive engine. All starting values: tune them in playtesting.

# Skill domain for each story mission.
const MISSION_DOMAINS := {
	"corsi": "memory",
	"go_nogo": "inhibition",
	"dccs": "flexibility",
	"cpt": "attention",
}

# --- Skill estimates (0-1) ---
const PRIOR_SKILL := 0.5
const MIN_LEARNING_RATE := 0.3 # The first run replaces the prior; later runs blend in at least this much.
const SCORE_DPRIME_MAX := 4.0 # d-prime that counts as a score of 1.0.

# --- Staircase (levels go up = harder) ---
const HARDER_AFTER_SUCCESSES := 2 # Two good runs in a row -> harder.
const EASIER_AFTER_FAILURES := 1 # One poor run -> easier.
const MAX_INVALID_SHARE := 0.2 # A run with more invalid trials than this does not move the staircase.

# What counts as a good or poor run, per task. Between the two counts as neutral.
const CORSI_SUCCESS_MARGIN := 2 # Reached at least start span + this.
const GONOGO_SUCCESS_ACCURACY := 0.85
const GONOGO_FAILURE_ACCURACY := 0.70
const DCCS_SUCCESS_ACCURACY := 0.90 # Accuracy in the mixed block.
const DCCS_FAILURE_ACCURACY := 0.70
const CPT_SUCCESS_DPRIME := 3.5
const CPT_FAILURE_DPRIME := 2.0

# --- Placement: the first finished run of a game picks the starting level from performance ---
const PLACEMENT_GREAT_STEP := 2 # A great first run moves up this many levels, a very poor one down this many.
const PLACEMENT_GOOD_STEP := 1
const CORSI_GREAT_MARGIN := 4 # Reached start span + this.
const GONOGO_GREAT_ACCURACY := 0.95
const GONOGO_VERY_POOR_ACCURACY := 0.50
const DCCS_GREAT_ACCURACY := 0.97
const DCCS_VERY_POOR_ACCURACY := 0.50
const CPT_GREAT_DPRIME := 4.2
const CPT_VERY_POOR_DPRIME := 1.0

# --- Mission scheduler ---
const WEIGHT_FLOOR := 0.15 # Strong domains still get picked sometimes.
const NOVELTY_BONUS := 0.5 # Extra weight for a mission never played.
const REPEAT_PENALTY := 0.25 # The mission just played is much less likely to come up again.

const SKILL_PATH := "user://adaptive.cfg"


static func domain_of(mission_id: String) -> String:
	return String(MISSION_DOMAINS.get(mission_id, ""))
