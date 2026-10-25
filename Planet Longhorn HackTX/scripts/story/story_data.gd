class_name StoryData
extends RefCounted
## All story content and the mission list. Pure data plus small lookups.
## Names are placeholders. Keep dialogue short and simple (age range is still open).
##
## A beat is a list of lines. A line has "speaker" and "text", plus optional
## "stage" ("ship" or "outside") and "actors" (speaker ids, drawn left to right).
## A line with "by_band" instead of "text" picks its text from how the run went.
## Text can use BBCode: [color=#hex]..[/color], [wave]..[/wave], [shake]..[/shake].
## A line may name an "effect": "shake" rattles the scene, "drums" sends a ripple out from the stones.
## A "choice" line shows a prompt and options; each option has a "label" and "reply" lines that play
## next. Choices change flavor only: every option leads back to the same story.

const BANDS: PackedStringArray = ["great", "good", "tried"]

const SPEAKERS := {
	"narrator": {"name": "", "color": Color("d8fff4"), "kind": "narrator", "voice_hz": 0.0},
	"kid": {
		"name": "You", "color": Color("7dffe6"), "kind": "kid", "voice_hz": 520.0,
		"body": Color("2cb5c8"), "head": Color("f2c8a0"), "accent": Color("3b2a22"), "style": "",
	},
	"elder_a": {
		"name": "Grand Elder Bram", "color": Color("ffd27d"), "kind": "longhorn", "voice_hz": 150.0,
		"body": Color("b57a4a"), "head": Color("b57a4a"), "accent": Color("e8e4f0"), "style": "beard",
	},
	"elder_b": {
		"name": "Elder Tilda", "color": Color("ff9ecb"), "kind": "longhorn", "voice_hz": 300.0,
		"body": Color("8c6aa8"), "head": Color("8c6aa8"), "accent": Color("ff5fa8"), "style": "band",
	},
}

const MISSIONS := [
	{
		"id": "corsi", "title": "Drum Stones",
		"blurb": "Appease the longhorns with their music",
		"scene": UIConst.SCENE_CORSI, "intro_beat": "arrival", "outro_beat": "corsi_after",
		"summary": "span",
	},
	{
		"id": "go_nogo", "title": "Herd the Calves",
		"blurb": "Herd the young longhorns. Snakes are not friends.",
		"scene": UIConst.SCENE_GONOGO, "intro_beat": "herd_intro", "outro_beat": "herd_after",
		"summary": "accuracy",
	},
	{
		"id": "dccs", "title": "Sorting Day",
		"blurb": "Sort by the elder's rule, even when it changes",
		"scene": UIConst.SCENE_DCCS, "intro_beat": "dccs_intro", "outro_beat": "dccs_after",
		"summary": "accuracy",
	},
	{
		"id": "cpt", "title": "Night Watch",
		"blurb": "Spot the cow in the ski mask",
		"scene": UIConst.SCENE_CPT, "intro_beat": "cpt_intro", "outro_beat": "cpt_after",
		"summary": "dprime",
	},
]

