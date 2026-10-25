# Game Design

Working notes for Planet Longhorn. Read this before making changes. Approved design goals and current implementation are labeled separately below.

## Vision

A game first: a fun, kid-friendly adventure that wraps established cognitive tasks in a story. The player is transported to a planet run by alien cartoon longhorns. Each task is a story mission. The game adjusts the challenge: more exposure to weaker domains, harder settings where the player is strong, gentler ones where they struggle.

Measurement comes second. The game records numbers so the challenge can be tuned, but it never presents them as an assessment. It never claims to diagnose anything or to train the brain. The honest wording is "adjusts the challenge". Nothing in the game text, store text, or reports may say otherwise.

## Players and age bands

**Design target: ages 6 to 12.** The approved design uses two age bands, but the current build has no age-band selection or age-band-specific settings. Profiles currently ask for a typed nickname and a chosen avatar; they do not store age.

| | Band A (ages 6-8) | Band B (ages 9-12) |
|---|---|---|
| Timing | Slower | Faster. The earlier spec values are the Band B defaults |
| Runs | Shorter, fewer trials | Longer |
| Difficulty | Smaller maximum | Full range |
| Reading | Minimal: icons and pictures, voiceover later. Text is a bonus, never a requirement | More story text |
| DCCS | One rule switch (color, then shape), larger cues | The full spec |

Each task's difficulty-to-params mapping is looked up per band. Band ranges live in constants files.

### Band defaults

Band B lists current task defaults. Band A values below are approved design choices, but are not implemented. The current build has no age-band selection.

| Task | Parameter | Band B (current) | Band A (proposed) |
|---|---|---|---|
| Corsi | stone lit / gap | 1000 ms / 250 ms | 1200 ms / 400 ms |
| Corsi | start span ladder | 2 to 5 (4 levels) | 2 to 4 (3 levels) |
| Corsi | maximum span | 9 | 5 |
| Corsi | trials per length | 2 | 2, and the run ends positively ("great drumming!") |
| Corsi | stone size | 150 | about 20% larger |
| Go/No-Go | stimulus | 500 ms | 800 ms |
| Go/No-Go | ISI | 1000-1500 ms | 1500-2000 ms |
| Go/No-Go | go probability | 0.75 | 0.70 |
| Go/No-Go | max no-go in a row | 3 | 2 |
| Go/No-Go | trials + practice | 60 + 10 | 30 + 6 |
| Go/No-Go | ladder | 5 levels | 3 levels: 1000 ms / 1800-2400 / 0.65, then 800 / 1500-2000 / 0.70 (default), then 650 / 1200-1700 / 0.75 |
| DCCS | blocks | pre 12, post 12, mixed 32 | pre 10, post 10, no mixed block |
| DCCS | cue / response timeout / gap | 700 / 4000 / 600 ms | 1200 / 6000 / 800 ms, cue about 50% larger |
| DCCS | ladder | 5 levels | 3 levels (cue 1500 / 1200 / 900 ms, timeout 7000 / 6000 / 5000 ms) |
| CPT | length | 5 minutes (150 trials) | 2 minutes (40 trials) |
| CPT | stimulus / trial | 250 ms / 2000 ms | 500 ms / 3000 ms |
| CPT | target probability | 0.10 | 0.15 |
| CPT | glyphs | 9 (8 harmless + the thief) | 6 (5 harmless + the thief) |
| CPT | ladder | 5 levels | 3 levels (trial 3500 / 3000 / 2600 ms, target 0.18 / 0.15 / 0.12) |

Estimated run length (play time only): Band B today is Corsi 1-3.5 min, Go/No-Go 2.6 min, DCCS 2.3 min, CPT 5 min. Band A proposed is Corsi up to 1.5 min, Go/No-Go 1.8 min, DCCS 1.2 min, CPT 2 min.

