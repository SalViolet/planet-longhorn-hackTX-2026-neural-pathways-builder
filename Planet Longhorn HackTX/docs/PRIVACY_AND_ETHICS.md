# Privacy and Ethics

Milestone 10. Read this before any child plays the game, and before any data leaves the device.

**This is an engineering checklist, not legal advice.** The decisions marked OPEN need the owner, and the legal ones need a qualified person (a lawyer, a data protection officer, or an ethics board).

## What the game stores today

Everything is stored on the device the game runs on. The game makes no network calls and has no online accounts or analytics. Players pick a profile on the device. (Planned change, not built yet: a profile becomes a chosen avatar plus an age band, with no typed name. The dashboard is open access (owner decision); an adult-question gate protects Delete and Reset story. A playtest mode that records only anonymous trial data. See the "Pending decisions" list in `docs/GAME_DESIGN.md`.) (`tests/unit/test_ethics.gd` fails if network code is added.)

| File (in the game's user data folder) | What is in it |
|---|---|
| `settings.cfg` | Master volume and the fullscreen choice (shared by everyone on the device) |
| `profiles.cfg` | The list of profiles: for each, a nickname, an avatar color, and a random 8-character code. It also remembers which profile played last. **This is the only file that contains a nickname** |
| `profiles/<code>/progress.cfg` | Which story scenes were seen, how often each mission was played, best results, and which mission is next |
| `profiles/<code>/adaptive.cfg` | One 0-1 skill estimate per domain (memory, inhibition, flexibility, attention), the difficulty level for each task, and the staircase counters |
| `profiles/<code>/trial_logs/<task>_<time>.csv` | One row per trial: task, trial number, the trial settings, what was shown, what the player did, correct or not, reaction time in ms, whether the trial was valid, whether it was flagged anticipatory, and why it was invalid |
| `profiles/<code>/points.cfg` | The points total, and which tasks were finished today (no names, no per-trial data) |
| `profiles/<code>/run_history.json`, `profiles/<code>/reports/`  | The numbers of every finished run, and any progress reports the player asked for. A report contains the nickname and performance data, so treat it as sensitive: it is created only when the "Clinician report" button is pressed, saved on the device, and never sent anywhere. Deleting the profile deletes both |

Each profile's folder is named by its random code, and nothing inside a profile's folder contains the nickname (checked by a test), except a progress report the owner asks for, which prints the nickname in its header. Only `profiles.cfg` links a code to a nickname. The game asks for a nickname, not a full name, but it cannot stop a parent typing one. These files are performance data about a child, and they can be copied by anyone with access to the device.

Saves from before profiles existed (`progress.cfg`, `adaptive.cfg` and `trial_logs/` directly in the user data folder) are not used by profiles and are not moved. They are only used when a scene is run on its own from the editor.

A game the player skips (after the warning) saves nothing at all: its partial trial log is discarded.

Deleting a profile on the "Who's playing?" screen (after a confirmation) removes its nickname and its whole folder.

Where to find them: in Godot, **Project > Open User Data Folder**. On a Mac that is `~/Library/Application Support/Godot/app_userdata/Alien Quest`. In an exported game it is the game's own folder under `~/Library/Application Support/`.

## What the game must never say

- That it diagnoses, screens for, or detects any condition (ADHD, autism, dyslexia, and so on).
- That it trains the brain, improves memory, raises IQ, or treats anything.
- That a score means something about the child's ability or future.

`tests/unit/test_ethics.gd` scans the game's scripts and scenes for these phrases. It cannot check images, store pages, or anything written outside the code, so check those by hand.

Results screens currently show numbers (span, accuracy, d-prime, costs). They are for the developer. Before children play, decide what the child sees (the story reaction only is the safest) and where the numbers go.

## Checklist before any child plays

| # | Item | Status | Who |
|---|---|---|---|
| 1 | Target age range | DECIDED: 6-12, two age bands (A 6-8, B 9-12). All players are under 13, so COPPA-level care applies | Owner |
| 2 | Entertainment or assessment | DECIDED: game first, measurement second. Metrics are for tuning only and are never presented as an assessment. Wording: "adjusts the challenge" | Owner |
| 3 | Consent: who consents (parent, school, the child), how it is asked, and how it is recorded. COPPA (US, under 13) and GDPR (EU and UK, age of digital consent is 13-16 depending on country) both apply to data about children | OPEN | Owner and legal |
| 4 | Data minimisation: confirm the trial log needs every column, and that nothing identifying is added later | Done for now (checked by test) | Developer |
| 5 | Retention and deletion: how long files are kept, and who may delete. A profile can now be deleted in the game with a confirmation, and that removes everything saved for it. Open: any adult-only protection on Delete, and a retention period. The hub's "Reset story" button resets that profile's story progress and difficulty, not its trial logs | Partly done | Owner |
| 6 | If data ever leaves the device (research upload, cloud sync, crash reports): written purpose, encryption, a data processing agreement, and a new review of this whole document | OPEN, not built | Owner and legal |
| 7 | Shared devices: each child can have their own profile with separate progress, difficulty and logs. Open: profiles are not protected, so any child can open or delete another's profile. Decide whether that needs a parent PIN | Partly done | Owner |
| 8 | Research use: if the game is used in a study, an ethics board (IRB) must approve the protocol before any data is collected | OPEN | Owner |
| 9 | Safety content: no violence beyond the cartoon snakes, no timers or scores that shame a child, no ads, no purchases, no links out. (Checked by test for network code and links.) | Done for now | Developer |
| 10 | Accessibility: blue and orange were chosen to stay distinct for colour-blind players. Check text size, contrast, sound-off play, and one-switch or touch-only play | Partly done | Developer |
| 11 | Photosensitivity: nothing flashes faster than about 4 times a second (Corsi lights are 1 s on, CPT glyphs are 0.25 s, one per 2 s). Re-check if timings are made faster | Done for now | Developer |
| 12 | Honest wording: re-read every piece of text a parent or child sees (game text, store page, website) against "What the game must never say" | OPEN | Owner |
| 13 | Review the adaptive engine's effects: it chooses missions by weakest domain, so a child who struggles with one task will see it more often. Decide whether that is acceptable for the age group | OPEN | Owner |

## Things to know about the results

- Reaction times are measured once per screen frame, so they are accurate to about one frame (16 ms at 60 Hz) and depend on the device and its display.
- Responses under 100 ms are flagged as anticipatory and kept in the log. They are left out of reaction-time averages.
- A trial interrupted by the window losing focus, or by the player leaving, is logged as invalid with a reason and left out of the scores.
- Skill estimates and difficulty levels are for adapting the game. They are not norm-referenced, and are not comparable between children or with published tests.
