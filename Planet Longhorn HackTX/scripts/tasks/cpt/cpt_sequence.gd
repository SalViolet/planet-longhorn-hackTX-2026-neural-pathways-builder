class_name CptSequence
extends RefCounted
## Builds the CPT glyph order. Pure logic: pass in the RNG so tests can seed it.


## One glyph id per trial. Exactly round(count * target_probability) trials are the target
## (the thief), never two in a row. Harmless glyphs never repeat back to back.
static func generate(count: int, target_probability: float, rng: RandomNumberGenerator) -> Array[int]:
	@warning_ignore("integer_division")
	var target_count := clampi(roundi(count * target_probability), 0, (count + 1) / 2)
	var is_target: Array[bool] = []
	is_target.resize(count)
	is_target.fill(false)

	# Pick target_count slots out of (count - target_count + 1), then push each later slot
	# one step along. That guarantees at least one non-target between targets.
	var slots: Array[int] = []
	for i in count - target_count + 1:
		slots.append(i)
	for i in range(slots.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := slots[i]
		slots[i] = slots[j]
		slots[j] = tmp
	var chosen := slots.slice(0, target_count)
	chosen.sort()
	for i in chosen.size():
		is_target[chosen[i] + i] = true

	var out: Array[int] = []
	var previous := -1
	for trial in count:
		if is_target[trial]:
			out.append(CptConst.TARGET_GLYPH)
			previous = CptConst.TARGET_GLYPH
			continue
		var pick := rng.randi_range(0, CptConst.TARGET_GLYPH - 1)
		if pick == previous:
			pick = (pick + 1 + rng.randi_range(0, CptConst.TARGET_GLYPH - 2)) % CptConst.TARGET_GLYPH
		out.append(pick)
		previous = pick
	return out
