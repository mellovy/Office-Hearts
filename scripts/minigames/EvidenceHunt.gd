extends MinigameBase
## Dante's archive beat: sweep a dim office for pink-tagged evidence.
## Wrong objects cost a strike; the clock and strikes can both end the run.

const GAME_ID := "evidence_hunt"

const CREAM := Color("#FDE8D0")
const PINK := Color("#F4A0B8")
const PINK_DEEP := Color("#E8447E")
const WINE := Color("#7A2F52")
const LAVENDER := Color("#A99FE0")
const SKY := Color("#A8D8F0")
const INK := Color("#57465F")
const ROOM := Color("#2A1E2E")
const ROOM_EDGE := Color("#6B4A63")
const OBJ := Color("#8A6E86")
const BAD := Color("#D1435F")

var _spots: Array[Dictionary] = []   # {n, kind, clue, found, checked, flash}
var _sel: int = 0
var _hover: int = -1
var _foot_hover: bool = false
var _found: int = 0
var _strikes: int = 0
var _clue_total: int = 3
var _max_strikes: int = 2
var _max_time: float = 40.0
var _time_left: float = 40.0
var _over: bool = false
var _win: bool = false


static func meta() -> Dictionary:
	return {
		"id": GAME_ID,
		"title": "Evidence Hunt",
		"blurb": "Search Dante's dim archive for the tagged files.",
		"instructions": "Move with the arrow keys (or hover the mouse) and press Enter / click to inspect an item. Find every object marked with a pink tag. Inspecting the wrong object costs a strike; running out of time or strikes loses the case. Esc gives up.",
	}


func _build() -> void:
	set_process(true)
	resized.connect(queue_redraw)
	var board := Control.new()
	board.name = "Board"
	board.set_anchors_preset(Control.PRESET_FULL_RECT)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board)
	_setup_spots()
	queue_redraw()


# ---------------------------------------------------------------- setup