Note: Band A DCCS has no mixed block, so switch cost and mixing cost do not exist for Band A. Only per-phase accuracy and stuck-on-old-rule errors are recorded.

## Purpose: game first, measurement second

- It should be fun to play. Metrics are for tuning the challenge, not for showing the player.
- Approved design goal: keep raw metrics off player-facing screens and show positive rewards. The current build still shows task results and best-result numbers on the hub; the full dashboard has not been built.
- Optional fixed-parameter **calibration runs** are kept separate from story missions: same task, fixed values, no story, no effect on the story or the adaptive engine. Planned, not built.
- Never claim to diagnose or to train the brain.

## Designing for 6-12-year-olds

- Nothing required to read for Band A: icons, pictures and (later) voiceover. Text is a bonus.
- Large touch targets and simple one-tap input. Works on a tablet and with a mouse.
- Sessions of 5-10 minutes with a natural stopping point. Short missions, with the story reward after each.
- Positive, encouraging feedback only. Never "wrong" or "failed": use gentle redo language.
- The Corsi drum stones use ONE tone for every stone, so it stays a spatial task and not a melody task.
- Trial feedback ("juice") is allowed on the player's RESPONSE and at the reward moment, never during the stimulus period. Stimulus timing and trial structure never change because of theming.

## Privacy (design target includes children under 13)

- No accounts, no logins, no network calls, no analytics, no ads, no third-party SDKs.
- All data stays on the device in local save files.
- The hub currently offers a locally generated clinician report. There is no general developer dashboard and no adult-question gate on Reset story or Delete profile.
- Current profiles contain a typed nickname and chosen avatar. The game does not collect age, photos, voice, or location. A no-name, avatar-plus-age-band profile remains an approved design goal, not current behavior.
- Final legal review is part of milestone 10, before any child outside the owner's own household plays.
- More detail and the checklist: `docs/PRIVACY_AND_ETHICS.md`.

## Story

The main character is a kid transported to a planet run by alien cartoon longhorns. The cognitive tasks are woven into the story as missions.

## Missions

| Task | Domain | Mission | How it plays |
|---|---|---|---|
| Corsi block-tapping | Visuospatial working memory | **Appease the longhorns with their music** | Nine drum stones lie in fixed, irregular positions. The elders play a pattern and the player repeats it, to get out of the spaceship and earn the elders' trust. |
| Go/No-Go | Response inhibition | **Herd the calves** | The player is the herder. Friendly young longhorns (calves) are "go" (tap). Evil snakes are "no-go" (withhold). |
| DCCS | Cognitive flexibility | **Sorting day** | The elder announces a rule (color, then shape), and the rule changes. The player sorts creatures or gifts into two pens. |
| CPT | Sustained attention | **Night watch** | The player guards the herd through a long, quiet stream and shines a flashlight (pushes the big FLASHLIGHT! button) only on the rare cow in the ski mask (the thief). |

## Task specs

These are the Band B values and what is built today. Tune them in playtesting. Every value belongs in a constants file, not in code. Band A values are in the table above.

### Corsi (built)
- Start with a sequence of 2 (the engine can raise the starting length, levels 2 to 5). Two trials per length. If at least one is right, the length goes up by 1. If both are wrong, the run ends. Maximum length 9.
- Each stone lights for 1000 ms with a 250 ms gap. Taps are ignored while the pattern plays.
- No stone twice in a row within a sequence, and no repeat of the previous trial's sequence.
- Params: `start_span`, `item_duration_ms`, `gap_ms`.
- Results: max span, total correct trials, Corsi score (max span x correct trials), per-trial accuracy.

### Go/No-Go (built)
- Fixation 500 ms, stimulus 500 ms, ISI jittered 1000-1500 ms.
- Go probability 0.75. At most 3 no-go trials in a row.
- 60 trials plus 10 practice trials.
- Metrics: hits, omissions, commission errors, correct rejections, RT mean and SD, d-prime (log-linear corrected).

