class_name DialogueBlips
extends RefCounted
## The little typing sounds, made in code. One pitch per speaker, cached.

static var _cache := {}


## A short blip at this pitch (null for a silent speaker, hz <= 0).
static func stream_for(hz: float) -> AudioStreamWAV:
	if hz <= 0.0:
		return null
	var key := int(hz)
	if not _cache.has(key):
		_cache[key] = _make(hz)
	return _cache[key]


static func _make(hz: float) -> AudioStreamWAV:
	var count := int(StoryConst.BLIP_SECONDS * StoryConst.BLIP_MIX_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / StoryConst.BLIP_MIX_RATE
		var progress := float(i) / count
		var envelope := minf(progress * 12.0, 1.0) * (1.0 - progress) # Quick attack, smooth fade.
		var tone := sin(TAU * hz * t) + 0.4 * sin(TAU * hz * 2.0 * t)
		data.encode_s16(i * 2, int(clampf(tone * envelope * StoryConst.BLIP_VOLUME, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = StoryConst.BLIP_MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