const BEATS := {
	# Before the Corsi mission. The ship's door panel mirrors the drum stones, which is why the
	# Corsi screen is the panel. The choice changes only who answers and how, never the plot.
	"arrival": {
		"next": UIConst.SCENE_CORSI,
		"lines": [
			{"speaker": "narrator", "stage": "ship", "actors": ["kid"], "effect": "shake",
			"text": "One second you were at home. Then... [shake]FLASH![/shake] A tumble through the stars, a big [shake]BONK[/shake], and now you are lying on the floor of a very small, very strange spaceship."},
			{"speaker": "kid", "text": "Ow... Hello? Is anybody there? Why is this ship so [wave]tiny[/wave]?"},
			{"speaker": "narrator", "effect": "drums",
			"text": "Outside, something is thumping. [wave]Boom... boom-boom... BOOM![/wave] It sounds like [color=#ffd27d]drums[/color]."},
			{"speaker": "kid", "text": "Drums?! Somebody out there is playing music!"},
			{"speaker": "narrator", "choice": {
				"prompt": "The round hatch will not budge. A deep voice rumbles through the wall: \"Who goes there?\" What do you shout back?",
				"options": [
					{"label": "Hello! I come in peace!", "reply": [
						{"speaker": "kid", "text": "Hello! I come in [color=#7dffe6]peace[/color]!"},
						{"speaker": "elder_a", "text": "[wave]Peace![/wave] Wonderful! Nobody has come in peace since Tuesday."},
					]},
					{"label": "Whoa, are those drums? Can I play?", "reply": [
						{"speaker": "kid", "text": "Whoa, are those [wave]drums[/wave]?! Can I play?!"},
						{"speaker": "elder_b", "text": "Straight to the point. I like you already, starling."},
					]},
				]}},
			{"speaker": "elder_a", "stage": "outside", "actors": ["elder_a", "elder_b"],
			"text": "[wave]Welcome[/wave], little traveler! You have landed on the [color=#ffd27d]Longhorn Planet[/color]. I am Grand Elder Bram!"},
			{"speaker": "elder_b",
			"text": "And I am Elder Tilda. Your ship's door only opens to [color=#ff9ecb]music[/color], starling. Our herd-song lives in these drum stones."},
			{"speaker": "elder_a", "effect": "drums",
			"text": "Watch closely! We will play a pattern on the stones. Then you play it back, [shake]just the same[/shake]!"},
			{"speaker": "elder_b",
			"text": "A panel by your door shows our stones. Tap them in the same order."},
			{"speaker": "elder_a",
			"text": "Show us you can really [color=#7dffe6]listen[/color], and the elders will trust you."},
			{"speaker": "kid", "stage": "ship", "actors": ["kid"],
			"text": "Watch the stones, then play the same pattern. [wave]I can do that![/wave]"},
			{"speaker": "narrator", "effect": "drums",
			"text": "The panel glows. Outside, the elders begin to play..."},
		],
	},
	# After the Corsi mission. The plot moves on whatever the score was.
	"corsi_after": {
		"next": UIConst.SCENE_HUB,
		"lines": [
			{"speaker": "narrator", "stage": "ship", "actors": ["kid"],
			"text": "The hatch hisses... then slides open. Warm purple light spills in, and with it a smell like [wave]cinnamon and hay[/wave]."},
			{"speaker": "elder_a", "stage": "outside", "actors": ["elder_a", "elder_b"], "effect": "drums",
			"by_band": {
				"great": "Not one beat out of place! You have the ears of a true [wave]herd-singer[/wave]!",
				"good": "Well played! Steady drumming and sharp ears. [wave]Moo-velous![/wave]",
				"tried": "A few beats wandered off, but you listened with your whole heart. That is what counts!",
			}},
			{"speaker": "elder_b", "text": "The elders trust you now. Welcome to our planet, starling."},
			{"speaker": "kid", "actors": ["kid", "elder_a", "elder_b"],
			"text": "Wow... everything is [color=#b44cff]purple[/color] and [wave]sparkly[/wave]!"},
			{"speaker": "elder_a",
			"text": "Ha! Wait until you see the herd. The herd, the market, the night watch... there is much to do. Will you help us?"},
			{"speaker": "elder_b", "text": "The elders will tell you what we need most."},
			{"speaker": "kid", "text": "I'll help. Where do we start?"},
			{"speaker": "narrator", "text": "Your quest on the [color=#ffd27d]Longhorn Planet[/color] has begun."},
		],
	},
	# Before the Go/No-Go mission. Explains the rules in story terms (no text appears during trials).
	"herd_intro": {
		"next": UIConst.SCENE_GONOGO,
		"lines": [
			{"speaker": "elder_a", "stage": "outside", "actors": ["kid", "elder_a", "elder_b"], "effect": "shake",
			"text": "Quick, little traveler! The calves have wandered into the [color=#a6e22e]tall grass[/color]!"},
			{"speaker": "elder_b",
			"text": "Our young longhorns are gentle and curious. You are the herder today: when a calf runs past, tap to guide it home."},
			{"speaker": "elder_a",
			"text": "But [shake]beware![/shake] Sneaky [color=#ff6b8a]snakes[/color] hide among the calves. Never tap a snake!"},
			{"speaker": "narrator", "choice": {
				"prompt": "Grand Elder Bram stares at you. \"What is your plan?\"",
				"options": [
					{"label": "Calves: yes. Snakes: nope!", "reply": [
						{"speaker": "kid", "text": "Calves: [color=#7dffe6]yes[/color]. Snakes: [shake]NOPE![/shake]"},
						{"speaker": "elder_b", "text": "Exactly. Short, sharp, and snake-proof."},
					]},
					{"label": "Can't I just ask the snakes nicely?", "reply": [
						{"speaker": "kid", "text": "Can't I just ask the snakes [wave]nicely[/wave]?"},
						{"speaker": "elder_a", "text": "[wave]Ha![/wave] They do not listen. Trust me, I tried. Twice."},
					]},
				]}},
			{"speaker": "elder_b",
			"text": "First we will practice a little. Then the real roundup begins."},
		],
	},
	# After the Go/No-Go mission. The plot moves on whatever the score was.
	"herd_after": {
		"next": UIConst.SCENE_HUB,
		"lines": [
			{"speaker": "elder_a", "stage": "outside", "actors": ["kid", "elder_a", "elder_b"],
			"by_band": {
				"great": "Every calf safe, and not a single snake tapped! [wave]Moo-velous![/wave]",
				"good": "The calves are home safe. Well done, little traveler!",
				"tried": "A few snakes slipped through, but the calves are safe because of you. Thank you!",
			}},
			{"speaker": "elder_b", "text": "The elders will call on you again soon."},
			{"speaker": "kid", "text": "I'll be ready!"},
			{"speaker": "narrator", "text": "The calves are safe, for now."},
		],
	},
	# Before the Sorting Day mission.
	"dccs_intro": {
		"next": UIConst.SCENE_DCCS,
		"lines": [
			{"speaker": "elder_b", "stage": "pens", "actors": ["kid", "elder_a", "elder_b"],
			"text": "Today is [wave]Sorting Day[/wave]! Every gift from the market must go into the right pen."},
			{"speaker": "elder_a",
			"text": "[color=#7aa8ff]Blue[/color] gifts go in the left pen. [color=#ffb347]Orange[/color] gifts go in the right pen. That is the color rule."},
			{"speaker": "elder_b",
			"text": "But careful! Sometimes the rule [shake]changes[/shake], and we sort by shape. Stars go left, round gifts go right."},
			{"speaker": "narrator", "choice": {
				"prompt": "A pile of gifts waits. How will you keep track of the rule?",
				"options": [
					{"label": "I'll check the sign every time!", "reply": [
						{"speaker": "kid", "text": "I'll check the sign every single time!"},
						{"speaker": "elder_a", "text": "Good thinking. A sharp eye beats a fast hoof."},
					]},
					{"label": "Color, shape... my head is spinning!", "reply": [
						{"speaker": "kid", "text": "Color, shape... color, shape... [wave]my head is spinning![/wave]"},
						{"speaker": "elder_b", "text": "It spins at first. Then it clicks. You will see."},
					]},
				]}},
			{"speaker": "elder_a", "text": "Let us begin."},
		],
	},
	# After the Sorting Day mission.
	"dccs_after": {
		"next": UIConst.SCENE_HUB,
		"lines": [
			{"speaker": "elder_b", "stage": "pens", "actors": ["kid", "elder_a", "elder_b"],
			"by_band": {
				"great": "Every gift in the right pen, even when the rule changed! You think [wave]fast[/wave], little traveler.",
				"good": "Nicely sorted! The pens are tidy and the market is happy.",
				"tried": "A few gifts landed in the wrong pen, but changing rules is tricky. You kept going, and that is what counts.",
			}},
			{"speaker": "elder_a", "text": "The whole village thanks you."},
			{"speaker": "narrator", "text": "Sorting Day is done."},
		],
	},
	# Before the Night Watch mission. Nothing on screen changes during the watch itself.
	"cpt_intro": {
		"next": UIConst.SCENE_CPT,
		"lines": [
			{"speaker": "narrator", "stage": "night", "actors": ["kid", "elder_a"],
			"text": "Night falls over the Longhorn Planet. The herd sleeps by a [wave]quiet stream[/wave]."},
			{"speaker": "elder_a",
			"text": "Someone has been sneaking hay out of the barn after dark. We caught a glimpse of the thief. It is a [shake]cow[/shake]. In a [shake]ski mask[/shake]."},
			{"speaker": "elder_b",
			"text": "We are all very embarrassed. Please do not tell the other planets."},
			{"speaker": "elder_a",
			"text": "We need a sharp-eyed watcher."},
			{"speaker": "elder_a",
			"text": "The rest of the herd will wander past in the dark. They are honest cows, every one. Ignore them."},
			{"speaker": "elder_a", "effect": "shake",
			"text": "But when you see the cow in the [shake]ski mask[/shake], shine your flashlight on him! Only then."},
			{"speaker": "narrator", "choice": {
				"prompt": "The stars blink. Grand Elder Bram whispers: \"Are you ready for the watch?\"",
				"options": [
					{"label": "Only the masked cow. I'll stay very still.", "reply": [
						{"speaker": "kid", "text": "Only the masked cow. I'll stay very, very still."},
						{"speaker": "elder_a", "text": "Perfect. Patience is a watcher's best horn."},
					]},
					{"label": "What if I get sleepy?", "reply": [
						{"speaker": "kid", "text": "What if I get a little [wave]sleepy[/wave]?"},
						{"speaker": "elder_b", "text": "Then blink slowly and breathe. The stream will keep you company."},
					]},
				]}},
			{"speaker": "narrator", "text": "The stream murmurs. The watch begins..."},
		],
	},
	# After the Night Watch mission.
	"cpt_after": {
		"next": UIConst.SCENE_HUB,
		"lines": [
			{"speaker": "elder_a", "stage": "night", "actors": ["kid", "elder_a"],
			"by_band": {
				"great": "Not one masked cow got past you! You have the eyes of an [wave]owl[/wave].",
				"good": "The masked cow ran off empty-handed. Well watched, little traveler!",
				"tried": "The night was long, and the masked cow slipped by once or twice. But you stayed on watch, and the hay is safe.",
			}},
			{"speaker": "elder_b", "text": "We found the ski mask by the stream this morning. The cow says it was cold."},
			{"speaker": "narrator", "text": "Morning light touches the stream."},
		],
	},
	# After every mission has been played once.
	"finale": {
		"next": UIConst.SCENE_HUB,
		"lines": [
			{"speaker": "narrator", "stage": "outside", "actors": ["kid", "elder_a", "elder_b"], "effect": "drums",
			"text": "The sun rises over the Longhorn Planet. The herd is safe, the gifts are sorted, and the drums are [wave]playing[/wave]."},
			{"speaker": "elder_a",
			"text": "You have done everything we asked, little traveler. The longhorns will never forget you."},
			{"speaker": "elder_b",
			"text": "You are always welcome here, starling. Come back any time, and we will find new things to do together."},
			{"speaker": "narrator", "choice": {
				"prompt": "The elders smile at you. What do you say?",
				"options": [
					{"label": "I'll visit again tomorrow!", "reply": [
						{"speaker": "kid", "text": "I'll visit again [color=#7dffe6]tomorrow[/color]!"},
						{"speaker": "elder_b", "text": "We will save you the best hay."},
					]},
					{"label": "Let's teach the herd to play drums!", "reply": [
						{"speaker": "kid", "text": "Let's teach the [wave]herd[/wave] to play drums!"},
						{"speaker": "elder_a", "effect": "drums", "text": "[wave]Ha![/wave] Moo-velous idea."},
					]},
				]}},
			{"speaker": "narrator", "text": "[color=#ffd27d]Quest complete.[/color] Thank you for playing!"},
		],
	},
}