func _setup_spots() -> void:
	_spots.clear()
	var d: float = _difficulty()
	_clue_total = int(roundf(lerpf(2.0, 4.0, d)))
	var total: int = int(minf(14.0, 8.0 + float(_clue_total) + roundf(d * 3.0)))
	_max_strikes = int(maxf(1.0, 3.0 - roundf(d * 2.0)))
	_max_time = lerpf(45.0, 26.0, d)
	_time_left = _max_time

	var cells: Array = []
	for row in range(3):
		for col in range(5):
			cells.append(Vector2i(col, row))
	for i in range(cells.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Vector2i = cells[i]
		cells[i] = cells[j]
		cells[j] = tmp

	var kinds: Array[String] = [
		"drawer", "binder", "mug", "monitor", "papers",
		"plant", "clock", "box", "folder", "lamp",
	]

	var idxs: Array = []
	for i in range(total):
		idxs.append(i)
	for i in range(idxs.size() - 1, 0, -1):
		var j2: int = rng.randi_range(0, i)
		var t2: int = idxs[i]
		idxs[i] = idxs[j2]
		idxs[j2] = t2
	var clue_set: Dictionary = {}
	for k in range(_clue_total):
		clue_set[idxs[k]] = true

	for i in range(total):
		var cell: Vector2i = cells[i]
		var nx: float = (float(cell.x) + 0.5) / 5.0 + rng.randf_range(-0.055, 0.055)
		var ny: float = (float(cell.y) + 0.5) / 3.0 + rng.randf_range(-0.06, 0.06)
		_spots.append({
			"n": Vector2(clampf(nx, 0.07, 0.93), clampf(ny, 0.12, 0.88)),
			"kind": kinds[rng.randi_range(0, kinds.size() - 1)],
			"clue": clue_set.has(i),
			"found": false,
			"checked": false,
			"flash": 0.0,
		})


# ---------------------------------------------------------------- layout

func _room_rect() -> Rect2:
	var top: float = 88.0
	var bot: float = 58.0
	return Rect2(16.0, top, size.x - 32.0, maxf(40.0, size.y - top - bot))


func _obj_radius() -> float:
	var r: Rect2 = _room_rect()
	return clampf(minf(r.size.x / 5.6, r.size.y / 3.5), 20.0, 46.0)


func _center(i: int) -> Vector2:
	var r: Rect2 = _room_rect()
	var n: Vector2 = _spots[i]["n"]
	return r.position + Vector2(n.x * r.size.x, n.y * r.size.y)


func _foot_rect() -> Rect2:
	return Rect2(size.x - 130.0, size.y - 46.0, 110.0, 34.0)


# ---------------------------------------------------------------- loop

func _process(delta: float) -> void:
	if not _over:
		_time_left -= delta
		if _time_left <= 0.0:
			_time_left = 0.0
			_end(false, {"found": _found, "reason": "time"})
			return
	for s in _spots:
		if float(s["flash"]) > 0.0:
			s["flash"] = maxf(0.0, float(s["flash"]) - delta)
	queue_redraw()


func _activate(i: int) -> void:
	if _over or i < 0 or i >= _spots.size():
		return
	var s: Dictionary = _spots[i]
	if bool(s["found"]):
		return
	if bool(s["clue"]):
		s["found"] = true
		_found += 1
		Audio.play_sfx("chime")
		if _found >= _clue_total:
			_end(true, {"found": _found})
	else:
		if bool(s["checked"]):
			return
		s["checked"] = true
		s["flash"] = 0.6
		_strikes += 1
		Audio.play_sfx("whoosh")
		if _strikes > _max_strikes:
			_end(false, {"found": _found, "reason": "strikes"})
	queue_redraw()


func _end(success: bool, result: Dictionary) -> void:
	if _over:
		return
	_over = true
	_win = success
	Audio.play_sfx("chime" if success else "whoosh")
	queue_redraw()
	if is_inside_tree():
		await get_tree().create_timer(0.9).timeout
	_finish(success, result)


# ---------------------------------------------------------------- input

func _index_at(p: Vector2) -> int:
	var rad: float = _obj_radius()
	for i in range(_spots.size()):
		if _center(i).distance_to(p) <= rad:
			return i
	return -1


func _gui_input(event: InputEvent) -> void:
	if _over:
		return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var nh: int = _index_at(mm.position)
		var nf: bool = _foot_rect().has_point(mm.position)
		if nh != _hover or nf != _foot_hover:
			_hover = nh
			_foot_hover = nf
			queue_redraw()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if _foot_rect().has_point(mb.position):
				Audio.play_sfx("click")
				_end(false, {"found": _found, "reason": "forfeit"})
				return
			var i: int = _index_at(mb.position)
			if i >= 0:
				_sel = i
				_activate(i)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		super._unhandled_input(event)
		return
	if _over or _spots.is_empty():
		return
	var dir := Vector2i.ZERO
	if event.is_action_pressed("ui_left"):
		dir = Vector2i(-1, 0)
	elif event.is_action_pressed("ui_right"):
		dir = Vector2i(1, 0)
	elif event.is_action_pressed("ui_up"):
		dir = Vector2i(0, -1)
	elif event.is_action_pressed("ui_down"):
		dir = Vector2i(0, 1)
	if dir != Vector2i.ZERO:
		_move_sel(dir)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept"):
		_activate(_sel)
		get_viewport().set_input_as_handled()


func _move_sel(dir: Vector2i) -> void:
	var from: Vector2 = _center(_sel)
	var best: int = _sel
	var best_score: float = INF
	for i in range(_spots.size()):
		if i == _sel:
			continue
		var d: Vector2 = _center(i) - from
		var along: float = d.x * float(dir.x) + d.y * float(dir.y)
		if along <= 1.0:
			continue
		var cross: float = absf(d.x * float(dir.y) - d.y * float(dir.x))
		var score: float = along + cross * 2.0
		if score < best_score:
			best_score = score
			best = i
	if best != _sel:
		_sel = best
		Audio.play_sfx("blip")
		queue_redraw()


# ---------------------------------------------------------------- draw

func _rr(rect: Rect2, radius: float, col: Color) -> void:
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return
	draw_colored_polygon(UIUtil._rounded_points(rect, radius, 8), col)


func _rr_outline(rect: Rect2, radius: float, col: Color, width: float) -> void:
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return
	var pts: PackedVector2Array = UIUtil._rounded_points(rect, radius, 8)
	var out: PackedVector2Array = pts.duplicate()
	out.append(pts[0])
	draw_polyline(out, col, width, true)


func _txt(s: String, pos: Vector2, fsize: int, col: Color, display: bool = false, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	var f: Font = UIUtil.font_bold(true) if display else UIUtil.font_semi()
	draw_string(f, pos, s, align, width, fsize, col)


func _draw() -> void:
	if size.x < 10.0 or size.y < 10.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), CREAM, true)
	_draw_header()
	var r: Rect2 = _room_rect()
	_rr(r, 14.0, ROOM)
	# faint floor line + shelf lines so the wall reads as a room
	var floor_y: float = r.position.y + r.size.y * 0.64
	draw_line(Vector2(r.position.x + 6.0, floor_y), Vector2(r.end.x - 6.0, floor_y), Color(ROOM_EDGE, 0.5), 1.5)
	for row in range(1, 3):
		var sy: float = r.position.y + r.size.y * (0.64 * float(row) / 3.0)
		draw_line(Vector2(r.position.x + 6.0, sy), Vector2(r.end.x - 6.0, sy), Color(ROOM_EDGE, 0.18), 1.0)
	for i in range(_spots.size()):
		_draw_spot(i)
	_draw_footer()
	if _over:
		_draw_banner()