### DCCS (built)
- Bivalent stimuli (color x shape). A cue before every stimulus.
- Pre-switch block 12 trials, post-switch block 12 trials, mixed block 32 trials with switch probability 0.5, including conflict trials.
- Metrics: accuracy and RT per phase, switch cost, mixing cost, perseverative errors.
- Not in the spec, chosen for the first version (tune in playtesting): cue 700 ms, response timeout 4000 ms, blank gap between trials 600 ms. The sign stays on screen, small, while the gift is shown.
- Pens: the left pen's target card is a blue star, the right pen's is an orange round gift. A blue round gift or an orange star is a "conflict" gift (color and shape point to different pens). The pre and post blocks are all conflict gifts. The mixed block is half conflict.
- Definitions: a switch trial has a different rule from the trial before. Switch cost = mixed switch vs mixed repeat. Mixing cost = single-rule blocks vs mixed repeat. A perseverative error is a wrong sort on a switch trial that matches the old rule. RT figures use correct answers not flagged anticipatory.
- Response: push the left or right pen (each is a big push button; its card sinks when pressed, and it registers on the way down, not on release), or press the left and right arrow keys. Clicking elsewhere on the screen does nothing.

### CPT (built)
- 8-10 glyphs, one of them the target.
- Stimulus 250 ms, trial 2000 ms, target probability 0.10.
- Default length 5 minutes, plus a 30-trial dev mode.
- Nothing on screen changes during the run except the shape and the player's own response: the flashlight beam (250 ms) when the button is pushed, and the green/orange glow with "Right!", "Not that one" or "Too slow!" at the top (owner request, which relaxes the earlier "no feedback in CPT" rule). Green on a hit, orange on pushing for a harmless shape, orange "Too slow!" when the thief gets away. No cue for correctly ignoring a shape (it would fire on nearly every trial).
- Metrics: hits, omissions, commissions, d-prime, criterion, RT SD and CV, and results in 5 time bins.
- Not in the spec, chosen for the first version: nine glyphs: eight different-looking cows (long horns, short horns with an eye patch, no horns and floppy ears, curly horns, narrow face, chubby face, bangs, a calf) and the thief, a cow wearing a dark knitted ski mask with a pom-pom, angry eye slits and a jagged grin; all the same color and size so nothing pops out, and no two thieves in a row. Trials run on a fixed grid from the start of the run, so timing never drifts. The 30-trial dev mode shows only in debug builds, and a dev run never moves the adaptive engine.
- If the window loses focus, the trial in progress is logged as invalid and the run pauses until the window returns, then resumes after a short quiet pause.

## Adaptive engine

### The owner's two-dial spec

- **Difficulty dial:** difficulty adjusts to keep accuracy at roughly 75-85%.
- **Exposure dial:** exposure favors weaker domains, with a minimum share so no domain disappears.
- **Difficulty never changes mid-run.** It only changes between runs.
- **Per age band:** difficulty ranges and thresholds are looked up per band. For Band A, never push difficulty to a point where a session feels like a series of failures.

### What is built today (Band B values only; no age bands yet)

