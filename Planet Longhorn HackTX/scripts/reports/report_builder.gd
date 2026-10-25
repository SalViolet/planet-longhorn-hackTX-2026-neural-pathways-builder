class_name ReportBuilder
extends RefCounted
## Turns a profile's run history into a printable HTML report, laid out like a short
## neuropsychological summary: identifying details, purpose and limits, tests given, data
## quality, results per test (every run, then a summary), domain overview, notes, glossary.
## Pure logic: give it the data, get a string back.
##
## data = {
##   "name": String, "generated": "YYYY-MM-DDTHH:MM:SS", "runs": Array of RunHistory entries,
##   "levels": {mission_id: {"level": int, "max": int}}, "skips": {mission_id: int},
## }

const STYLE := """
body{font-family:-apple-system,Helvetica,Arial,sans-serif;max-width:900px;margin:2em auto;padding:0 1em;color:#1b1b1b;line-height:1.45}
h1{font-size:1.6em;margin-bottom:0} h2{font-size:1.2em;margin-top:1.8em;border-bottom:2px solid #333;padding-bottom:.2em}
h3{font-size:1.05em;margin-top:1.4em} .sub{color:#555;margin-top:.2em}
table{border-collapse:collapse;width:100%;margin:.6em 0;font-size:.92em}
th,td{border:1px solid #bbb;padding:.35em .55em;text-align:left;vertical-align:top} th{background:#eee}
td.n{text-align:right;white-space:nowrap} .box{border:2px solid #333;padding:.2em 1em;background:#f6f6f0}
.small{font-size:.85em;color:#555} @media print{body{margin:0}h2{page-break-after:avoid}table{page-break-inside:auto}}
"""


static func build(data: Dictionary) -> String:
	var runs: Array = data["runs"]
	var parts := PackedStringArray()
	parts.append("<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\"><title>%s</title><style>%s</style></head><body>" % [ReportText.TITLE, STYLE])
	parts.append("<h1>%s</h1><p class=\"sub\">%s</p>" % [ReportText.TITLE, ReportText.SUBTITLE])
	parts.append(_identifying(data, runs))
	parts.append(_limits())
	parts.append(_tests_given(runs, data))
	parts.append(_data_quality(runs, data))
	parts.append(_day_overview(runs))
	parts.append("<h2>Results by task</h2>")
	for task: Dictionary in ReportConst.TASKS:
		parts.append(_task_section(task, _runs_for(runs, task["id"])))
	parts.append(_domain_overview(runs, data))
	parts.append(_cautions())
	parts.append(_glossary())
	parts.append("</body></html>")
	return "\n".join(parts)


static func escape(text: String) -> String:
	return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;")


static func date_of(time_text: String) -> String:
	return time_text.substr(0, 10)


static func format_value(value: float, kind: String) -> String:
	match kind:
		"percent":
			return "%d%%" % roundi(value * 100.0)
		"ms":
			return "%d ms" % roundi(value)
		"score":
			return "%.2f" % value
	return str(roundi(value)) if is_equal_approx(value, roundf(value)) else "%.1f" % value


static func _runs_for(runs: Array, mission_id: String) -> Array:
	return runs.filter(func(r: Dictionary) -> bool: return r["mission"] == mission_id)


static func _identifying(data: Dictionary, runs: Array) -> String:
	var dates := PackedStringArray()
	for run: Dictionary in runs:
		var d := date_of(String(run["time"]))
		if d not in dates:
			dates.append(d)
	dates.sort()
	var period := "No runs recorded"
	if not dates.is_empty():
		period = dates[0] if dates.size() == 1 else "%s to %s" % [dates[0], dates[dates.size() - 1]]
	var rows := [
		["Player (nickname)", escape(String(data["name"]))],
		["Report generated", escape(date_of(String(data["generated"])))],
		["Play period covered", period],
		["Days with play", str(dates.size())],
		["Finished runs included", str(runs.size())],
		["Age / age band", "Not recorded"],
	]
	return "<h2>Identifying details</h2>" + _kv_table(rows)


