class_name DrumSound
extends RefCounted
## Builds the drum-stone sound in code: a falling sine "thump" plus a short click.


static func make_stream() -> AudioStreamWAV:
	var count := int(CorsiConst.DRUM_SECONDS * CorsiConst.DRUM_MIX_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1 # Same sample every launch.
	var phase := 0.0
	for i in count:
		var t := float(i) / CorsiConst.DRUM_MIX_RATE
		var hz := CorsiConst.DRUM_END_HZ + (CorsiConst.DRUM_START_HZ - CorsiConst.DRUM_END_HZ) \
				* exp(-t * CorsiConst.DRUM_PITCH_DECAY)
		phase += TAU * hz / CorsiConst.DRUM_MIX_RATE
		var tone := sin(phase) * exp(-t * CorsiConst.DRUM_AMP_DECAY)
		var click := rng.randf_range(-1.0, 1.0) * CorsiConst.DRUM_NOISE_AMOUNT \
				* exp(-t * CorsiConst.DRUM_NOISE_DECAY)
		var sample := clampf((tone + click) * CorsiConst.DRUM_VOLUME, -1.0, 1.0)
		data.encode_s16(i * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = CorsiConst.DRUM_MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
