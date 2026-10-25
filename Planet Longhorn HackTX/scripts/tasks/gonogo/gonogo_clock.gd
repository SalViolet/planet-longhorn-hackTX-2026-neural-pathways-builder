class_name GoNoGoClock
extends RefCounted
## Which part of a trial we are in, given the time since the trial began.
## A trial is: fixation, then stimulus, then a blank ISI. Pure logic.

enum Phase { FIXATION, STIMULUS, ISI, DONE }


static func phase_at(elapsed_ms: float, fixation_ms: int, stimulus_ms: int, isi_ms: int) -> Phase:
	if elapsed_ms < fixation_ms:
		return Phase.FIXATION
	if elapsed_ms < fixation_ms + stimulus_ms:
		return Phase.STIMULUS
	if elapsed_ms < fixation_ms + stimulus_ms + isi_ms:
		return Phase.ISI
	return Phase.DONE
