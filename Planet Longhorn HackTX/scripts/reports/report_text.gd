class_name ReportText
extends RefCounted
## Fixed wording for the progress report. These sentences state what the report is NOT, so
## they use words the ethics test otherwise bans in game files; this file is the one exception
## and the test checks that it still says "not a diagnosis".

const TITLE := "Cognitive Task Performance Summary"
const SUBTITLE := "Game-based tasks, summarised across all play on this profile"

const LIMITS_HEADING := "Purpose and limits of this report"
const LIMITS: Array[String] = [
	"This is a descriptive summary of how this player performed on game-based versions of four well-known cognitive tasks. It is not a diagnosis, not a clinical or psychological assessment, and it does not measure intelligence.",
	"There are no age norms behind these numbers. Nothing here is a percentile or a standard score, and results cannot be compared with published test norms or with other players.",
	"The tasks are not given under standardised conditions. A story, feedback and sound surround them, the difficulty adjusts between runs, and the setting (supervision, device, time of day, tiredness, help given) is unknown.",
	"The game adjusts the challenge. It does not claim to improve any ability or to treat anything. Any concern about a child's attention, memory, learning or behaviour should go to a qualified professional, who will use their own tests.",
]

const CAUTIONS_HEADING := "Notes for the reviewing professional"
const CAUTIONS: Array[String] = [
	"Difficulty changes between runs, so a change in accuracy or speed may reflect a harder or easier level rather than a change in ability. The level is shown for every run.",
	"Practice effects are expected: scores usually rise a little with repeat play.",
	"Short runs give noisy estimates. Treat a single run as an observation, not a measurement.",
	"Trends are only shown with several runs, and describe this player's own earlier and later runs.",
]
