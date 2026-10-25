class_name DccsClock
extends RefCounted
## Which part of a DCCS trial we are in. A trial is: cue, then the stimulus until the
## player responds or the timeout runs out, then a blank ITI. Pure logic.

enum Phase { CUE, STIMULUS, ITI, DONE }


## response_elapsed_ms is when the player responded, measured from the trial start (-1 = no response yet).
static func phase_at(elapsed_ms: float, cue_ms: int, timeout_ms: int, iti_ms: int,
		response_elapsed_ms: float = -1.0) -> Phase:
	if response_elapsed_ms >= 0.0:
		return Phase.ITI if elapsed_ms < response_elapsed_ms + iti_ms else Phase.DONE
	if elapsed_ms < cue_ms:
		return Phase.CUE
	if elapsed_ms < cue_ms + timeout_ms:
		return Phase.STIMULUS
	if elapsed_ms < cue_ms + timeout_ms + iti_ms:
		return Phase.ITI
	return Phase.DONE