## How the elders react: Corsi by the longest span, Go/No-Go and DCCS by accuracy, CPT by d-prime.
## Anything else counts as "good".
static func performance_band(results: Dictionary) -> String:
	# Results tagged with their mission (by StoryFlow) are judged the way that task is scored.
	match String(results.get("mission_id", "")):
		"dccs":
			return _band_by_accuracy(float(results.get("mixed_accuracy", 0.0)))
		"cpt":
			var d_prime := float(results.get("d_prime", 0.0))
			if d_prime >= StoryConst.BAND_GREAT_MIN_DPRIME:
				return "great"
			return "good" if d_prime >= StoryConst.BAND_GOOD_MIN_DPRIME else "tried"
	if results.has("max_span"):
		var span := int(results["max_span"])
		if span >= StoryConst.BAND_GREAT_MIN_SPAN:
			return "great"
		if span >= StoryConst.BAND_GOOD_MIN_SPAN:
			return "good"
		return "tried"
	if results.has("accuracy"):
		return _band_by_accuracy(float(results["accuracy"]))
	return StoryConst.BAND_DEFAULT


static func _band_by_accuracy(accuracy: float) -> String:
	if accuracy >= StoryConst.BAND_GREAT_MIN_ACCURACY:
		return "great"
	return "good" if accuracy >= StoryConst.BAND_GOOD_MIN_ACCURACY else "tried"


