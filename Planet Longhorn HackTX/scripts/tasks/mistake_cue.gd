class_name MistakeCue
extends Control
## A soft orange glow around the screen edge (and, if wanted, a low gentle tone) shown right
## after a mistake. No words. It never covers the middle of the screen, never changes the
## stimulus, and fades by clock time, so it cannot affect trial timing.

var _until_us := 0
var _color := TaskConst.COLOR_MISTAKE
var _drawn_alpha := 0.0
var _player: AudioStreamPlayer
var _bing_player: AudioStreamPlayer
var _label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player = AudioStreamPlayer.new()
	_player.stream = _make_tone()
	add_child(_player)
	_bing_player = AudioStreamPlayer.new()
	_bing_player.stream = make_bing()
	add_child(_bing_player)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", TaskConst.FEEDBACK_FONT_SIZE)
	_label.add_theme_color_override("font_color", TaskConst.COLOR_MISTAKE)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.visible = false
	add_child(_label)
	_label.anchor_left = 0.0
	_label.anchor_right = 1.0
	_label.anchor_top = 0.0
	_label.anchor_bottom = 0.0
	_label.offset_top = TaskConst.FEEDBACK_TEXT_TOP
	_label.offset_bottom = TaskConst.FEEDBACK_TEXT_TOP + TaskConst.FEEDBACK_FONT_SIZE * 1.5


## Shows the glow. `with_tone` also plays the soft tone (Corsi stays silent: one tone only).
func play(with_tone: bool = true, text: String = "") -> void:
	_color = TaskConst.COLOR_MISTAKE
	_start_glow(text)
	if with_tone and not DisplayServer.get_name() == "headless":
		_player.play()


## The orange glow and tone, plus a short "Too slow!" at the bottom of the screen.
func play_too_slow() -> void:
	play(true, TaskConst.TOO_SLOW_TEXT)


## Soft green glow after a correct response, with the "bing" (Corsi passes false: it dings once per set).
func play_correct(text: String = "", with_sound: bool = true) -> void:
	_color = TaskConst.COLOR_CORRECT
	_start_glow(text)
	if with_sound:
		play_bing()


## The happy "bing" on its own.
func play_bing() -> void:
	if DisplayServer.get_name() != "headless":
		_bing_player.play()


## The low "bom" on its own (the same tone as a mistake, with no glow).
func play_bom() -> void:
	if DisplayServer.get_name() != "headless":
		_player.play()


func _start_glow(text: String = "") -> void:
	_label.text = text
	_label.add_theme_color_override("font_color", _color)
	_label.visible = text != ""
	_until_us = Time.get_ticks_usec() + TaskConst.MISTAKE_CUE_MS * TaskConst.USEC_PER_MS
	queue_redraw()


func _process(_delta: float) -> void:
	if _label.visible and Time.get_ticks_usec() >= _until_us:
		_label.visible = false # Hidden by clock time, like the glow.
	if _alpha() != _drawn_alpha:
		queue_redraw()


func _alpha() -> float:
	var left_us := _until_us - Time.get_ticks_usec()
	if left_us <= 0:
		return 0.0
	return clampf(float(left_us) / float(TaskConst.MISTAKE_CUE_MS * TaskConst.USEC_PER_MS), 0.0, 1.0)


func _draw() -> void:
	_drawn_alpha = _alpha()
	if _drawn_alpha <= 0.0:
		return
	var color := _color
	for band in TaskConst.MISTAKE_CUE_BANDS:
		var inset := band * TaskConst.MISTAKE_CUE_BAND_WIDTH
		var fade := 1.0 - float(band) / TaskConst.MISTAKE_CUE_BANDS
		color.a = _color.a * _drawn_alpha * fade
		draw_rect(Rect2(Vector2.ONE * inset, size - Vector2.ONE * inset * 2.0),
				color, false, TaskConst.MISTAKE_CUE_BAND_WIDTH)


## Two quick rising notes, built in code.
static func make_bing() -> AudioStreamWAV:
	var count := int(TaskConst.BING_SECONDS * TaskConst.BING_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / TaskConst.BING_RATE
		var sample := _bing_note(t, TaskConst.BING_HZ_LOW) \
				+ _bing_note(t - TaskConst.BING_NOTE_GAP, TaskConst.BING_HZ_HIGH)
		data.encode_s16(i * 2, int(clampf(sample * TaskConst.BING_VOLUME, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = TaskConst.BING_RATE
	stream.stereo = false
	stream.data = data
	return stream


static func _bing_note(t: float, hz: float) -> float:
	if t < 0.0:
		return 0.0
	return sin(TAU * hz * t) * minf(t / TaskConst.BING_ATTACK, 1.0) * exp(-t * TaskConst.BING_DECAY)


static func _make_tone() -> AudioStreamWAV:
	var count := int(TaskConst.MISTAKE_TONE_SECONDS * TaskConst.MISTAKE_TONE_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / TaskConst.MISTAKE_TONE_RATE
		var envelope := minf(t / 0.01, 1.0) * exp(-t * TaskConst.MISTAKE_TONE_DECAY)
		var sample := sin(TAU * TaskConst.MISTAKE_TONE_HZ * t) * envelope * TaskConst.MISTAKE_TONE_VOLUME
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = TaskConst.MISTAKE_TONE_RATE
	stream.stereo = false
	stream.data = data
	return stream
