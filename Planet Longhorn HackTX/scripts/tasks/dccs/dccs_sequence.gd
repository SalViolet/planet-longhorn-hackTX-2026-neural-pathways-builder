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


## Stimuli for a block: exactly round(count * conflict_probability) conflict items, shuffled,
## with the two conflict items (and the two congruent items) used equally often.
static func stimuli(count: int, conflict_probability: float, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var conflict_count := clampi(roundi(count * conflict_probability), 0, count)
	var flags: Array[bool] = []
	for i in count:
		flags.append(i < conflict_count)
	_shuffle(flags, rng)
	var conflict_turn := rng.randi_range(0, 1)
	var congruent_turn := rng.randi_range(0, 1)
	var out: Array[Dictionary] = []
	for is_conflict in flags:
		var item: Dictionary
		if is_conflict:
			item = _CONFLICT_ITEMS[conflict_turn % 2]
			conflict_turn += 1
		else:
			item = _CONGRUENT_ITEMS[congruent_turn % 2]
			congruent_turn += 1
		out.append(item.duplicate())
	return out


static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = values[i]
		values[i] = values[j]
		values[j] = tmp