static func _limits() -> String:
	return "<h2>%s</h2><div class=\"box\">%s</div>" % [ReportText.LIMITS_HEADING, _paragraphs(ReportText.LIMITS)]


static func _tests_given(runs: Array, data: Dictionary) -> String:
	var html := "<h2>Tasks given</h2><table><tr><th>Task</th><th>Domain</th><th>What the player does</th><th>Runs</th><th>First</th><th>Latest</th><th>Levels played</th></tr>"
	var levels: Dictionary = data["levels"]
	for task: Dictionary in ReportConst.TASKS:
		var task_runs := _runs_for(runs, task["id"])
		var first := date_of(String(task_runs[0]["time"])) if not task_runs.is_empty() else "-"
		var latest := date_of(String(task_runs[task_runs.size() - 1]["time"])) if not task_runs.is_empty() else "-"
		html += "<tr><td>%s</td><td>%s</td><td>%s</td><td class=\"n\">%d</td><td class=\"n\">%s</td><td class=\"n\">%s</td><td>%s</td></tr>" % [
			escape(task["title"]), escape(task["domain"]), escape(task["paradigm"]), task_runs.size(),
			first, latest, _level_range(task_runs, levels.get(task["id"], {}))]
	return html + "</table>"


static func _level_range(task_runs: Array, level_info: Dictionary) -> String:
	if task_runs.is_empty():
		return "-"
	var low := 999
	var high := -1
	for run: Dictionary in task_runs:
		var level := int((run["metrics"] as Dictionary).get("difficulty_level", -1))
		if level < 0:
			continue
		low = mini(low, level)
		high = maxi(high, level)
	if high < 0:
		return "-"
	var of_max := " of %d" % (int(level_info["max"]) + 1) if level_info.has("max") else ""
	var text := "%d" % (low + 1) if low == high else "%d to %d" % [low + 1, high + 1]
	return text + of_max


static func _data_quality(runs: Array, data: Dictionary) -> String:
	var invalid := 0
	var anticipatory := 0
	var scored := 0
	for run: Dictionary in runs:
		var m: Dictionary = run["metrics"]
		invalid += int(m.get("invalid_trials", 0))
		anticipatory += int(m.get("anticipatory_responses", 0))
		scored += int(m.get("total_trials", 0))
	var skipped := 0
	for mission_id: String in data["skips"]:
		skipped += int(data["skips"][mission_id])
	var all_trials := maxi(scored + invalid, 1)
	var notes: Array[String] = []
	if float(invalid) / all_trials > ReportConst.INVALID_SHARE_CONCERN:
		notes.append("More than %d%% of trials were interrupted (for example the window lost focus or the player paused). Results may under-represent usual performance." % roundi(ReportConst.INVALID_SHARE_CONCERN * 100.0))
	if float(anticipatory) / all_trials > ReportConst.ANTICIPATORY_SHARE_CONCERN:
		notes.append("More than %d%% of responses were faster than 100 ms, which suggests some guessing or tapping ahead of the stimulus." % roundi(ReportConst.ANTICIPATORY_SHARE_CONCERN * 100.0))
	if notes.is_empty():
		notes.append("No data-quality concerns were flagged by the game's simple checks.")
	var rows := [
		["Scored trials", str(scored)],
		["Interrupted trials (left out of scores)", str(invalid)],
		["Anticipatory responses (under 100 ms, kept but flagged)", str(anticipatory)],
		["Tasks the player chose to skip", str(skipped)],
	]
	return "<h2>Data quality and behavioural observations</h2>" + _kv_table(rows) + _paragraphs(notes)


