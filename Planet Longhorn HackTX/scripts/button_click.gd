class_name ButtonClick
extends RefCounted
## The little click heard whenever a button is pressed. Built in code, like the other sounds.


static func make_stream() -> AudioStreamWAV:
	var count := int(UIConst.CLICK_SECONDS * UIConst.CLICK_MIX_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1 # Same sample every launch.
	for i in count:
		var t := float(i) / UIConst.CLICK_MIX_RATE
		var envelope := exp(-t * UIConst.CLICK_DECAY)
		var tone := sin(TAU * UIConst.CLICK_HZ * t)
		var noise := rng.randf_range(-1.0, 1.0) * UIConst.CLICK_NOISE_AMOUNT
		var sample := clampf((tone + noise) * envelope * UIConst.CLICK_VOLUME, -1.0, 1.0)
		data.encode_s16(i * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = UIConst.CLICK_MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
