class_name ProfileBadge
extends Control
## A round avatar portrait. Used on the profile list and in the avatar picker.

var _avatar := 0


func setup(avatar_index: int) -> void:
	_avatar = avatar_index
	queue_redraw()


func _draw() -> void:
	AvatarArt.draw(self, size / 2.0, minf(size.x, size.y) / 2.0, _avatar)