static func _task_section(task: Dictionary, task_runs: Array) -> String:
	var html := "<h3>%s: %s</h3>" % [escape(task["title"]), escape(task["domain"])]
	if task_runs.is_empty():
		return html + "<p>Not played yet.</p>"
	var metrics: Array = task["metrics"]
	html += "<table><tr><th>Date</th><th>Level</th>"
	for metric: Dictionary in metrics:
		html += "<th>%s</th>" % escape(metric["label"])
	html += "</tr>"
	for run: Dictionary in task_runs:
		var m: Dictionary = run["metrics"]
		var level := int(m.get("difficulty_level", -1)) + 1
		html += "<tr><td class=\"n\">%s</td><td class=\"n\">%d</td>" % [date_of(String(run["time"])), level]
		for metric: Dictionary in metrics:
			html += "<td class=\"n\">%s</td>" % _cell(m, metric)
		html += "</tr>"
	html += "</table>"
	html += _daily_table(task, task_runs)
	html += "<table><tr><th>Summary across runs</th><th>Runs</th><th>Mean (SD)</th><th>Range</th><th>First</th><th>Latest</th><th>Earlier vs later runs</th></tr>"
	for metric: Dictionary in metrics:
		var values := ReportStats.series(task_runs, metric["key"])
		if values.is_empty():
			continue
		var kind: String = metric["kind"]
		html += "<tr><td>%s</td><td class=\"n\">%d</td><td class=\"n\">%s (%s)</td><td class=\"n\">%s to %s</td><td class=\"n\">%s</td><td class=\"n\">%s</td><td>%s</td></tr>" % [
			escape(metric["label"]), values.size(),
			format_value(ReportStats.mean(values), kind), format_value(ReportStats.sd(values), kind),
			format_value(values.min(), kind), format_value(values.max(), kind),
			format_value(values[0], kind), format_value(values[values.size() - 1], kind),
			ReportStats.trend_text(ReportStats.trend(values))]
	html += "</table>"
	if task["id"] == "cpt":
		html += _vigilance(task_runs)
	return html


## One row per day: how many of the four tasks were finished, the points that earned, and
## the trials that were interrupted.
static func _day_overview(runs: Array) -> String:
	var days := ReportStats.group_by_day(runs)
	var points := PointsRules.tally(runs)
	var html := "<h2>Day by day</h2><table><tr><th>Date</th><th>Tasks finished (of %d)</th><th>Runs</th><th>Points from recorded runs</th><th>Interrupted trials</th></tr>" % PointsConst.REQUIRED_TASKS.size()
	if days.is_empty():
		return html + "<tr><td colspan=\"5\">No runs recorded.</td></tr></table>"
	for day: String in days:
		var day_runs: Array = days[day]
		var interrupted := 0
		for run: Dictionary in day_runs:
			interrupted += int((run["metrics"] as Dictionary).get("invalid_trials", 0))
		var entry: Dictionary = points[day]
		html += "<tr><td class=\"n\">%s</td><td class=\"n\">%d</td><td class=\"n\">%d</td><td class=\"n\">%d</td><td class=\"n\">%d</td></tr>" % [
			day, (entry["done"] as Array).size(), day_runs.size(), int(entry["points"]), interrupted]
	return html + "</table>"


## The task's metrics averaged for each day it was played.
static func _daily_table(task: Dictionary, task_runs: Array) -> String:
	var metrics: Array = task["metrics"]
	var html := "<table><tr><th>Day average</th><th>Runs</th>"
	for metric: Dictionary in metrics:
		html += "<th>%s</th>" % escape(metric["label"])
	html += "</tr>"
	var days := ReportStats.group_by_day(task_runs)
	for day: String in days:
		var day_runs: Array = days[day]
		html += "<tr><td class=\"n\">%s</td><td class=\"n\">%d</td>" % [day, day_runs.size()]
		for metric: Dictionary in metrics:
			var values := ReportStats.series(day_runs, metric["key"])
			html += "<td class=\"n\">%s</td>" % (format_value(ReportStats.mean(values), metric["kind"]) if not values.is_empty() else "n/a")
		html += "</tr>"
	return html + "</table>"


