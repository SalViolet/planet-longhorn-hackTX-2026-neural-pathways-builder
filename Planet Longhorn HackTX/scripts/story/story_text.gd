class_name StoryText
extends RefCounted
## Helpers for story text that uses BBCode (colors, [wave], [shake]). Pure functions.

const _TAG := "\\[(/?)([a-z]+)(?:[= ][^\\]]*)?\\]"


## The text as the player reads it, with the tags removed.
static func plain(text: String) -> String:
	var regex := RegEx.create_from_string(_TAG)
	return regex.sub(text, "", true)


## True if every opening tag has its closing tag, in the right order.
static func is_balanced(text: String) -> bool:
	var regex := RegEx.create_from_string(_TAG)
	var open_tags: Array[String] = []
	for m in regex.search_all(text):
		var closing := m.get_string(1) == "/"
		var tag_name := m.get_string(2)
		if closing:
			if open_tags.is_empty() or open_tags.pop_back() != tag_name:
				return false
		else:
			open_tags.append(tag_name)
	return open_tags.is_empty()
