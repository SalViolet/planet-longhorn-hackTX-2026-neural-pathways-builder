class_name DccsSequence
extends RefCounted
## Builds the DCCS rule and stimulus lists. Pure logic: pass in the RNG so tests can seed it.

const _CONFLICT_ITEMS := [
	{"hue": DccsStimulus.Hue.BLUE, "shape": DccsStimulus.Shape.ROUND},
	{"hue": DccsStimulus.Hue.ORANGE, "shape": DccsStimulus.Shape.STAR},
]
const _CONGRUENT_ITEMS := [
	{"hue": DccsStimulus.Hue.BLUE, "shape": DccsStimulus.Shape.STAR},
	{"hue": DccsStimulus.Hue.ORANGE, "shape": DccsStimulus.Shape.ROUND},
]


## Rules for a mixed block. Exactly round(count * switch_probability) trials switch rule
## compared with the trial before (the first one is compared with `previous_rule`).
static func rules(count: int, switch_probability: float, previous_rule: int,
		rng: RandomNumberGenerator) -> Array[int]:
	var switch_at: Array[int] = []
	for i in count:
		switch_at.append(i)
	_shuffle(switch_at, rng)
	var switches := {}
	for i in clampi(roundi(count * switch_probability), 0, count):
		switches[switch_at[i]] = true
	var out: Array[int] = []
	var rule := previous_rule
	for i in count:
		if switches.has(i):
			rule = DccsStimulus.other_rule(rule as DccsStimulus.Rule)
		out.append(rule)
	return out


## Stimuli for a block: exactly round(count * conflict_probability) conflict items, and the two
## conflict items (and the two congruent items) used equally often. The whole list is shuffled
## together, so the order has no pattern, but it is reshuffled if one gift would repeat more than
## DccsConst.MAX_SAME_STIMULUS_IN_ROW times in a row.
static func stimuli(count: int, conflict_probability: float, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var conflict_count := clampi(roundi(count * conflict_probability), 0, count)
	var pool: Array[Dictionary] = []
	_add_balanced(pool, _CONFLICT_ITEMS, conflict_count, rng)
	_add_balanced(pool, _CONGRUENT_ITEMS, count - conflict_count, rng)
	for attempt in DccsConst.SHUFFLE_ATTEMPTS:
		_shuffle(pool, rng)
		if longest_run(pool) <= DccsConst.MAX_SAME_STIMULUS_IN_ROW:
			break
	return pool


## The most identical gifts (same color and shape) found one after another.
static func longest_run(items: Array[Dictionary]) -> int:
	var longest := 0
	var run := 0
	for i in items.size():
		var same: bool = i > 0 and items[i]["hue"] == items[i - 1]["hue"] and items[i]["shape"] == items[i - 1]["shape"]
		run = run + 1 if same else 1
		longest = maxi(longest, run)
	return longest


# Adds `count` items from a pair, split evenly (when odd, a random one of the pair gets the extra).
static func _add_balanced(pool: Array[Dictionary], pair: Array, count: int, rng: RandomNumberGenerator) -> void:
	var first := rng.randi_range(0, 1)
	for i in count:
		var item: Dictionary = pair[(i + first) % 2]
		pool.append(item.duplicate())


static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = values[i]
		values[i] = values[j]
		values[j] = tmp