## Long-format CSV for spreadsheets: one row per day, task and metric (the day's average).
static func daily_csv(runs: Array) -> String:
	var lines := PackedStringArray(["date,task,runs_that_day,metric,day_average"])
	var days := ReportStats.group_by_day(runs)
	for day: String in days:
		for task: Dictionary in ReportConst.TASKS:
			var task_runs := _runs_for(days[day], task["id"])
			if task_runs.is_empty():
				continue
			for metric: Dictionary in task["metrics"]:
				var values := ReportStats.series(task_runs, metric["key"])
				if values.is_empty():
					continue
				lines.append("%s,%s,%d,%s,%s" % [day, task["id"], task_runs.size(), metric["key"],
						String.num(ReportStats.mean(values), 4)])
	return "\n".join(lines) + "\n"


static func _cell(metrics: Dictionary, metric: Dictionary) -> String:
	if not metrics.has(metric["key"]):
		return "-"
	var value := float(metrics[metric["key"]])
	if value == 0.0 and String(metric["key"]) in ReportConst.ZERO_MEANS_NA:
		return "n/a"
	return format_value(value, metric["kind"])


## Hit rate in each equal time block of the run, averaged over runs: shows whether attention
## held up as the run went on.
static func _vigilance(task_runs: Array) -> String:
	var sums: Array[float] = []
	var counts: Array[int] = []
	for run: Dictionary in task_runs:
		var bins: Array = run.get("bins", [])
		for i in bins.size():
			if sums.size() <= i:
				sums.append(0.0)
				counts.append(0)
			if bins[i] != null:
				sums[i] += float(bins[i])
				counts[i] += 1
	if sums.is_empty():
		return ""
	var html := "<table><tr><th>Hit rate by time block (average over runs)</th>"
	for i in sums.size():
		html += "<th>Block %d</th>" % (i + 1)
	html += "</tr><tr><td>Hit rate</td>"
	for i in sums.size():
		html += "<td class=\"n\">%s</td>" % (format_value(sums[i] / counts[i], "percent") if counts[i] > 0 else "-")
	return html + "</tr></table><p class=\"small\">A steady rate across blocks means attention was held; a falling rate is a typical vigilance pattern.</p>"


static func _domain_overview(runs: Array, data: Dictionary) -> String:
	var levels: Dictionary = data["levels"]
	var html := "<h2>Overview by domain</h2><table><tr><th>Domain</th><th>Task</th><th>Runs</th><th>Current difficulty level</th></tr>"
	for task: Dictionary in ReportConst.TASKS:
		var info: Dictionary = levels.get(task["id"], {})
		var current := "%d of %d" % [int(info["level"]) + 1, int(info["max"]) + 1] if info.has("level") else "-"
		html += "<tr><td>%s</td><td>%s</td><td class=\"n\">%d</td><td>%s</td></tr>" % [
			escape(task["domain"]), escape(task["title"]), _runs_for(runs, task["id"]).size(), current]
	return html + "</table><p class=\"small\">The difficulty level is the game's own setting for this player. It is not a score and does not compare with other players.</p>"


static func _cautions() -> String:
	return "<h2>%s</h2>%s" % [ReportText.CAUTIONS_HEADING, _bullets(ReportText.CAUTIONS)]


static func _glossary() -> String:
	var html := "<h2>Glossary</h2><table>"
	for entry: Array in ReportConst.GLOSSARY:
		html += "<tr><td>%s</td><td>%s</td></tr>" % [escape(entry[0]), escape(entry[1])]
	return html + "</table>"


static func _kv_table(rows: Array) -> String:
	var html := "<table>"
	for row: Array in rows:
		html += "<tr><th style=\"width:40%%\">%s</th><td>%s</td></tr>" % [escape(row[0]), row[1]]
	return html + "</table>"


static func _paragraphs(lines: Array[String]) -> String:
	var html := ""
	for line in lines:
		html += "<p>%s</p>" % escape(line)
	return html


static func _bullets(lines: Array[String]) -> String:
	var html := "<ul>"
	for line in lines:
		html += "<li>%s</li>" % escape(line)
	return html + "</ul>"
