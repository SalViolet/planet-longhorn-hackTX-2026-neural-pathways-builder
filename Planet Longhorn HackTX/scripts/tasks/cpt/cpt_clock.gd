class_name CptClock
extends RefCounted
## Trial timing for the CPT. Trials start on a fixed grid (trial 0 at 0 ms, trial 1 at
## trial_ms, ...) so frame timing never makes the run drift. Pure logic.


## Which trial the run is in at this time (equals the trial count once the run is over).
static func trial_index(elapsed_ms: float, trial_ms: int) -> int:
	return maxi(floori(elapsed_ms / trial_ms), 0)


## Milliseconds since the current trial began.
static func within_ms(elapsed_ms: float, trial_ms: int) -> float:
	return fposmod(elapsed_ms, float(trial_ms))


static func stimulus_visible(elapsed_ms: float, trial_ms: int, stimulus_ms: int) -> bool:
	return within_ms(elapsed_ms, trial_ms) < stimulus_ms