## The beat's lines with any "by_band" text resolved for this run.
static func lines_for(beat_id: String, results: Dictionary = {}) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not BEATS.has(beat_id):
		return out
	var band := performance_band(results)
	for entry: Dictionary in BEATS[beat_id]["lines"]:
		var line := entry.duplicate()
		if line.has("by_band"):
			var variants: Dictionary = line["by_band"]
			line["text"] = variants[band]
			line.erase("by_band")
		out.append(line)
	return out


## Every piece of text in a list of lines: line text, choice prompts, option labels and replies.
static func all_texts(lines: Array) -> Array[String]:
	var out: Array[String] = []
	for entry: Variant in lines:
		var line: Dictionary = entry
		if line.has("text"):
			out.append(String(line["text"]))
		if line.has("choice"):
			var choice: Dictionary = line["choice"]
			out.append(String(choice["prompt"]))
			for option: Dictionary in choice["options"]:
				out.append(String(option["label"]))
				out.append_array(all_texts(option["reply"]))
	return out


static func next_scene(beat_id: String) -> String:
	if not BEATS.has(beat_id):
		return ""
	return String(BEATS[beat_id]["next"])


## Returns {} for an unknown id.
static func mission(mission_id: String) -> Dictionary:
	for entry: Dictionary in MISSIONS:
		if entry["id"] == mission_id:
			return entry
	return {}


static func is_playable(mission_id: String) -> bool:
	return String(mission(mission_id).get("scene", "")) != ""