- `SkillModel` keeps a 0-1 estimate per domain (memory, inhibition, flexibility, attention) from the player's own results. The first run replaces the starting guess of 0.5, and later runs blend in with a learning rate of at least 0.3.
- Score per task: Corsi = max span / 9. Go/No-Go and CPT = d-prime / 4. DCCS = accuracy in the mixed block. All limited to 0-1.
- The first finished run of each task places the player on its ladder from how it went (see Implemented so far). After that, each task has a difficulty staircase that moves once per finished run: two good runs in a row make it harder, one poor run makes it easier, and a run in between changes nothing (2-down/1-up, higher level = harder). What counts as good or poor: Corsi reaches start span + 2 or fails the first length; Go/No-Go accuracy 85% or above, or below 70%; DCCS mixed-block accuracy 90% or above, or below 70%; CPT d-prime 3.5 or above, or below 2.0.
- What the levels change: Corsi's starting length (2 to 5). Go/No-Go's stimulus time, ISI and go probability (level 1 is the spec). DCCS's cue time and response timeout. CPT's trial length and target probability (level 1 is the spec).
- Runs with more than 20% invalid trials, and dev runs, do not move the engine.
- The scheduler weights each mission by `(1 - skill) + 0.15`, adds 0.5 for a domain never played, and cuts a mission just played to a quarter. The first mission is always Corsi, because the story needs it. The pick is saved, so the hub does not re-roll it on every visit.
- The plot always advances: every mission story works in any order, and the ending plays once after all four missions have been played.
- Limits: the skill estimate does not account for the difficulty level a result came from, and the numbers are not comparable between children or with published tests. All values live in `scripts/adaptive/adaptive_constants.gd` and `difficulty_ladders.gd`.

### Approved Band A safeguards (not implemented)

- Ladders have 3 levels (see the table above), so the hardest Band A level is gentler than Band B's middle.
- Lower the level after one run under 65% accuracy; raise it only after two runs in a row at 85% or above.
- The first-run placement can move a Band A player up by at most 1 level, and never below level 1.
- Pacing rule (both bands): after a harder mission or a run under 65%, the next mission offered is a short, easy, rewarding one.
- End-of-run screens are always positive, whatever the result.

## Planned, not built yet

These come from the owner's decisions. Plan only: build them in the milestone shown.

- **Meta-loop (milestone 8):** missions earn things that grow a ranch and herd: rescued cows, decorations, a longhorn companion. An unlockable map with new areas.
- **Variety (milestone 8):** the same task in different story skins (a different herd, time of day, elder, or location), so it does not feel like repeating the same test. A skin changes art and story only, never timing or trial structure.
- **A real story with personality (milestone 8):** funny longhorn characters, a mystery (why was the kid brought here?), and a payoff arc.
- **Pacing rule:** after a harder mission, a short, easy, rewarding one.
- **Playtest mode (before milestone 5, see Milestones):** a "playtest" setting that records nothing about the child except anonymous trial data on the device, plus a visible observer-notes screen where the owner can write what they saw. The owner will watch real kids play early prototypes and use that to decide what to polish.
- **Developer dashboard (milestone 7b), open access:** the place for metrics, results and tuning values, so they stay off the child-facing screens.
- **Calibration runs:** optional, fixed-parameter, separate from story missions.
- **Voiceover (milestone 9):** so Band A never has to read.

## Engineering rules

- Godot 4.x, GDScript, static typing.
- Tasks extend `TaskModule`, with `start(params: Dictionary)` and a `finished(results: Dictionary)` signal.
- Trial logic lives in pure `RefCounted` classes with no node dependencies, tested with GUT. Presentation lives in separate scenes and scripts.
- Trial-critical timing uses `Time.get_ticks_usec()` and `_process` delta accumulation, not tweens or await timers.
- Responses under 100 ms are flagged as anticipatory, not deleted.
- If the window loses focus mid-trial, abort the trial and log it as invalid.
- No magic numbers. Placeholder art only.

## Design rules

- **Story stays outside the trials.** Story lives before and after each task: cutscenes, dialogue, rewards. During trials there is no dialogue, no popups, and no animated distractions. Themed art is allowed only as the stimuli.
- **Theming never touches the task.** Every task keeps the parameters in its own spec. Theming never changes timing or trial structure.
- **Feedback ("juice") only on the response and at the reward moment, never during the stimulus period.**
- **Positive feedback only.** No "wrong" or "failed" anywhere the player can see.
- **One tone for every Corsi stone.**
- **Adaptive mission choice, fixed plot.** The adaptive engine chooses missions from the player's weakest domains, but the plot always advances.
- **Art and audio:** most character and scene art is drawn in code, with generated sound effects. The project also includes the looping track `audio/lofi_positive.mp3`. Final art and voiceover are not implemented.

