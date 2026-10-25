class_name DccsStimulus
extends RefCounted
## The DCCS stimulus set and the sorting rules. Pure logic.
## Pens: the left pen's target card is a BLUE STAR, the right pen's is an ORANGE ROUND gift.
## So a blue round gift is a "conflict" item: colour says left, shape says right.

enum Hue { BLUE, ORANGE }
enum Shape { STAR, ROUND }
enum Rule { COLOR, SHAPE }
enum Pen { LEFT, RIGHT }


static func correct_side(hue: Hue, shape: Shape, rule: Rule) -> Pen:
	if rule == Rule.COLOR:
		return Pen.LEFT if hue == Hue.BLUE else Pen.RIGHT
	return Pen.LEFT if shape == Shape.STAR else Pen.RIGHT


static func is_conflict(hue: Hue, shape: Shape) -> bool:
	return correct_side(hue, shape, Rule.COLOR) != correct_side(hue, shape, Rule.SHAPE)


static func other_rule(rule: Rule) -> Rule:
	return Rule.SHAPE if rule == Rule.COLOR else Rule.COLOR


static func side_name(side: int) -> String:
	if side == Pen.LEFT:
		return "left"
	return "right" if side == Pen.RIGHT else "none"
