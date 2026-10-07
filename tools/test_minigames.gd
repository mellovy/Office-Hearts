extends SceneTree
## Headless smoke test for EVERY registered minigame.
## Run:
##   godot --headless --path . --script res://tools/test_minigames.gd
## Instantiates each minigame via MinigameRegistry, builds its UI, checks that
## _finish is idempotent, that Esc forfeits with the right payload, and (for a
## few) that a win path succeeds while a lose path fails.
##
## NOTE: the minigames load lazily (MinigameRegistry.create) so they compile
## after autoloads exist; this script never names them as static types, else the
## main script would be compiled before the Audio autoload is registered.

var _fails: Array[String] = []
var _ran: bool = false


func _initialize() -> void:
	# Defer until the first frame so nodes are really inside the tree;
	# the base class calls get_viewport() when Esc forfeits.
	_run.call_deferred()


func _run() -> void:
	if _ran:
		return
	_ran = true
	# Every id in the registry (not a hardcoded subset).
	for id in MinigameRegistry.ids():
		_test(String(id))
	await _probe_evidence()
	await _probe_latte()
	await _probe_password()
	if _fails.is_empty():
		print("MINIGAME TEST OK")
		quit(0)
	else:
		print("MINIGAME TEST FAILED:")
		for f in _fails:
			print("  - ", f)
		quit(1)


# ---------------------------------------------------------------- generic

func _test(id: String) -> void:
	if not MinigameRegistry.has(id):
		_fails.append("%s: MinigameRegistry has no resolvable entry" % id)
		return
	var m: MinigameBase = MinigameRegistry.create(id)
	if m == null:
		_fails.append("%s: MinigameRegistry.create returned null" % id)
		return
	root.add_child(m)
	m.setup({"title": "Test", "prompt": "Probe", "difficulty": 0.5, "seed": 4242, "accent": Color("#E8447E")})

	if m.find_child("Board", true, false) == null:
		_fails.append("%s: no 'Board' panel built" % id)
	if m.custom_minimum_size.x < 720.0 or m.custom_minimum_size.y < 420.0:
		_fails.append("%s: expected 720x420 minimum, got %s" % [id, str(m.custom_minimum_size)])
	if m.get_child_count() == 0:
		_fails.append("%s: no children after _build" % id)

	var meta: Dictionary = m.meta()
	if String(meta.get("id", "")) != id:
		_fails.append("%s: meta id mismatch ('%s')" % [id, String(meta.get("id", ""))])
	for key in ["title", "blurb", "instructions"]:
		if String(meta.get(key, "")).strip_edges() == "":
			_fails.append("%s: meta '%s' missing" % [id, key])

	# _finish must be idempotent (emit exactly once)
	var box: Dictionary = _watch(m)
	m._finish(true, {"probe": true})
	m._finish(true, {"probe": true})
	if int(box["n"]) != 1:
		_fails.append("%s: _finish emitted %d times (expected 1)" % [id, int(box["n"])])
	if not bool(box["ok"]) or not bool((box["res"] as Dictionary).get("probe", false)):
		_fails.append("%s: success payload not delivered" % id)
	m.queue_free()

	# Esc / forfeit path must emit finished(false, {"forfeit": true})
	var m2: MinigameBase = MinigameRegistry.create(id)
	root.add_child(m2)
	m2.setup({"title": "Test", "prompt": "Probe", "difficulty": 0.5, "seed": 99, "accent": Color("#E8447E")})
	var box2: Dictionary = _watch(m2)
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	m2._unhandled_input(ev)
	if int(box2["n"]) != 1:
		_fails.append("%s: forfeit emitted %d times (expected 1)" % [id, int(box2["n"])])
	elif bool(box2["ok"]) or not bool((box2["res"] as Dictionary).get("forfeit", false)):
		_fails.append("%s: forfeit payload wrong: %s" % [id, str(box2["res"])])
	m2.queue_free()

	print("  - %s: panel built, idempotent finish, Esc forfeit ok" % id)


