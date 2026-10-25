class_name ReportConst
extends RefCounted
## The progress report: what is saved per run, which numbers appear, and the thresholds used.

const HISTORY_FILE := "run_history.json"
const GUEST_HISTORY_PATH := "user://run_history.json" # Used when no profile is active.
const REPORT_DIR_NAME := "reports"

# --- Button and panel text (hub) ---
const BUTTON_TEXT := "Clinician report"
const PANEL_HEADING := "REPORT READY"
const PANEL_BODY := "Saved as a web page on this device, with a day-by-day spreadsheet file (CSV) next to it. Open the page to read it, or print it to PDF from the browser.\nNothing was sent anywhere."
const PANEL_FAILED_HEADING := "NO REPORT YET"
const COPY_TEXT := "Copy file location"
const COPIED_TEXT := "Copied!"
const CLOSE_TEXT := "Close"
const PANEL_MIN_WIDTH := 1100.0

# A trend needs this many runs, and a change smaller than this share of the earlier mean is "similar".
const MIN_RUNS_FOR_TREND := 4
const TREND_CHANGE_FRACTION := 0.10
# Data-quality notes appear when more than this share of trials is affected.
const INVALID_SHARE_CONCERN := 0.10
const ANTICIPATORY_SHARE_CONCERN := 0.10

# A value of exactly 0 for these means "not measurable in that run" and is left out of summaries.
const ZERO_MEANS_NA: Array[String] = [
	"rt_mean_ms", "rt_sd_ms", "rt_cv", "pre_rt_ms", "post_rt_ms", "mixed_rt_ms",
	"switch_cost_rt_ms", "mixing_cost_rt_ms",
]

# Metric kinds: "count", "percent" (stored 0-1), "ms", "score" (two decimals).
const TASKS: Array[Dictionary] = [
	{
		"id": "corsi", "title": "Corsi block-tapping (drum stones)", "domain": "Visuospatial working memory",
		"paradigm": "Repeat a sequence of tapped locations; the sequence gets longer after success.",
		"metrics": [
			{"key": "max_span", "label": "Longest span", "kind": "count"},
			{"key": "corsi_score", "label": "Corsi score (span x correct trials)", "kind": "count"},
			{"key": "mean_accuracy", "label": "Position accuracy", "kind": "percent"},
			{"key": "correct_trials", "label": "Correct trials", "kind": "count"},
		],
	},
	{
		"id": "go_nogo", "title": "Go/No-Go (herd the calves)", "domain": "Response inhibition",
		"paradigm": "Respond to frequent 'go' stimuli and withhold the response to rare 'no-go' stimuli.",
		"metrics": [
			{"key": "accuracy", "label": "Accuracy", "kind": "percent"},
			{"key": "hit_rate", "label": "Hit rate (go trials)", "kind": "percent"},
			{"key": "commission_rate", "label": "Commission rate (responded to no-go)", "kind": "percent"},
			{"key": "d_prime", "label": "d-prime", "kind": "score"},
			{"key": "rt_mean_ms", "label": "Mean reaction time (hits)", "kind": "ms"},
			{"key": "rt_sd_ms", "label": "Reaction time SD", "kind": "ms"},
		],
	},
	{
		"id": "dccs", "title": "Dimensional Change Card Sort (sorting day)", "domain": "Cognitive flexibility",
		"paradigm": "Sort items by one rule (colour), then a different rule (shape), then a mix of both.",
		"metrics": [
			{"key": "accuracy", "label": "Accuracy (all blocks)", "kind": "percent"},
			{"key": "pre_accuracy", "label": "Accuracy, colour block", "kind": "percent"},
			{"key": "post_accuracy", "label": "Accuracy, shape block", "kind": "percent"},
			{"key": "mixed_accuracy", "label": "Accuracy, mixed block", "kind": "percent"},
			{"key": "mixed_rt_ms", "label": "Reaction time, mixed block", "kind": "ms"},
			{"key": "switch_cost_rt_ms", "label": "Switch cost (reaction time)", "kind": "ms"},
			{"key": "mixing_cost_rt_ms", "label": "Mixing cost (reaction time)", "kind": "ms"},
			{"key": "perseverative_errors", "label": "Errors that kept the old rule", "kind": "count"},
		],
	},
	{
		"id": "cpt", "title": "Continuous Performance Test (night watch)", "domain": "Sustained attention",
		"paradigm": "Respond to a rare target in a long stream of non-targets.",
		"metrics": [
			{"key": "hit_rate", "label": "Hit rate (targets)", "kind": "percent"},
			{"key": "commission_rate", "label": "Commission rate (responded to non-target)", "kind": "percent"},
			{"key": "d_prime", "label": "d-prime", "kind": "score"},
			{"key": "criterion", "label": "Response criterion", "kind": "score"},
			{"key": "rt_mean_ms", "label": "Mean reaction time (hits)", "kind": "ms"},
			{"key": "rt_sd_ms", "label": "Reaction time SD", "kind": "ms"},
			{"key": "rt_cv", "label": "Reaction time variability (CV)", "kind": "score"},
		],
	},
]

const GLOSSARY: Array[Array] = [
	["d-prime", "Sensitivity: how well targets are told apart from non-targets. Higher is better. Corrected so perfect scores stay finite."],
	["Response criterion", "Response bias. Negative values mean a liberal tendency to respond, positive values a cautious one."],
	["Commission", "A response to something that should have been left alone."],
	["Omission", "No response to something that needed one."],
	["Switch cost", "Extra reaction time when the rule changes compared with when it repeats (mixed block)."],
	["Mixing cost", "Extra reaction time in the mixed block compared with single-rule blocks."],
	["Reaction time CV", "Reaction time SD divided by the mean reaction time; a measure of how steady the responses were."],
	["Corsi score", "Longest span multiplied by the number of correct trials."],
	["Anticipatory response", "A response faster than 100 ms. Kept in the data and flagged; left out of reaction-time averages."],
]
