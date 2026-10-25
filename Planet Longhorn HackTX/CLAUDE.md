# Planet Longhorn

At the start of every session, read `docs/GAME_DESIGN.md` before doing anything else.

A kid-friendly Godot 4 adventure game that wraps cognitive tasks (Corsi, Go/No-Go, DCCS, CPT) in a story. The full design, task specs, and milestone list are in `docs/GAME_DESIGN.md`.

## Working with the owner

- The owner is a beginner. Explain what you do in plain language and keep changes small.
- Do not build gameplay or a milestone until the owner says go.
- Tell the owner when to commit to git. Do not commit on your own.
- After each milestone, tell the owner how to run it on a Mac, which files changed, and what to check.
- Remind the owner to decide each open question (see the design doc) before the milestone it affects.
- Never claim the game diagnoses anything or trains the brain. The honest wording is "adjusts the challenge".

## Decisions already made (details in `docs/GAME_DESIGN.md`)

- Design target age 6-12, with two approved age bands: Band A (6-8) and Band B (9-12). The current build has no age-band screen, stores no age band, and only implements Band B task values. Band A values are approved for future implementation.
- Game first, measurement second. Metrics are for tuning only and are never shown to the player as an assessment. Calibration runs (fixed parameters) stay separate from story missions.
- Design for 6-12: nothing required to read for Band A, large one-tap targets (tablet + mouse), 5-10 minute sessions with a natural stopping point, positive feedback only (never "wrong" or "failed"), Corsi uses ONE tone for every stone, "juice" only on the response and at the reward moment, never during the stimulus period.
- Privacy: no accounts, network calls, analytics, ads or third-party SDKs; saved data stays local. Current profiles ask for a nickname and avatar, with no age field. A clinician-report button exists, but no general dashboard or adult-question gate is implemented. Legal review is still required before any child outside the owner's household plays.
- Adaptive engine: difficulty keeps accuracy about 75-85%, exposure favors weaker domains with a minimum share, difficulty never changes mid-run, and Band A must never feel like a string of failures.
- Approved but not yet built: ranch/herd meta-loop, story skins, mystery story arc, pacing rule, playtest mode with observer notes, full developer dashboard, adult-question gate, age-band support, and voiceover. Do not build a milestone until the owner says go.
- Milestone order: 1 start screen, 2 foundation, 3 Corsi, 4 Go/No-Go, playtest with real kids, 5 DCCS, 6 CPT, 7 adaptive engine with age bands, 7b dashboard (open access), 8 story layer and meta-loop, 9 art/audio/voiceover/polish, 10 privacy and legal review.
- Where the current build has not caught up with approved decisions, see "Approved decisions not yet implemented" in the design doc. Ask the owner before changing code for any of them.

## Where things live

- `scripts/tasks/<task>/`: each task's pure logic (`*_session.gd`, `*_sequence.gd`, `*_clock.gd`, `*_constants.gd`), plus its view and task script. Scenes are in `scenes/tasks/`.
- `scripts/adaptive/`: skill model helpers, staircase, difficulty ladders, mission scheduler, and the saved file.
- `scripts/story/`: story text and missions (`story_data.gd`), flow, rules, progress, and the placeholder stage art.
- `scripts/profiles/`: player profiles (rules, store, screen). Each profile's saves live in their own folder; the nickname is indexed in `profiles.cfg` and copied into a report only when one is generated.
- `scripts/points/`: daily points (100 per task, 500 bonus for all four) and the calf that offers them. `scripts/sample/`: made-up play for the "Sample" player.
- `scripts/reports/`: run history and the profile progress report (descriptive only, no diagnosis, no norm scores).
- `docs/PRIVACY_AND_ETHICS.md`: read before any child plays or any data leaves the device.

## Running the tests

From the project folder (needs the `godot` command; on a Mac, the path inside Godot.app works too):

`godot --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json`

The tests live in `tests/unit/`. Run them after any change to trial logic. GUT is in `addons/gut/`.

## Code rules

- Godot 4.x, GDScript, static typing.
- Tasks extend `TaskModule` with `start(params: Dictionary)` and a `finished(results: Dictionary)` signal.
- Trial logic lives in pure `RefCounted` classes with no node dependencies, tested with GUT. Presentation lives in separate scenes and scripts.
- Trial-critical timing uses `Time.get_ticks_usec()` and `_process` delta accumulation, not tweens or await timers.
- No dialogue, popups, or animated distractions during trials. Themed art only as the stimuli. Theming never changes timing or trial structure.
- Responses under 100 ms are flagged as anticipatory, not deleted. If the window loses focus mid-trial, abort and log the trial as invalid.
- No magic numbers: colors, durations, and sizes go in constants files. Placeholder art only.
- Keep UI logic out of global scripts. The only autoloads are `SceneTransition`, `Settings`, `Music` (looping background track, quieter in tasks) and `Metrics` (running totals and last values of every results-screen number, in `scripts/metrics.gd`).
