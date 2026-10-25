class_name PointsOffer
extends VBoxContainer
## A calf with a speech bubble underneath. On a results screen the calf offers the points just earned;
## on the hub it sums up today. Shown only outside trials.

var _calf: Control
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", PointsConst.OFFER_SEPARATION)
	alignment = BoxContainer.ALIGNMENT_CENTER
	_calf = _CalfIcon.new()
	_calf.custom_minimum_size = PointsConst.OFFER_CALF_SIZE
	_calf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_calf)
	var bubble := PanelContainer.new()
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bubble)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", PointsConst.OFFER_FONT_SIZE)
	_label.add_theme_color_override("font_color", PointsConst.OFFER_COLOR)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size.x = PointsConst.OFFER_TEXT_WIDTH
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_child(_label)
	hide()


## The calf offers the points a just-finished run earned. `award` comes from PointsStore.
func show_award(award: Dictionary) -> void:
	if award.is_empty():
		hide()
		return
	var lines: Array[String] = []
	if int(award["task_points"]) > 0:
		lines.append(PointsConst.OFFER_TASK_FORMAT % int(award["task_points"]))
	elif bool(award["repeat"]):
		lines.append(PointsConst.OFFER_REPEAT_TEXT)
	if int(award.get("extra", 0)) > 0:
		var great := int(award["extra"]) >= PointsConst.EXTRA_GREAT
		lines.append((PointsConst.OFFER_EXTRA_GREAT_FORMAT if great else PointsConst.OFFER_EXTRA_GOOD_FORMAT) % int(award["extra"]))
	if int(award["bonus"]) > 0:
		lines.append(PointsConst.OFFER_BONUS_FORMAT % int(award["bonus"]))
	if lines.is_empty():
		hide()
		return
	_label.text = "\n".join(lines)
	show()


## The hub version: today's progress and the running total.
func show_summary() -> void:
	var done := PointsStore.done_on().size()
	var needed := PointsConst.REQUIRED_TASKS.size()
	if done >= needed:
		_label.text = PointsConst.SUMMARY_DONE_FORMAT % PointsStore.total()
	else:
		_label.text = PointsConst.SUMMARY_FORMAT % [done, needed, PointsStore.total()] \
				+ PointsConst.SUMMARY_HINT_FORMAT % [needed, PointsConst.DAILY_BONUS]
	show()


## Put the offer in the empty space at the left of the screen, away from the middle column.
func place_left(parent: Control) -> void:
	parent.add_child(self)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_MINSIZE, UIConst.SCREEN_MARGIN)


class _CalfIcon extends Control:
	func _draw() -> void:
		var k := PointsConst.OFFER_CALF_SCALE * size.y / PointsConst.OFFER_CALF_SIZE.y
		var feet := Vector2(size.x / 2.0, size.y - 8.0)
		LonghornArt.draw(self, feet, k, LonghornArt.look(StoryConst.COLOR_CALF_HIDE), true, false)