func _draw_header() -> void:
	var w: float = size.x
	_txt("EVIDENCE HUNT", Vector2(24.0, 38.0), 26, WINE, true)
	_txt("Find every item marked with a pink tag.", Vector2(24.0, 62.0), 15, INK)
	_txt("FOUND %d / %d" % [_found, _clue_total], Vector2(w - 240.0, 30.0), 16, PINK_DEEP)
	_txt("STRIKES %d / %d" % [_strikes, _max_strikes], Vector2(w - 120.0, 30.0), 16, INK)
	var bar := Rect2(w - 240.0, 42.0, 216.0, 14.0)
	_rr(bar, 7.0, Color(WINE, 0.22))
	var ratio: float = clampf(_time_left / _max_time, 0.0, 1.0)
	_rr(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), 7.0, LAVENDER.lerp(PINK_DEEP, 1.0 - ratio))
	_txt("%.1fs" % _time_left, Vector2(w - 216.0, 70.0), 13, INK, false, HORIZONTAL_ALIGNMENT_RIGHT, 200.0)


func _draw_spot(i: int) -> void:
	var s: Dictionary = _spots[i]
	var c: Vector2 = _center(i)
	var rad: float = _obj_radius()
	var found: bool = bool(s["found"])
	var flash: float = float(s["flash"])
	var hl: bool = (i == _hover or i == _sel) and not _over

	draw_circle(c + Vector2(2.0, rad * 1.02), rad * 0.6, Color(0.0, 0.0, 0.0, 0.3))
	var base: Color = OBJ if not found else OBJ.lerp(PINK_DEEP, 0.35)
	_draw_kind(String(s["kind"]), c, rad, base)

	if bool(s["clue"]) and not found:
		_draw_tag(c + Vector2(rad * 0.66, -rad * 0.72), rad * 0.34)
	if found:
		draw_circle(c, rad * 1.02, Color(PINK_DEEP, 0.22))
		draw_circle(c, rad * 0.46, PINK_DEEP)
		var chk := PackedVector2Array([
			c + Vector2(-rad * 0.24, rad * 0.02),
			c + Vector2(-rad * 0.05, rad * 0.22),
			c + Vector2(rad * 0.28, -rad * 0.2),
		])
		draw_polyline(chk, CREAM, 4.0, true)
	if flash > 0.0:
		draw_arc(c, rad * 1.16, 0.0, TAU, 32, Color(BAD, flash), 4.0, true)
	if hl:
		draw_arc(c, rad * 1.32, 0.0, TAU, 40, SKY, 2.5, true)


