extends MinigameBase
## Dante's iced-latte beat: stop the sweeping marker inside the pink zone.
## Three rounds; centre hits are perfect, misses cost strikes.

const GAME_ID := "latte_timing"

const CREAM := Color("#FDE8D0")
const PINK := Color("#F4A0B8")
const PINK_DEEP := Color("#E8447E")
const WINE := Color("#7A2F52")
const INK := Color("#57465F")
const BAD := Color("#D1435F")

const ROUNDS := 3
const MAX_STRIKES := 3

var _phase: String = "aim"     # aim | result | over
var _round: int = 0            # 0-based
var _strikes: int = 0
var _perfect: int = 0
var _score: int = 0
var _mx: float = 0.5
var _dir: float = 1.0
var _speed: float = 1.0
var _sweet_hw: float = 0.14
var _perfect_hw: float = 0.045
var _res_timer: float = 0.0
var _last_label: String = ""
var _last_good: bool = false
var _over: bool = false
var _win: bool = false


static func meta() -> Dictionary:
	return {
		"id": GAME_ID,
		"title": "Latte Timing",
		"blurb": "Hit the sweet spot to pour Dante's iced latte.",
		"instructions": "A marker sweeps along the bar. Press Space / Enter (or click) to stop it inside the pink sweet spot. The centre is a perfect pour. Miss three times and the order is ruined. The zone narrows and the sweep speeds up each round. Esc gives up.",
	}


func _build() -> void:
	set_process(true)
	resized.connect(queue_redraw)
	var board := Control.new()
	board.name = "Board"
	board.set_anchors_preset(Control.PRESET_FULL_RECT)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board)
	_start_round()
	queue_redraw()


func _start_round() -> void:
	_phase = "aim"
	_mx = 0.5 + rng.randf_range(-0.32, 0.32)
	_dir = 1.0 if rng.randf() < 0.5 else -1.0
	var d: float = _difficulty()
	_speed = lerpf(0.62, 1.25, d) * (1.0 + 0.14 * float(_round))
	_sweet_hw = maxf(0.05, lerpf(0.17, 0.09, d) - 0.018 * float(_round))
	_perfect_hw = _sweet_hw * 0.32


func _process(delta: float) -> void:
	if _phase == "aim":
		_mx += _dir * _speed * delta
		if _mx >= 1.0:
			_mx = 1.0
			_dir = -1.0
		elif _mx <= 0.0:
			_mx = 0.0
			_dir = 1.0
	elif _phase == "result":
		_res_timer -= delta
		if _res_timer <= 0.0:
			_advance_round()
	queue_redraw()


func _stop() -> void:
	if _phase != "aim" or _over:
		return
	_phase = "result"
	_res_timer = 0.8
	var dx: float = absf(_mx - 0.5)
	if dx <= _perfect_hw:
		_score += 2
		_perfect += 1
		_last_label = "PERFECT!"
		_last_good = true
		Audio.play_sfx("chime")
	elif dx <= _sweet_hw:
		_score += 1
		_last_label = "NICE"
		_last_good = true
		Audio.play_sfx("choice")
	else:
		_strikes += 1
		_last_label = "MISS"
		_last_good = false
		Audio.play_sfx("whoosh")
	queue_redraw()


func _advance_round() -> void:
	if _strikes >= MAX_STRIKES:
		_end(false, {"rounds": _round, "perfect": _perfect, "strikes": _strikes})
		return
	_round += 1
	if _round >= ROUNDS:
		_end(true, {"rounds": ROUNDS, "perfect": _perfect, "strikes": _strikes, "score": _score})
	else:
		_start_round()


func _end(success: bool, result: Dictionary) -> void:
	if _over:
		return
	_over = true
	_win = success
	_phase = "over"
	Audio.play_sfx("chime" if success else "whoosh")
	queue_redraw()
	if is_inside_tree():
		await get_tree().create_timer(0.9).timeout
	_finish(success, result)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		super._unhandled_input(event)
		return
	if _over:
		return
	if event.is_action_pressed("ui_accept"):
		_stop()
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if _over:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_stop()


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
	var w: float = size.x
	var h: float = size.y
	draw_rect(Rect2(Vector2.ZERO, size), CREAM, true)

	_txt("LATTE TIMING", Vector2(24.0, 38.0), 26, WINE, true)
	_txt("Stop the sweep inside the pink zone. Centre = perfect.", Vector2(24.0, 62.0), 15, INK)
	_txt("ROUND %d / %d" % [mini(_round + 1, ROUNDS), ROUNDS], Vector2(w - 240.0, 30.0), 16, PINK_DEEP)
	_txt("STRIKES %d / %d" % [_strikes, MAX_STRIKES], Vector2(w - 120.0, 30.0), 16, INK)

	var track := Rect2(w * 0.09, h * 0.47, w * 0.82, 48.0)
	_rr(track, 12.0, Color(WINE, 0.18))
	_rr_outline(track, 12.0, Color(WINE, 0.45), 2.0)
	var cx: float = track.position.x + track.size.x * 0.5
	var sw: float = _sweet_hw * track.size.x
	var pw: float = _perfect_hw * track.size.x
	_rr(Rect2(cx - sw, track.position.y + 4.0, sw * 2.0, track.size.y - 8.0), 8.0, Color(PINK, 0.88))
	_rr(Rect2(cx - pw, track.position.y + 4.0, pw * 2.0, track.size.y - 8.0), 6.0, PINK_DEEP)

	var mx: float = track.position.x + _mx * track.size.x
	draw_line(Vector2(mx, track.position.y - 18.0), Vector2(mx, track.end.y + 18.0), WINE, 3.0)
	draw_circle(Vector2(mx, track.position.y - 26.0), 10.0, WINE)
	draw_circle(Vector2(mx, track.position.y - 26.0), 5.0, CREAM)

	# steam cup glyph centred under the track
	var cup_c := Vector2(cx, track.end.y + 46.0)
	draw_rect(Rect2(cup_c - Vector2(16.0, 14.0), Vector2(32.0, 28.0)), WINE.lightened(0.1), true)
	draw_arc(cup_c + Vector2(16.0, 0.0), 10.0, -PI * 0.5, PI * 0.5, 14, WINE.lightened(0.1), 3.0, true)

	if _phase == "result" or _phase == "over":
		var fc: Color = PINK_DEEP if _last_good else BAD
		_txt(_last_label, Vector2(0.0, track.position.y - 52.0), 30, fc, true, HORIZONTAL_ALIGNMENT_CENTER, w)

	_txt("SPACE / ENTER / click to stop · Esc give up", Vector2(0.0, h - 20.0), 15, INK, false, HORIZONTAL_ALIGNMENT_CENTER, w)

	if _over:
		_draw_banner()


func _draw_banner() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(WINE, 0.55), true)
	var bw: float = 420.0
	var bh: float = 132.0
	var box := Rect2((size.x - bw) * 0.5, (size.y - bh) * 0.5, bw, bh)
	_rr(box, 16.0, CREAM)
	_rr_outline(box, 16.0, PINK_DEEP, 3.0)
	var title: String = "ORDER PERFECT" if _win else "ORDER RUINED"
	_txt(title, box.position + Vector2(0.0, 56.0), 32, WINE, true, HORIZONTAL_ALIGNMENT_CENTER, bw)
	var sub: String = "Perfect pours: %d · Score: %d" % [_perfect, _score]
	_txt(sub, box.position + Vector2(0.0, 94.0), 18, INK, false, HORIZONTAL_ALIGNMENT_CENTER, bw)
