extends MinigameBase
## Surveillance Dodge — the lobby-showcase reveal beat.
##
## A turn-based lobby crawl. You start bottom-left and must reach the marked
## exit top-right without stepping into a guard's sweeping vision cone. Every
## move advances the guards; the cone you can see right now is exactly the one
## that catches you, so the puzzle is planning a route through the sweep. Get
## caught too many times, or run out of turns, and the showcase is ruined.

const GAME_ID := "surveillance_dodge"

const CREAM := Color("#FDE8D0")
const HOT := Color("#E8447E")
const BLUSH := Color("#F4A0B8")
const WINE := Color("#7A2F52")
const LAVENDER := Color("#A99FE0")
const SKY := Color("#A8D8F0")
const INK := Color("#57465F")
const MUTED := Color("#7C6B86")

const GX := 11
const GY := 7

const START := Vector2i(0, GY - 1)
const GOAL := Vector2i(GX - 1, 0)


class Guard:
	var pos: Vector2i
	var angle: float
	var spin: float

	func _init(p: Vector2i, a: float, s: float) -> void:
		pos = p
		angle = a
		spin = s


var _canvas: Control
var _status: Label
var _strike_label: Label
var _turn_label: Label

var _player: Vector2i = START
var _guards: Array[Guard] = []
var _walls: Dictionary = {}

var _range: int = 2
var _half_angle: float = deg_to_rad(35.0)
var _speed: float = deg_to_rad(40.0)
var _max_strikes: int = 2
var _strikes: int = 0
var _moves: int = 0
var _turn: int = 0
var _turn_limit: int = 60

var _ending: bool = false
var _hover_cell: Vector2i = Vector2i(-1, -1)
var _has_hover: bool = false
var _flash: float = 0.0
var _caught_cell: Vector2i = Vector2i(-1, -1)


static func meta() -> Dictionary:
	return {
		"id": GAME_ID,
		"title": "Lobby Surveillance",
		"blurb": "Slip across the lobby to the exit without crossing a sweeping camera cone.",
		"instructions": "You are the heart token at the bottom-left; reach the EXIT at the top-right. Move one square with the arrow keys (or click an adjacent square). Every move rotates the guards, and a square inside a visible cone will get you caught. Too many catches or too many turns ends the run. Esc forfeits.",
	}


func _build() -> void:
	var d: float = _difficulty()
	_range = int(round(lerpf(2.0, 3.0, d)))
	_half_angle = deg_to_rad(lerpf(30.0, 46.0, d))
	_speed = deg_to_rad(lerpf(28.0, 72.0, d))
	_max_strikes = int(round(lerpf(3.0, 1.0, d)))
	_turn_limit = int(round(float(GX - 1 + GY - 1) * lerpf(4.5, 3.0, d))) + 18

	_layout()

	var panel := Panel.new()
	panel.name = "Board"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIUtil.panel_style(CREAM, 10, WINE, 3, true))
	add_child(panel)

	var m := UIUtil.margin(18, 14, 18, 14)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	m.add_child(vb)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var title := _text(_title_text(), 22, WINE, false, UIUtil.font_bold(true))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_turn_label = _text("", 16, WINE, false, UIUtil.font_bold(false))
	_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(_turn_label)
	vb.add_child(head)

	vb.add_child(_text(_prompt_text(), 15, INK, true))

	_canvas = Control.new()
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.custom_minimum_size = Vector2(0, 250)
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.draw.connect(_draw_canvas.bind(_canvas))
	_canvas.gui_input.connect(_canvas_input)
	_canvas.mouse_exited.connect(_on_mouse_exit)
	vb.add_child(_canvas)

	var frow := HBoxContainer.new()
	frow.add_theme_constant_override("separation", 10)
	_strike_label = _text("", 16, HOT, false, UIUtil.font_bold(false))
	_strike_label.custom_minimum_size = Vector2(200, 0)
	frow.add_child(_strike_label)
	_status = _text("Reach the EXIT. Watch the cones.", 16, INK, false)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frow.add_child(_status)
	vb.add_child(frow)

	vb.add_child(_text("Arrows / WASD move · click an adjacent square · Esc forfeits", 12, MUTED, false))

	_update_hud()
	set_process(true)


