class_name GoNoGoSequence
extends RefCounted
## Builds the go / no-go order. Pure logic: pass in the RNG so tests can seed it.


## true = go trial, false = no-go. Exactly round(count * go_probability) go trials,
## and never more than max_consecutive_nogo no-go trials in a row.
static func generate(count: int, go_probability: float, max_consecutive_nogo: int,
		rng: RandomNumberGenerator) -> Array[bool]:
	var go_count := clampi(roundi(count * go_probability), 0, count)
	# If the limit makes the requested mix impossible, add go trials until it fits.
	while count - go_count > (go_count + 1) * max_consecutive_nogo:
		go_count += 1
	var nogo_count := count - go_count

	# The go trials split the sequence into go_count + 1 gaps. Hand out the no-go
	# trials one at a time to a random gap that still has room.
	var gaps: Array[int] = []
	gaps.resize(go_count + 1)
	gaps.fill(0)
	for i in nogo_count:
		var open: Array[int] = []
		for gap in gaps.size():
			if gaps[gap] < max_consecutive_nogo:
				open.append(gap)
		gaps[open[rng.randi_range(0, open.size() - 1)]] += 1

	var order: Array[bool] = []
	for gap in gaps.size():
		for k in gaps[gap]:
			order.append(false)
		if gap < go_count:
			order.append(true)
	return order


## Random blank time after the stimulus, in whole milliseconds.
static func isi_ms(min_ms: int, max_ms: int, rng: RandomNumberGenerator) -> int:
	return rng.randi_range(min_ms, max_ms)