## Milestones

| # | Milestone | Status |
|---|---|---|
| 1 | Start screen | Done |
| 2 | Shared foundation (TaskModule, TrialLogger, SkillModel, hub) | Done. SkillModel is real, not a stub |
| 3 | Corsi (drum stones, single tone) | Done (first version, Band B values) |
| 4 | Go/No-Go (calves and snakes) | Done (first version, Band B values) |
| - | **Playtest with real kids** | **Not started.** Needs playtest mode (planned, not built). Milestones 5-7 were built before this step, so treat them as prototypes to playtest |
| 5 | DCCS | Built early (first version, Band B values). Band A version still to do |
| 6 | CPT | Built early (first version, Band B values). Band A version still to do |
| 7 | Adaptive engine with age bands | First version built, **without age bands**. Bands still to do |
| 7b | Developer dashboard and adult-question gate for Reset story and Delete profile | Partial: a clinician-report button exists; the full dashboard and gate are not implemented |
| 8 | Story layer and ranch/herd meta-loop | Story layer first version built (dialogue, scenes, choices, saved progress). Meta-loop, skins and the mystery arc are planned |
| 9 | Art, audio, voiceover, polish | Partial: code-drawn art, generated sound effects, and one music track are present; final art and voiceover remain |
| 10 | Privacy and legal review | Started: engineering checks and the checklist (`docs/PRIVACY_AND_ETHICS.md`). The legal review must happen before any child outside the owner's household plays |

## Implemented so far

This section describes current behavior. The approved design goals and remaining implementation gaps are listed separately below.