# =====================================================================
# layout / generation
# =====================================================================

func _layout() -> void:
	var span := GX - 1 + GY - 1
	_turn_limit = int(round(float(span) * lerpf(4.5, 3.0, _difficulty()))) + 18

	# furniture: a few blocks, never adjacent to start/goal
	var wall_count := 4 + int(round(_difficulty() * 4.0))
	var candidates: Array[Vector2i] = []
	for y in range(GY):
		for x in range(GX):
			var cell := Vector2i(x, y)
			if _near(cell, START, 2) or _near(cell, GOAL, 2):
				continue
			candidates.append(cell)
	while _walls.size() < wall_count and not candidates.is_empty():
		var idx := rng.randi_range(0, candidates.size() - 1)
		var c := candidates[idx]
		candidates.remove_at(idx)
		_walls[c] = true
		if not _connected():
			_walls.erase(c)

	# guards: spread across the middle of the board
	var spots: Array[Vector2i] = []
	for y in range(GY):
		for x in range(GX):
			var cell := Vector2i(x, y)
			if _walls.has(cell):
				continue
			if _near(cell, START, 3) or _near(cell, GOAL, 3):
				continue
			spots.append(cell)
	var guard_count := 2 + int(round(_difficulty() * 3.0))
	for i in range(guard_count):
		if spots.is_empty():
			break
		var idx2 := rng.randi_range(0, spots.size() - 1)
		var gpos := spots[idx2]
		spots.remove_at(idx2)
		var ang := rng.randf_range(0.0, TAU)
		var spin := 1.0 if rng.randf() < 0.5 else -1.0
		_guards.append(Guard.new(gpos, ang, spin))


func _near(a: Vector2i, b: Vector2i, r: int) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) <= r


func _connected() -> bool:
	var seen: Dictionary = {START: true}
	var queue: Array[Vector2i] = [START]
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == GOAL:
			return true
		for dir in dirs:
			var nxt: Vector2i = cur + dir
			if not _in_bounds(nxt) or _walls.has(nxt) or seen.has(nxt):
				continue
			seen[nxt] = true
			queue.append(nxt)
	return seen.has(GOAL)


func _in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < GX and c.y < GY


# =====================================================================
# rules
# =====================================================================

func _try_move(dx: int, dy: int) -> void:
	if _ending:
		return
	var nxt := _player + Vector2i(dx, dy)
	if not _in_bounds(nxt) or _walls.has(nxt):
		Audio.play_sfx("click")
		_status.text = "Blocked."
		return
	_moves += 1
	_player = nxt
	Audio.play_sfx("blip")

	if _player == GOAL:
		_status.text = "You made the exit clean. Showcase saved!"
		Audio.play_sfx("chime")
		_redraw()
		_schedule(true, {"moves": _moves})
		return

	var caught := _threatened(_player)
	if caught:
		_strikes += 1
		_flash = 1.0
		_caught_cell = _player
		Audio.play_sfx("whoosh")
		if _strikes > _max_strikes:
			_status.text = "Caught again — the guards escort you out."
			_redraw()
			_schedule(false, {"moves": _moves, "strikes": _strikes})
			return
		_status.text = "Caught! Back to the entrance."
		_player = START
	else:
		_status.text = "Clear."

	for g in _guards:
		g.angle = wrapf(g.angle + g.spin * _speed, -PI, PI)

	_turn += 1
	if _turn >= _turn_limit:
		_status.text = "Too slow — the showcase starts without you."
		_redraw()
		_schedule(false, {"moves": _moves, "turns": _turn})
		return
	_update_hud()
	_redraw()


func _threatened(cell: Vector2i) -> bool:
	for g in _guards:
		var v := Vector2(cell - g.pos)
		var dist := v.length()
		if dist < 0.5:
			return true
		if dist > float(_range) + 0.25:
			continue
		var diff := absf(wrapf(v.angle() - g.angle, -PI, PI))
		if diff <= _half_angle:
			return true
	return false


