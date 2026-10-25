class_name CorsiSequence
extends RefCounted
## Sequence generation. Pure logic: pass in the RNG so tests can seed it.

const MAX_ATTEMPTS := 100


## No block twice in a row, and never identical to `previous`.
static func generate(length: int, block_count: int, previous: Array[int],
		rng: RandomNumberGenerator) -> Array[int]:
	var seq: Array[int] = []
	for attempt in MAX_ATTEMPTS:
		seq = _draw(length, block_count, rng)
		if seq != previous:
			break
	return seq


static func _draw(length: int, block_count: int, rng: RandomNumberGenerator) -> Array[int]:
	var seq: Array[int] = []
	for i in length:
		var pick := rng.randi_range(0, block_count - 1)
		if i > 0:
			# Draw from the other (block_count - 1) blocks, then skip over the last one.
			pick = rng.randi_range(0, block_count - 2)
			if pick >= seq[i - 1]:
				pick += 1
		seq.append(pick)
	return seq