- **Flow:** Begin Quest opens "Who's playing?", then plays the arrival story the first time, then the Corsi mission, then its results screen, then the aftermath story, then the hub. After that, a returning player goes straight to the hub. A mission's intro story plays every time until that mission has been completed once. From the hub, the next mission (chosen by the adaptive engine) plays its intro story, the task, its results screen, then its aftermath story. After all four, the ending plays once.
- **Corsi in the story:** the ship's door panel mirrors the drum stones, so the Corsi screen is that panel. Every stone makes the same single drum tone, played when it lights and when it is tapped.
- **Plot always advances:** the elder's reaction line depends on how the run went (great, good, tried). The rest of the story is identical.
- **Hub:** lists all four missions with a quest progress bar, the level and best result for each, and "(up next)" on the engine's pick. Any mission can be replayed. It has "Reset story" and "Switch player" buttons.
- **Progress and profiles:** each profile has its own story progress, skill estimates, difficulty levels, trial logs, points and run history, in a folder named by a random code. A profile is currently a typed nickname plus a picked avatar (up to 8 players; 6 avatars: four kids in space suits and two young longhorns, drawn in code). The avatar index is stored in the field named `color`. The nickname is in `profiles.cfg` and is copied to a report when one is generated. Profiles can be deleted after a confirmation.
- **Go/No-Go:** cow = go, snake = no-go. There is an instructions screen before practice and a break screen between practice and real trials (both outside trials). Feedback cues also apply during practice. A response counts from stimulus onset to the end of the blank pause. Taps during the fixation cross are ignored for scoring but counted in the log.
- **Trial log columns:** `task, trial, params, stimulus, response, correct, rt_ms, valid, anticipatory, invalid_reason`. A response under 100 ms is flagged `anticipatory` and kept. A trial interrupted by window focus loss or by the skip warning is logged invalid with a reason and left out of the scores.
- **Skipping a game:** every game has a small, dim "Skip" button in the top-right corner, and Esc or the gamepad's back button do the same. It opens a warning with "Keep playing" focused first, and the game pauses while it is open. "Skip game" discards the partial run and trial log; story progress records a skip, but does not count it as a play. The hub marks the mission as skipped, and the quest cannot be finished without playing it.
- **Whole game required:** the ending only plays once all four games have actually been finished.
- **Levels from performance:** the first finished run of a game places the player (up two levels for a great run down to two levels down for a very poor one). After that the 2-down/1-up rule moves them one step at a time. The hub and results screens show the level.
- **Dialogue:** BBCode text effects, typing blips per speaker, talking mouths, blinking, entrances, screen shake and drum ripples, a short flavor choice in each mission intro and the ending, and funny elder voices (Grand Elder Bram booms and makes cow puns, Elder Tilda is dry and calls the kid "starling").
- **Progress bars:** the hub shows quest progress (missions finished out of four). Every task has a thin bar at the top that advances during active play and reaches full when the task finishes. Timed tasks interpolate through the active trial; Corsi reflects sequence playback and the player's taps. `SHOW_PROGRESS_BAR` in `scripts/tasks/task_constants.gd` turns the task bars off.
- **Feedback text:** a short line in a fixed spot at the top of the screen (under the progress bar, not a popup), shown for 0.7 s with the glow: "Right!" (green), "Not that one" (orange, after a mistake), and "Too slow!" (orange, when a cow gets away in Go/No-Go or no sort happens in time in DCCS). Words are in `task_constants.gd`. Shown after the stimulus is gone; the owner asked for text during trials, which relaxes the earlier "no text during trials" rule for this line only.
- **Mistake and correct cues:** after a correct response the screen edge glows soft green (silent); after a mistake it glows soft orange (`MistakeCue`, values in `task_constants.gd`), with no words. Go/No-Go and DCCS also play a low soft tone. Triggers: tapping a snake, a cow that got away, a wrong pen, no sort in time, and in Corsi a tap on the wrong stone (the stone turns orange, silent so every stone keeps the one tone). The glow only touches the edge, never the stimulus. CPT now has them too (green on a hit, orange on a harmless shape, "Too slow!" on a missed thief). Corsi has no time limit, so it has no "too slow". This feedback also applies to practice trials.
- **Corsi input modes:** the white ring on a drum follows the input type. With mouse, trackpad or touch there is no ring until the pointer hovers a drum, and the ring follows the pointer. With keyboard or gamepad the ring marks the focused drum. The game switches automatically on the first input of the other kind (`CorsiBlock.pointer_mode`).
- **Daily points:** each of the four tasks earns 100 points the first time it is finished on a calendar day, plus an extra for a good run (+25) or a great run (+50), using the same great/good/tried bands the story uses; finishing always earns at least the 100. Finishing all four that day adds a 500 point bonus (once a day, max 1100 a day). Points are never taken away; skipped and dev runs earn nothing; replaying a task the same day earns nothing more. A calf offers the points on the results screen ("Moo! 150 points! Great herding! +50") and, on the hub, shows "Today: 2 of 4 done, Points: N". Saved per profile in `points.cfg`. Values and wording in `scripts/points/points_constants.gd`.
- **Sample data:** the profile screen's "Add sample player" button creates (or refreshes) a player called Sample with 14 days of made-up runs and points, so the report and points can be tried right away. It never touches real players. Code in `scripts/sample/sample_data.gd`.
- **Music:** one looping lofi track (`audio/lofi_positive.mp3`, supplied by the owner) plays through the `Music` autoload on every screen. During the four tasks it drops a lot quieter (-34 dB instead of -12 dB, both in `ui_constants.gd`) so it never competes with the trials or Corsi's single drum tone. A "Music" switch in Settings turns it off (saved in settings.cfg). This is the one soundtrack that is not placeholder, so the track's licence must be checked before anyone outside the household plays.
- **Push buttons:** Sorting Day uses the two pens as buttons. Go/No-Go ("HERD!") and Night Watch ("THIEF!") have one big button at the bottom centre, away from the stimulus (`ResponsePad`). Each button sinks when pressed and registers on the way down. Clicking anywhere else does nothing; Space/Enter/gamepad A and (in Sorting Day) the arrow keys still work. The button's label never changes during a run.
- **Day-by-day data:** the locally generated report has a "Day by day" table and a per-task day-average table, and saves a CSV file (`daily_metrics_<time>.csv`: date, task, runs that day, metric, day average) next to the HTML report. Both come from the saved run history, so they cover every day played on that profile.
- **Title:** the start screen title is "PLANET LONGHORN" (was a working title). The hub and story still call the place "Longhorn Planet".
- **Night Watch story:** the thief is a cow in a ski mask who has been sneaking hay out of the barn; the elders are embarrassed and the story says so before the watch ("It is a cow. In a ski mask."), and after it (the ski mask is found by the stream, "the cow says it was cold"). The harmless shapes are the honest cows of the herd. Results say "Masked cows caught/missed".
- **Avatar = main character:** the avatar a player picks when they create their profile is the main character ("You") in every story scene. The four kid avatars change the hair style, skin, suit colour and goggles; the two calf avatars make the main character a young longhorn. Drawn in `story_stage.gd` from `ProfileConst.AVATARS`; the story text is unchanged (the elders still say "little traveler").
- **Characters:** the Go/No-Go calves are drawn with the same code as the elders (`scripts/longhorn_art.gd`): same face, ears, horns and hide shading, but smaller with a big head, short horns and a tuft. Calves are tan; elders are brown (Bram) and purple (Tilda). The kid has a redesigned space suit: goggles on the head, bangs, blush, gloves, belt, badge, boots and a backpack. All placeholder art.
- **Clinician report:** the hub's top-right "Clinician report" button builds a printable web page (HTML) for the active profile from its saved run history (`run_history.json` in the profile folder, one numbers-only line per finished run; runs from before this feature are not included). Layout imitates a short neuropsychological summary: identifying details, purpose and limits, tasks given, data quality, results per task (every run, then mean/SD/range/first/latest and earlier-vs-later trend), CPT hit rate by time block, domain overview, notes for the reviewing professional, glossary. Descriptive only: no diagnosis, no norm-based scores (we have no age norms), clear "not a clinical assessment" statement. Saved under the profile's `reports/` folder and never sent anywhere; the game shows the file location. Code in `scripts/reports/`; the fixed wording is in `report_text.gd`, the only file the ethics test lets contain the words "diagnosis" and "clinical" (the test checks it only denies them). Age band shows "Not recorded" until age bands exist.
- **Metrics (global script):** the `Metrics` autoload (`scripts/metrics.gd`) keeps, for every number shown on a results screen, a running total over all finished runs and the last run's value. Memory only (resets when the game closes). Skipped and dev runs are not counted. Read with `Metrics.total(mission, metric)` and `Metrics.last(mission, metric)`.
- **Window focus:** if the window loses focus, tasks log the trial in progress as invalid and wait for the window to return before starting the next trial.
- **Static background during tasks:** the starfield is frozen in every task so nothing animates during trials.
- **Where things live:** story text and missions in `scripts/story/story_data.gd`, scene order in `story_flow.gd`, placeholder art in `story_stage.gd`, profiles in `scripts/profiles/`.
- **Placeholder names:** Grand Elder Bram, Elder Tilda, and "You" for the kid are placeholders.