func _draw_tag(pos: Vector2, s: float) -> void:
	var pts := PackedVector2Array()
	for i in range(5):
		var a: float = -PI * 0.5 + TAU * float(i) / 5.0
		pts.append(pos + Vector2(cos(a), sin(a)) * s)
	draw_colored_polygon(pts, PINK_DEEP)
	draw_circle(pos, s * 0.26, CREAM)


func _draw_kind(kind: String, c: Vector2, s: float, col: Color) -> void:
	var lo: Color = col.darkened(0.3)
	var hi: Color = col.lightened(0.22)
	match kind:
		"drawer":
			var body := Rect2(c - Vector2(s * 0.4, s * 0.9), Vector2(s * 0.8, s * 1.8))
			draw_rect(body, col, true)
			draw_rect(body, hi, false, 2.0)
			for k in range(3):
				var yy: float = body.position.y + body.size.y * (0.22 + 0.27 * float(k))
				draw_line(Vector2(body.position.x + 2.0, yy), Vector2(body.end.x - 2.0, yy), lo, 2.0)
				draw_circle(Vector2(c.x, yy + body.size.y * 0.09), s * 0.06, hi)
		"binder":
			var body2 := Rect2(c - Vector2(s * 0.42, s * 0.9), Vector2(s * 0.84, s * 1.8))
			draw_rect(body2, col, true)
			draw_rect(body2, hi, false, 2.0)
			draw_rect(Rect2(body2.position, Vector2(s * 0.16, body2.size.y)), lo, true)
			draw_circle(c + Vector2(s * 0.2, -s * 0.42), s * 0.08, hi)
			draw_circle(c + Vector2(s * 0.2, s * 0.3), s * 0.08, hi)
		"mug":
			var cup := Rect2(c - Vector2(s * 0.5, s * 0.5), Vector2(s * 1.0, s * 1.05))
			draw_rect(cup, col, true)
			draw_rect(cup, hi, false, 2.0)
			draw_arc(c + Vector2(s * 0.5, 0.0), s * 0.34, -PI * 0.5, PI * 0.5, 16, hi, 3.0, true)
			draw_line(c + Vector2(-s * 0.15, -s * 0.7), c + Vector2(-s * 0.05, -s * 1.05), Color(hi, 0.7), 2.0)
		"monitor":
			var scr := Rect2(c - Vector2(s * 0.8, s * 0.62), Vector2(s * 1.6, s * 1.05))
			draw_rect(scr, col, true)
			draw_rect(scr, hi, false, 2.0)
			draw_rect(Rect2(scr.position + Vector2(s * 0.12, s * 0.12), scr.size - Vector2(s * 0.24, s * 0.24)), lo, true)
			draw_rect(Rect2(c - Vector2(s * 0.12, -s * 0.4), Vector2(s * 0.24, s * 0.35)), col, true)
			draw_rect(Rect2(c - Vector2(s * 0.36, s * 0.85), Vector2(s * 0.72, s * 0.14)), col, true)
		"papers":
			for k2 in range(3):
				var off := Vector2(float(k2) * s * 0.14 - s * 0.14, float(k2) * -s * 0.12)
				var pg := Rect2(c - Vector2(s * 0.5, s * 0.62) + off, Vector2(s * 1.0, s * 1.28))
				draw_rect(pg, col.lightened(0.05 * float(k2)), true)
				draw_rect(pg, lo, false, 1.5)
		"plant":
			var pot := Rect2(c - Vector2(s * 0.4, s * 0.12), Vector2(s * 0.8, s * 0.72))
			draw_colored_polygon(PackedVector2Array([
				pot.position,
				Vector2(pot.end.x, pot.position.y),
				Vector2(pot.end.x - s * 0.12, pot.end.y),
				Vector2(pot.position.x + s * 0.12, pot.end.y),
			]), col)
			for a in [-0.9, -0.2, 0.5]:
				var tip: Vector2 = c + Vector2(sin(a) * s * 0.7, -s * 0.5 - cos(a) * s * 0.35)
				draw_line(c + Vector2(0.0, -s * 0.1), tip, hi, 2.0)
				draw_circle(tip, s * 0.28, col.lightened(0.15))
		"clock":
			draw_circle(c, s * 0.85, col)
			draw_arc(c, s * 0.85, 0.0, TAU, 32, hi, 3.0, true)
			draw_line(c, c + Vector2(s * 0.4, -s * 0.2), hi, 3.0)
			draw_line(c, c + Vector2(0.0, -s * 0.6), lo, 3.0)
		"box":
			var body3 := Rect2(c - Vector2(s * 0.75, s * 0.6), Vector2(s * 1.5, s * 1.2))
			draw_rect(body3, col, true)
			draw_rect(body3, hi, false, 2.0)
			draw_line(Vector2(body3.position.x, c.y), Vector2(body3.end.x, c.y), lo, 2.0)
			draw_line(Vector2(c.x, body3.position.y), Vector2(c.x, body3.end.y), lo, 2.0)
		"folder":
			var body4 := Rect2(c - Vector2(s * 0.7, s * 0.42), Vector2(s * 1.4, s * 0.98))
			draw_rect(body4, col, true)
			draw_rect(Rect2(body4.position + Vector2(0.0, -s * 0.24), Vector2(s * 0.6, s * 0.24)), col.darkened(0.08), true)
			draw_rect(body4, hi, false, 2.0)
		"lamp":
			draw_rect(Rect2(c - Vector2(s * 0.4, -s * 0.05), Vector2(s * 0.8, s * 0.12)), col, true)
			draw_line(c, c + Vector2(0.0, -s * 0.9), col, 3.0)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-s * 0.5, -s * 0.9),
				c + Vector2(s * 0.5, -s * 0.9),
				c + Vector2(s * 0.25, -s * 0.5),
				c + Vector2(-s * 0.25, -s * 0.5),
			]), hi)
		_:
			var body5 := Rect2(c - Vector2(s * 0.65, s * 0.6), Vector2(s * 1.3, s * 1.2))
			draw_rect(body5, col, true)
			draw_rect(body5, hi, false, 2.0)


func _draw_footer() -> void:
	var h: float = size.y
	_txt("Arrows move · Enter inspect · Esc give up", Vector2(24.0, h - 24.0), 14, INK)
	var r: Rect2 = _foot_rect()
	_rr(r, 6.0, CREAM.lightened(0.06) if _foot_hover else CREAM)
	_rr_outline(r, 6.0, PINK_DEEP, 2.0)
	_txt("Give Up", r.position + Vector2(0.0, r.size.y * 0.68), 16, INK, false, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func _draw_banner() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(WINE, 0.55), true)
	var bw: float = 420.0
	var bh: float = 128.0
	var box := Rect2((size.x - bw) * 0.5, (size.y - bh) * 0.5, bw, bh)
	_rr(box, 16.0, CREAM)
	_rr_outline(box, 16.0, PINK_DEEP, 3.0)
	var title: String = "EVIDENCE SECURED" if _win else "CASE LOST"
	_txt(title, box.position + Vector2(0.0, 56.0), 32, WINE, true, HORIZONTAL_ALIGNMENT_CENTER, bw)
	_txt("Clues found: %d / %d" % [_found, _clue_total], box.position + Vector2(0.0, 92.0), 18, INK, false, HORIZONTAL_ALIGNMENT_CENTER, bw)