func _redraw() -> void:
	if _canvas != null:
		_canvas.queue_redraw()


func _update_hud() -> void:
	_turn_label.text = "Turn %d/%d" % [_turn, _turn_limit]
	var pips := ""
	for i in range(_max_strikes + 1):
		pips += "[x]" if i < _strikes else "[ ]"
	_strike_label.text = "Caught %s" % pips


func _schedule(success: bool, result: Dictionary) -> void:
	if _ending:
		return
	_ending = true
	_redraw()
	var tmr := get_tree().create_timer(0.95)
	tmr.timeout.connect(func(): _finish(success, result))


# =====================================================================
# input
# =====================================================================

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if _ending:
		return
	if event.is_action_pressed("ui_left"):
		_try_move(-1, 0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_try_move(1, 0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_try_move(0, -1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_try_move(0, 1)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			match k.keycode:
				KEY_A: _try_move(-1, 0); get_viewport().set_input_as_handled()
				KEY_D: _try_move(1, 0); get_viewport().set_input_as_handled()
				KEY_W: _try_move(0, -1); get_viewport().set_input_as_handled()
				KEY_S: _try_move(0, 1); get_viewport().set_input_as_handled()
				_: pass


func _canvas_input(event: InputEvent) -> void:
	if _ending:
		return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		_hover_cell = _cell_at(mm.position)
		_has_hover = true
		_redraw()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var cell := _cell_at(mb.position)
			var diff := cell - _player
			if absi(diff.x) + absi(diff.y) == 1:
				_try_move(diff.x, diff.y)
			else:
				Audio.play_sfx("click")
			_canvas.accept_event()


func _on_mouse_exit() -> void:
	_has_hover = false
	_redraw()


# =====================================================================
# geometry + drawing
# =====================================================================

func _cell_px(csz: Vector2) -> float:
	return minf(csz.x / float(GX), csz.y / float(GY))


func _origin(csz: Vector2) -> Vector2:
	var cell := _cell_px(csz)
	return Vector2((csz.x - cell * float(GX)) * 0.5, (csz.y - cell * float(GY)) * 0.5)


func _cell_center(cell: Vector2i, csz: Vector2) -> Vector2:
	var cp := _cell_px(csz)
	return _origin(csz) + (Vector2(float(cell.x), float(cell.y)) + Vector2(0.5, 0.5)) * cp


func _cell_at(pt: Vector2) -> Vector2i:
	var csz := _canvas.size
	var cp := _cell_px(csz)
	if cp <= 0.0:
		return Vector2i(-1, -1)
	var rel := (pt - _origin(csz)) / cp
	var cx := int(floor(rel.x))
	var cy := int(floor(rel.y))
	if cx < 0 or cy < 0 or cx >= GX or cy >= GY:
		return Vector2i(-1, -1)
	return Vector2i(cx, cy)


func _draw_canvas(c: Control) -> void:
	var csz := c.size
	var cp := _cell_px(csz)
	if cp <= 0.0:
		return
	c.draw_rect(Rect2(Vector2.ZERO, csz), Color(WINE, 0.14), true)
	var origin := _origin(csz)

	for y in range(GY):
		for x in range(GX):
			var cell := Vector2i(x, y)
			var r := Rect2(origin + Vector2(float(x), float(y)) * cp, Vector2(cp, cp))
			var col := Color("#F7DFC6") if (x + y) % 2 == 0 else Color("#EFD2B4")
			if _walls.has(cell):
				col = Color("#9C7E92")
			c.draw_rect(r, col, true)
			c.draw_rect(r, Color(WINE, 0.12), false, 1.0)

	# cones
	for g in _guards:
		_draw_cone(c, g, csz, cp)

	# goal
	var gr := Rect2(origin + Vector2(float(GOAL.x), float(GOAL.y)) * cp, Vector2(cp, cp)).grow(-3.0)
	c.draw_rect(gr, Color(SKY, 0.85), true)
	c.draw_rect(gr, WINE, false, 2.0)
	_draw_fit_text(c, "EXIT", gr, 13, WINE)

	# start marker
	var sr := Rect2(origin + Vector2(float(START.x), float(START.y)) * cp, Vector2(cp, cp)).grow(-6.0)
	c.draw_rect(sr, Color(BLUSH, 0.5), false, 2.0)

	# hover highlight on reachable neighbour
	if _has_hover and not _ending:
		var diff := _hover_cell - _player
		if absi(diff.x) + absi(diff.y) == 1 and _in_bounds(_hover_cell) and not _walls.has(_hover_cell):
			var hr := Rect2(origin + Vector2(float(_hover_cell.x), float(_hover_cell.y)) * cp, Vector2(cp, cp))
			c.draw_rect(hr, Color(HOT, 0.25), false, 3.0)

	# guards on top
	for g in _guards:
		_draw_guard(c, g, csz, cp)

	# player
	var pc := _cell_center(_player, csz)
	var pcol := _accent() if _flash <= 0.0 else Color(HOT)
	c.draw_circle(pc, cp * 0.34, WINE)
	c.draw_circle(pc, cp * 0.28, pcol)
	UIUtil._heart(c, pc, cp * 0.2, Color.WHITE)
	if _flash > 0.0:
		c.draw_arc(pc, cp * 0.5, 0.0, TAU, 24, HOT, 3.0, true)

	if _flash > 0.0 and _caught_cell.x >= 0:
		var cc := _cell_center(_caught_cell, csz)
		var a := clampf(_flash, 0.0, 1.0)
		var d := cp * 0.24
		c.draw_line(cc - Vector2(d, d), cc + Vector2(d, d), Color(HOT, a), 3.0, true)
		c.draw_line(cc + Vector2(-d, d), cc + Vector2(d, -d), Color(HOT, a), 3.0, true)


func _draw_cone(c: Control, g: Guard, csz: Vector2, cp: float) -> void:
	var centre := _cell_center(g.pos, csz)
	var radius := (float(_range) + 0.35) * cp
	var pts := PackedVector2Array()
	pts.append(centre)
	var steps := 18
	for i in range(steps + 1):
		var a := g.angle - _half_angle + (2.0 * _half_angle) * float(i) / float(steps)
		pts.append(centre + Vector2(cos(a), sin(a)) * radius)
	c.draw_colored_polygon(pts, Color(HOT, 0.20))
	var outline := pts.duplicate()
	outline.append(pts[0])
	c.draw_polyline(outline, Color(HOT, 0.55), 1.5, true)


func _draw_guard(c: Control, g: Guard, csz: Vector2, cp: float) -> void:
	var centre := _cell_center(g.pos, csz)
	c.draw_circle(centre, cp * 0.30, WINE)
	c.draw_circle(centre, cp * 0.23, LAVENDER)
	var tip := centre + Vector2(cos(g.angle), sin(g.angle)) * cp * 0.42
	c.draw_line(centre, tip, WINE, 3.0, true)
	# spin indicator
	var perp := Vector2(-sin(g.angle), cos(g.angle)) * cp * 0.12 * g.spin
	var mid := centre + Vector2(cos(g.angle), sin(g.angle)) * cp * 0.30
	c.draw_line(mid - perp, mid + perp, WINE, 2.0, true)


func _draw_fit_text(c: Control, txt: String, rect: Rect2, size: int, col: Color) -> void:
	var f := UIUtil.font_bold(false)
	var ts := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	c.draw_string(f, rect.position + Vector2((rect.size.x - ts.x) * 0.5, rect.size.y * 0.5 + ts.y * 0.35), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


# =====================================================================
# misc
# =====================================================================

func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta / 0.45
		if _flash <= 0.0:
			_caught_cell = Vector2i(-1, -1)
		_redraw()


func _text(txt: String, size: int, col: Color, wrap: bool = false, font: Font = null) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if font != null:
		l.add_theme_font_override("font", font)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		l.clip_text = true
	return l


func _title_text() -> String:
	var t := str(cfg.get("title", ""))
	return t if t != "" else "Lobby Surveillance"


func _prompt_text() -> String:
	var p := str(cfg.get("prompt", ""))
	return p if p != "" else "Reach the exit without stepping into a camera cone."