## Implementation gaps and remaining design questions

This list separates implementation gaps from design choices that still need an answer.

1. **Profiles:** the current build asks for a typed nickname and avatar. The approved design is a profile with an avatar and age band only, selected without typing.
2. **No age bands exist yet.** There is no first-launch band screen, no Band A values, and no per-band ladders.
3. **Players see raw metrics.** Results screens show counts, accuracy, d-prime and criterion; the hub shows best results and levels. The planned dashboard is open access, but the current implementation is a clinician-report feature rather than a complete dashboard.
4. **Levels shown to the player.** The hub and results currently show "Level N", "Level up!" and "Next time will be a little easier". The design decision about keeping levels visible or moving them to a dashboard remains open.
5. **Child-visible destructive controls.** "Reset story" on the hub and "Delete" on the profile screen are available without an adult-question gate. The approved design calls for a simple adult-level question.
6. **Reading required everywhere.** Instructions screens, the hub, the skip warning, profile screens and all story dialogue are text. Band A needs icons, pictures and short or pictorial story beats. Voiceover comes in milestone 9.
7. **Corsi's starting span is set by difficulty (2 to 5)** and the maximum span is fixed at 9. The approved Band A design starts at 2 to 4 and stops at 5.
8. **The difficulty rule does not match "accuracy about 75-85%".** Current task-specific thresholds leave a wide range where difficulty does not change. The approved target is to make difficulty easier below 75% and harder after two runs at or above 85%, with gentler safeguards for Band A.
9. **"Minimum share" is not guaranteed.** The scheduler gives weaker domains more weight, but does not guarantee the approved 15% share for each domain over any 12 missions.
10. **First-run placement can move a player two levels,** which can push a Band A child too high. The approved Band A safeguard limits first-run placement to at most +1 level.
11. **Session pacing is missing:** no natural stopping point, no "short easy mission after a hard one" rule. Today a mission with its story takes 4-9 minutes.
12. **Skip prompt wording and visuals:** the current warning and controls are text-based. The proposed child-friendly direction is an icon and gentle wording that explains the game can be played later.
13. **Playtest came before DCCS, CPT and the adaptive engine in your order,** but they are already built. Treat them as prototypes until real kids have played them.

