extends SceneTree
## Headless story-data validator. Run:
##   godot --headless --path . --script res://tools/validate_story.gd
## Exits non-zero (via failure count) on broken chapter data.

const MODULES := [
	preload("res://scripts/story/story_common.gd"),
	preload("res://scripts/story/story_arthur.gd"),
	preload("res://scripts/story/story_dante.gd"),
	preload("res://scripts/story/story_leo.gd"),
]

var chapters: Dictionary = {}
var graph: GDScript = preload("res://scripts/story/story_graph.gd")
var audio_script: GDScript = preload("res://scripts/Audio.gd")
var failures: Array = []


func _initialize() -> void:
	for m in MODULES:
		chapters.merge(m.CHAPTERS)

	var ids: Array = chapters.keys()
	var node_ids := {}
	for n in graph.FLOW_NODES:
		node_ids[n["id"]] = true
	var valid_scenes: Array = PixelArt.scene_keys()

	for id in ids:
		_check_chapter(String(id), chapters[id], node_ids, valid_scenes)

	_check_options()
	_check_reachability()
	_check_layout()

	if failures.is_empty():
		print("STORY VALIDATION OK — %d chapters, %d graph nodes, %d endings" % [
			ids.size(), graph.FLOW_NODES.size(), graph.ENDING_IDS.size()])
		quit(0)
	else:
		print("STORY VALIDATION FAILED — %d problem(s):" % failures.size())
		for f in failures:
			print("  - ", f)
		quit(1)


func _fail(msg: String) -> void:
	failures.append(msg)


func _check_chapter(id: String, ch: Dictionary, node_ids: Dictionary, scenes: Array) -> void:
	for key in ["title", "location", "bgm_key", "bg_scene", "route", "lines"]:
		if not ch.has(key):
			_fail("%s missing key '%s'" % [id, key])
	if ch.has("bgm_key") and not audio_script.MOODS.has(String(ch["bgm_key"])):
		_fail("%s has unknown bgm_key '%s'" % [id, ch["bgm_key"]])
	if ch.has("bg_scene") and not scenes.has(String(ch["bg_scene"])):
		_fail("%s has unknown bg_scene '%s'" % [id, ch["bg_scene"]])
	if ch.has("minigame"):
		_validate_minigame(id, ch)
	if ch.has("choice"):
		_validate_choice(id, ch["choice"])
	elif ch.has("next"):
		var nxt := String(ch["next"])
		if nxt != "game_end" and not node_ids.has(nxt):
			_fail("%s next -> unknown chapter '%s'" % [id, nxt])
	elif not ch.has("ending"):
		_fail("%s has no choice, no next, and no ending" % id)
	if ch.has("ending"):
		for key in ["ending_name", "ending_desc"]:
			if not ch.has(key) or String(ch[key]).strip_edges() == "":
				_fail("ending %s missing '%s'" % [id, key])
	var lines: Array = ch.get("lines", [])
	for i in range(lines.size()):
		if not lines[i].has("text") or not lines[i].has("speaker"):
			_fail("%s line %d needs speaker+text" % [id, i])


## Optional chapter key: {"id":..., "success_flag":..., "difficulty":...}
func _validate_minigame(id: String, ch: Dictionary) -> void:
	var mg = ch.get("minigame", null)
	if typeof(mg) != TYPE_DICTIONARY:
		_fail("%s 'minigame' must be a Dictionary" % id)
		return
	var mgd: Dictionary = mg
	var mid := String(mgd.get("id", ""))
	if mid.strip_edges() == "":
		_fail("%s minigame is missing an id" % id)
	elif not MinigameRegistry.PATHS.has(mid):
		_fail("%s minigame id '%s' is not in MinigameRegistry.PATHS" % [id, mid])
	if mgd.has("success_flag"):
		var flag := String(mgd.get("success_flag", ""))
		if flag.strip_edges() == "":
			_fail("%s minigame success_flag must be a non-empty string" % id)
		else:
			var route := String(ch.get("route", ""))
			if flag.ends_with("_evidence") and flag != route + "_evidence":
				_fail("%s minigame success_flag '%s' does not match route '%s_evidence'" % [id, flag, route])
	if mgd.has("difficulty"):
		var d := float(mgd.get("difficulty", 0.5))
		if d < 0.0 or d > 1.0:
			_fail("%s minigame difficulty %.2f is outside 0..1" % [id, d])


func _validate_choice(id: String, choice: Dictionary) -> void:
	var options: Array = choice.get("options", [])
	if options.is_empty():
		_fail("%s choice has no options" % id)
		return
	var ungated := 0
	for opt in options:
		if not opt.has("requires"):
			ungated += 1
		if not opt.has("next"):
			_fail("%s option '%s' missing next" % [id, String(opt.get("text", "")).substr(0, 30)])
		if opt.has("char") and not ["arthur", "dante", "leo", ""].has(String(opt["char"])):
			_fail("%s option has bad char '%s'" % [id, opt["char"]])
	if ungated == 0:
		_fail("%s choice has NO ungated option (player could get stuck)" % id)


func _check_options() -> void:
	for id in chapters.keys():
		var ch: Dictionary = chapters[id]
		if not ch.has("choice"):
			continue
		for opt in ch["choice"]["options"]:
			var nxt := String(opt.get("next", "game_end"))
			if nxt != "game_end" and not chapters.has(nxt):
				_fail("%s option next -> unknown chapter '%s'" % [id, nxt])


## No two flowchart nodes may overlap (mirrors Flowchart.gd spacing constants).
func _check_layout() -> void:
	const NODE_W := 150.0
	const NODE_H := 64.0
	const COL := 220.0
	const ROW := 130.0
	var nodes: Array = graph.FLOW_NODES
	for i in range(nodes.size()):
		for j in range(i + 1, nodes.size()):
			var a: Dictionary = nodes[i]
			var b: Dictionary = nodes[j]
			var dx: float = abs((float(a["col"]) - float(b["col"])) * COL)
			var dy: float = abs((float(a["row"]) - float(b["row"])) * ROW)
			if dx < NODE_W and dy < NODE_H:
				_fail("flowchart nodes overlap: %s @(%s,%s) vs %s @(%s,%s)" % [
					a["id"], a["col"], a["row"], b["id"], b["col"], b["row"]])


## Every route must be able to set its evidence flag and reach all three endings.
func _check_reachability() -> void:
	for route in ["arthur", "dante", "leo"]:
		var evidence_seen := false
		for id in chapters.keys():
			if not String(id).begins_with(route):
				continue
			var ch: Dictionary = chapters[id]
			# The evidence flag is granted by the route's minigame, not a choice.
			if ch.has("minigame") and String(ch["minigame"].get("success_flag", "")) == route + "_evidence":
				evidence_seen = true
			if not ch.has("choice"):
				continue
			for opt in ch["choice"]["options"]:
				if String(opt.get("sets_flag", "")) == route + "_evidence":
					evidence_seen = true
				if String(opt.get("next", "")) == route + "_end_true" and not opt.has("requires"):
					_fail("%s_end_true option must stay gated" % route)
		if not evidence_seen:
			_fail("%s route never sets '%s_evidence' flag" % [route, route])
		for kind in ["good", "true", "bad"]:
			if not chapters.has("%s_end_%s" % [route, kind]):
				_fail("%s_end_%s chapter missing" % [route, kind])