func _watch(m: MinigameBase) -> Dictionary:
	var box: Dictionary = {"n": 0, "ok": null, "res": {}}
	m.finished.connect(func(success: bool, result: Dictionary) -> void:
		box["n"] = int(box["n"]) + 1
		box["ok"] = success
		box["res"] = result)
	return box


func _spawn(id: String, seed_val: int) -> MinigameBase:
	var m: MinigameBase = MinigameRegistry.create(id)
	if m == null:
		_fails.append("%s: create returned null for probe" % id)
		return null
	root.add_child(m)
	m.setup({"difficulty": 0.5, "seed": seed_val, "accent": Color("#E8447E")})
	return m


# ---------------------------------------------------------------- win / lose

func _probe_evidence() -> void:
	# win: inspect every clue
	var m: MinigameBase = _spawn("evidence_hunt", 7)
	if m == null:
		return
	var box: Dictionary = _watch(m)
	var spots: Array = m.get("_spots")
	for i in range(spots.size()):
		var s: Dictionary = spots[i]
		if bool(s["clue"]):
			m.call("_activate", i)
	await create_timer(1.3).timeout
	if box["ok"] != true:
		_fails.append("evidence_hunt: win path did not succeed")
	m.queue_free()

	# lose: rack up strikes on decoys
	var m2: MinigameBase = _spawn("evidence_hunt", 8)
	if m2 == null:
		return
	var box2: Dictionary = _watch(m2)
	var spots2: Array = m2.get("_spots")
	var max_strikes: int = int(m2.get("_max_strikes"))
	var hits: int = 0
	for i in range(spots2.size()):
		var s2: Dictionary = spots2[i]
		if not bool(s2["clue"]) and hits <= max_strikes:
			m2.call("_activate", i)
			hits += 1
	await create_timer(1.3).timeout
	if box2["ok"] != false:
		_fails.append("evidence_hunt: lose path did not fail")
	m2.queue_free()


func _probe_latte() -> void:
	# win: stop dead centre three times
	var m: MinigameBase = _spawn("latte_timing", 21)
	if m == null:
		return
	var box: Dictionary = _watch(m)
	for _r in range(3):
		await create_timer(1.0).timeout
		m.set("_mx", 0.5)
		m.call("_stop")
	await create_timer(2.0).timeout
	if box["ok"] != true:
		_fails.append("latte_timing: win path did not succeed")
	m.queue_free()

	# lose: miss three times
	var m2: MinigameBase = _spawn("latte_timing", 22)
	if m2 == null:
		return
	var box2: Dictionary = _watch(m2)
	for _r in range(3):
		await create_timer(1.0).timeout
		m2.set("_mx", 0.02)
		m2.call("_stop")
	await create_timer(2.0).timeout
	if box2["ok"] != false:
		_fails.append("latte_timing: lose path did not fail")
	m2.queue_free()


func _probe_password() -> void:
	# win: submit the secret
	var m: MinigameBase = _spawn("password_deduction", 31)
	if m == null:
		return
	var box: Dictionary = _watch(m)
	var secret: Array = m.get("_secret")
	var e: Array[int] = []
	for d in secret:
		e.append(int(d))
	m.set("_entry", e)
	m.call("_submit")
	await create_timer(1.2).timeout
	if box["ok"] != true:
		_fails.append("password_deduction: win path did not succeed")
	m.queue_free()

	# lose: burn every guess on a wrong code
	var m2: MinigameBase = _spawn("password_deduction", 32)
	if m2 == null:
		return
	var box2: Dictionary = _watch(m2)
	var secret2: Array = m2.get("_secret")
	var wrong: Array[int] = []
	for d in secret2:
		wrong.append((int(d) + 1) % 10)
	var max_guesses: int = int(m2.get("_max_guesses"))
	for _g in range(max_guesses):
		var e2: Array[int] = []
		for d in wrong:
			e2.append(d)
		m2.set("_entry", e2)
		m2.call("_submit")
	await create_timer(1.2).timeout
	if box2["ok"] != false:
		_fails.append("password_deduction: lose path did not fail")
	m2.queue_free()