## Decisions made

- **Band A defaults approved** as proposed in the table above (to be tuned after playtesting).
- **Minimum share:** every domain gets at least 15% of missions over any 12 missions.
- **Dashboard is open access: no gate.** A clinician-report button exists, but the complete dashboard is not implemented. The approved adult-question gate for "Reset story" and "Delete profile" is not implemented.
- **Avatars:** 6 (placeholder shapes until milestone 9).
- **Age band screen:** approved design is two big pictures (ages 6-8 and 9-12), one tap, changeable later from settings; not implemented.
- **Sessions:** a natural stopping point only. After each mission's story reward, "See you next time" is offered as an equal choice to "Next mission". No timer.
- **Playtest observer notes:** free text plus quick tick boxes (needed help reading, got frustrated, wanted to stop, smiled or laughed).
- **Design target age 6-12, two age bands** (A: 6-8, B: 9-12). Age-band selection and settings are not implemented.
- **Game first, measurement second.** The honest wording is "adjusts the challenge".
- **Corsi uses one tone for every stone.**
- **The design targets children under 13:** no accounts, network calls, analytics, ads or third-party SDKs; local data only. The current build stores a typed nickname and avatar, but no age, photos, voice or location.
- **Two-dial adaptive spec, with difficulty ranges looked up per band.** Difficulty never changes mid-run.
- **Corsi keeps its own step-up rule** (two trials per length, up after one correct, stop after two wrong). The engine sets the starting length.
- **The WATCH / REPEAT label stays in Corsi** for now. It is text, so Band A needs an icon instead.
- **Progress bars:** all four tasks show a thin bar that advances during active play and reaches full at completion. One constant turns the task bars off.
- **Staircase runs once per finished run, not per trial.**
- **Skip button during trials:** a small, dim, static button and a warning that only appears when the player asks. `SHOW_SKIP_BUTTON` turns the button off. A skipped run is not saved at all.
- **Placement uses only the first finished run.**
- **Mission order:** Corsi first, then the engine picks. Every mission's story stands alone.
- **Corsi invalid trials are retried;** Go/No-Go invalid trials are left out.

## Open questions

The player-facing level display and the proposed skip-prompt wording and visuals still need a decision.
