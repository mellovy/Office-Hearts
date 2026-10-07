extends MinigameBase
## Watermark Forensics — Leo's colour-channel investigation beat.
##
## A doctored "surveillance still" is generated in code: smooth per-pixel noise
## with one subtly shifted colour patch hidden somewhere on the frame. The player
## sweeps a magnifier (arrow keys / mouse), can flip to a single colour channel to
## make the tamper stand out, and clicks the patch within a click budget + timer.
## Warm / cold feedback keeps it fair instead of a blind guess.

const GAME_ID := "watermark_forensics"

const CREAM := Color("#FDE8D0")
const HOT := Color("#E8447E")
const BLUSH := Color("#F4A0B8")
const WINE := Color("#7A2F52")
const SKY := Color("#A8D8F0")
const INK := Color("#57465F")
const MUTED := Color("#7C6B86")

const IMG_W := 160
const IMG_H := 112
const ZOOM := 3.2
const CHAN_NAMES := ["Composite", "Red", "Green", "Blue"]

var _canvas: Control
var _meter: Control
var _feedback: Label
var _clicks_label: Label
var _time_label: Label
var _channel_label: Label
var _channel_btns: Array[Button] = []

var _base_img: Image
var _tex: ImageTexture
var _channel: int = 0
var _tamper: Rect2i = Rect2i()
var _tamper_center: Vector2 = Vector2.ZERO
var _tamper_channel: int = 0
var _tamper_factor: float = 0.2

var _max_clicks: int = 8
var _clicks: int = 0
var _time_limit: float = 40.0
var _time_left: float = 40.0

var _ending: bool = false
var _found: bool = false

var _cursor: Vector2 = Vector2.ZERO
var _hover: Vector2 = Vector2.ZERO
var _has_hover: bool = false
var _last_click: Vector2 = Vector2.ZERO
var _have_last_click: bool = false
var _last_dist: float = INF
var _proximity: float = 0.0


static func meta() -> Dictionary:
	return {
		"id": GAME_ID,
		"title": "Watermark Forensics",
		"blurb": "Someone doctored the security still. Find the tampered patch before the trail goes cold.",
		"instructions": "Move the magnifier over the frame with the arrow keys (or the mouse) and press Enter / Space (or click) to inspect a spot. A warm/cold readout tells you if you are getting closer. Switch colour channels to expose the alteration. You have limited inspections and a timer. Esc forfeits.",
	}


func _build() -> void:
	var d: float = _difficulty()
	_max_clicks = int(round(lerpf(10.0, 5.0, d)))
	_time_limit = lerpf(48.0, 22.0, d)
	_time_left = _time_limit

	_generate()

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

	# --- header -------------------------------------------------------
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var title := _text(_title_text(), 22, WINE, false, UIUtil.font_bold(true))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_time_label = _text("", 18, WINE, false, UIUtil.font_bold(false))
	_time_label.custom_minimum_size = Vector2(150, 0)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(_time_label)
	vb.add_child(head)

	vb.add_child(_text(_prompt_text(), 15, INK, true))

	# --- channel row --------------------------------------------------
	var crow := HBoxContainer.new()
	crow.add_theme_constant_override("separation", 6)
	_channel_label = _text("Channel:", 15, MUTED, false)
	crow.add_child(_channel_label)
	for i in range(CHAN_NAMES.size()):
		var b := UIUtil.pill_button(CHAN_NAMES[i], 116, 44)
		b.add_theme_font_size_override("font_size", 15)
		b.pressed.connect(_set_channel.bind(i))
		crow.add_child(b)
		_channel_btns.append(b)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crow.add_child(sp)
	_clicks_label = _text("", 15, MUTED, false)
	crow.add_child(_clicks_label)
	vb.add_child(crow)

	# --- frame --------------------------------------------------------
	_canvas = Control.new()
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_canvas.custom_minimum_size = Vector2(0, 250)
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.draw.connect(_draw_canvas.bind(_canvas))
	_canvas.gui_input.connect(_canvas_input)
	_canvas.mouse_exited.connect(_on_mouse_exit)
	vb.add_child(_canvas)

	# --- footer -------------------------------------------------------
	var frow := HBoxContainer.new()
	frow.add_theme_constant_override("separation", 10)
	_meter = Control.new()
	_meter.custom_minimum_size = Vector2(220, 14)
	_meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_meter.draw.connect(_draw_meter.bind(_meter))
	frow.add_child(_meter)
	_feedback = _text("Scanning…", 16, INK, false, UIUtil.font_bold(false))
	_feedback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frow.add_child(_feedback)
	vb.add_child(frow)

	vb.add_child(_text("Arrows move the reticle · Enter/Space inspects · 1-2-3-4 switch channel · mouse works too · Esc forfeits", 12, MUTED, false))

	_update_channel_ui()
	_update_hud()
	set_process(true)


# =====================================================================
# generation
# =====================================================================

func _generate() -> void:
	_base_img = Image.create_empty(IMG_W, IMG_H, false, Image.FORMAT_RGBA8)
	var gx := 10
	var gy := 7
	var nr := _noise_field(gx, gy)
	var ng := _noise_field(gx, gy)
	var nb := _noise_field(gx, gy)
	for y in range(IMG_H):
		for x in range(IMG_W):
			var u := float(x) / float(IMG_W)
			var v := float(y) / float(IMG_H)
			var band := 0.02 * sin(v * 70.0)
			var r := 0.56 + 0.15 * _sample(nr, gx, gy, u, v) + band
			var g := 0.53 + 0.15 * _sample(ng, gx, gy, u, v) + band
			var b := 0.60 + 0.15 * _sample(nb, gx, gy, u, v) + band
			_base_img.set_pixel(x, y, Color(clampf(r, 0.0, 1.0), clampf(g, 0.0, 1.0), clampf(b, 0.0, 1.0), 1.0))

	# hide a subtly shifted patch
	var d: float = _difficulty()
	var tw := int(round(lerpf(float(IMG_W) * 0.24, float(IMG_W) * 0.12, d)))
	var th := int(round(lerpf(float(IMG_H) * 0.26, float(IMG_H) * 0.13, d)))
	var margin := 7
	var tx := margin + rng.randi_range(0, maxi(1, IMG_W - tw - margin * 2))
	var ty := margin + rng.randi_range(0, maxi(1, IMG_H - th - margin * 2))
	_tamper = Rect2i(tx, ty, tw, th)
	_tamper_center = Vector2(float(tx) + float(tw) * 0.5, float(ty) + float(th) * 0.5)
	_tamper_channel = rng.randi_range(0, 2)
	_tamper_factor = lerpf(0.34, 0.15, d)
	var dir := 1.0 if rng.randf() < 0.5 else -1.0
	var shift := _tamper_factor * dir
	for y in range(ty, ty + th):
		for x in range(tx, tx + tw):
			var c := _base_img.get_pixel(x, y)
			match _tamper_channel:
				0: c.r = clampf(c.r + shift, 0.0, 1.0)
				1: c.g = clampf(c.g + shift, 0.0, 1.0)
				_: c.b = clampf(c.b + shift, 0.0, 1.0)
			_base_img.set_pixel(x, y, c)

	_cursor = _tamper_center.round()
	_apply_channel()


func _noise_field(cx: int, cy: int) -> PackedFloat32Array:
	var f := PackedFloat32Array()
	f.resize(cx * cy)
	for i in range(cx * cy):
		f[i] = rng.randf_range(-1.0, 1.0)
	return f


func _sample(field: PackedFloat32Array, cx: int, cy: int, u: float, v: float) -> float:
	var fx := clampf(u, 0.0, 1.0) * float(cx - 1)
	var fy := clampf(v, 0.0, 1.0) * float(cy - 1)
	var x0 := int(floor(fx))
	var y0 := int(floor(fy))
	var x1 := mini(x0 + 1, cx - 1)
	var y1 := mini(y0 + 1, cy - 1)
	var tx := fx - float(x0)
	var ty := fy - float(y0)
	var a := field[y0 * cx + x0]
	var b := field[y0 * cx + x1]
	var c := field[y1 * cx + x0]
	var dd := field[y1 * cx + x1]
	var top := a + (b - a) * tx
	var bot := c + (dd - c) * tx
	return top + (bot - top) * ty


func _apply_channel() -> void:
	var out := Image.create_empty(IMG_W, IMG_H, false, Image.FORMAT_RGBA8)
	for y in range(IMG_H):
		for x in range(IMG_W):
			var c := _base_img.get_pixel(x, y)
			match _channel:
				1: out.set_pixel(x, y, Color(c.r, c.r, c.r, 1.0))
				2: out.set_pixel(x, y, Color(c.g, c.g, c.g, 1.0))
				3: out.set_pixel(x, y, Color(c.b, c.b, c.b, 1.0))
				_: out.set_pixel(x, y, c)
	_tex = ImageTexture.create_from_image(out)
	if _canvas != null:
		_canvas.queue_redraw()


# =====================================================================
# geometry helpers
# =====================================================================

func _image_rect(sz: Vector2) -> Rect2:
	var pad := 6.0
	var avail := Vector2(maxf(sz.x - pad * 2.0, 1.0), maxf(sz.y - pad * 2.0, 1.0))
	var sc := minf(avail.x / float(IMG_W), avail.y / float(IMG_H))
	var w := float(IMG_W) * sc
	var h := float(IMG_H) * sc
	return Rect2(Vector2((sz.x - w) * 0.5, (sz.y - h) * 0.5), Vector2(w, h))


func _pix_scale(rect: Rect2) -> float:
	return rect.size.x / float(IMG_W)


func _to_canvas(img: Vector2, rect: Rect2) -> Vector2:
	return rect.position + img * _pix_scale(rect)


func _canvas_to_img(p: Vector2) -> Vector2:
	var rect := _image_rect(_canvas.size)
	if rect.size.x <= 0.0:
		return Vector2.ZERO
	var u := (p.x - rect.position.x) / rect.size.x
	var v := (p.y - rect.position.y) / rect.size.y
	return Vector2(clampf(u, 0.0, 1.0) * float(IMG_W), clampf(v, 0.0, 1.0) * float(IMG_H))


func _img_rect_to_canvas(ir: Rect2i, rect: Rect2) -> Rect2:
	var s := _pix_scale(rect)
	return Rect2(
		rect.position + Vector2(float(ir.position.x), float(ir.position.y)) * s,
		Vector2(float(ir.size.x), float(ir.size.y)) * s)


func _diag() -> float:
	return sqrt(float(IMG_W * IMG_W + IMG_H * IMG_H))


# =====================================================================
# input
# =====================================================================

func _canvas_input(event: InputEvent) -> void:
	if _ending or _found:
		return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		_has_hover = true
		_hover = _canvas_to_img(mm.position)
		_cursor = _hover
		_canvas.queue_redraw()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_has_hover = true
			_inspect(_canvas_to_img(mb.position))
			_canvas.accept_event()


func _on_mouse_exit() -> void:
	_has_hover = false
	_canvas.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if _ending or _found:
		return
	var step := 6.0
	if event.is_action_pressed("ui_left"):
		_cursor.x = maxf(_cursor.x - step, 0.0)
		_after_key()
	elif event.is_action_pressed("ui_right"):
		_cursor.x = minf(_cursor.x + step, float(IMG_W - 1))
		_after_key()
	elif event.is_action_pressed("ui_up"):
		_cursor.y = maxf(_cursor.y - step, 0.0)
		_after_key()
	elif event.is_action_pressed("ui_down"):
		_cursor.y = minf(_cursor.y + step, float(IMG_H - 1))
		_after_key()
	elif event.is_action_pressed("ui_accept"):
		_inspect(_cursor)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			match k.keycode:
				KEY_1, KEY_R:
					_set_channel(1)
					get_viewport().set_input_as_handled()
				KEY_2, KEY_G:
					_set_channel(2)
					get_viewport().set_input_as_handled()
				KEY_3, KEY_B:
					_set_channel(3)
					get_viewport().set_input_as_handled()
				KEY_4, KEY_C:
					_set_channel(0)
					get_viewport().set_input_as_handled()
				_:
					pass


func _after_key() -> void:
	_has_hover = true
	_hover = _cursor
	_canvas.queue_redraw()
	get_viewport().set_input_as_handled()


# =====================================================================
# play
# =====================================================================

func _inspect(p: Vector2) -> void:
	if _ending or _found:
		return
	_clicks += 1
	_last_click = p
	_have_last_click = true
	var ip := Vector2i(int(clampf(p.x, 0.0, float(IMG_W - 1))), int(clampf(p.y, 0.0, float(IMG_H - 1))))
	if _tamper.has_point(ip):
		_found = true
		Audio.play_sfx("chime")
		_set_feedback("The patch! You found it.", HOT)
		_canvas.queue_redraw()
		_schedule(true, {"clicks": _clicks})
		return

	var dist := p.distance_to(_tamper_center)
	var msg := "Scanning…"
	var col := INK
	if _clicks > 1:
		if dist < _last_dist:
			msg = "Warmer…"
			col = HOT
			Audio.play_sfx("blip")
		else:
			msg = "Colder."
			col = SKY
			Audio.play_sfx("click")
	else:
		Audio.play_sfx("click")
	_last_dist = dist
	_proximity = clampf(1.0 - dist / _diag(), 0.0, 1.0)
	_set_feedback(msg, col)
	_update_hud()
	_update_meter()
	_canvas.queue_redraw()

	if _clicks >= _max_clicks:
		_fail("Out of inspections — the forgery escapes you.")


func _set_channel(i: int) -> void:
	if _ending or _found or i == _channel:
		return
	_channel = i
	Audio.play_sfx("choice")
	_apply_channel()
	_update_channel_ui()


func _set_feedback(txt: String, col: Color) -> void:
	_feedback.text = txt
	_feedback.add_theme_color_override("font_color", col)


func _update_hud() -> void:
	_clicks_label.text = "Inspections %d/%d" % [_clicks, _max_clicks]
	var t := maxf(_time_left, 0.0)
	_time_label.text = "TIME %.1fs" % t
	_time_label.add_theme_color_override("font_color", HOT if t <= 8.0 else WINE)


func _update_channel_ui() -> void:
	for i in range(_channel_btns.size()):
		var b := _channel_btns[i]
		b.text = ("[ %s ]" % CHAN_NAMES[i]) if i == _channel else CHAN_NAMES[i]
	_channel_label.text = "Channel: %s" % CHAN_NAMES[_channel]


func _update_meter() -> void:
	if _meter != null:
		_meter.queue_redraw()


func _process(delta: float) -> void:
	if _ending:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_time_left = 0.0
		_update_hud()
		_fail("Time's up — the tamper goes unnoticed.")
		return
	_update_hud()


func _fail(reason: String) -> void:
	if _ending or _found:
		return
	_set_feedback(reason, WINE)
	Audio.play_sfx("whoosh")
	_schedule(false, {"clicks": _clicks, "reason": reason})


func _schedule(success: bool, result: Dictionary) -> void:
	if _ending:
		return
	_ending = true
	_canvas.queue_redraw()
	var tmr := get_tree().create_timer(0.95)
	tmr.timeout.connect(func(): _finish(success, result))


# =====================================================================
# drawing
# =====================================================================

func _draw_canvas(c: Control) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(WINE, 0.14), true)
	var rect := _image_rect(c.size)
	if rect.size.x <= 0.0:
		return
	if _tex != null:
		c.draw_texture_rect(_tex, rect, false)
	c.draw_rect(rect, Color(WINE, 0.55), false, 2.0)

	if _found:
		var tr := _img_rect_to_canvas(_tamper, rect)
		c.draw_rect(tr.grow(6.0), Color(HOT, 0.35), true)
		c.draw_rect(_img_rect_to_canvas(_tamper, rect), HOT, false, 3.0)
		_draw_center_text(c, "VERIFIED", HOT)

	if _have_last_click and not _found:
		var p := _to_canvas(_last_click, rect)
		c.draw_arc(p, 14.0, 0.0, TAU, 28, Color(HOT, 0.85), 2.0, true)

	if not _found and not _ending:
		_draw_loupe(c, rect)
		var rp := _to_canvas(_cursor, rect)
		c.draw_arc(rp, 12.0, 0.0, TAU, 28, INK, 2.0, true)
		c.draw_line(rp - Vector2(18, 0), rp - Vector2(6, 0), INK, 1.0)
		c.draw_line(rp + Vector2(6, 0), rp + Vector2(18, 0), INK, 1.0)
		c.draw_line(rp - Vector2(0, 18), rp - Vector2(0, 6), INK, 1.0)
		c.draw_line(rp + Vector2(0, 6), rp + Vector2(0, 18), INK, 1.0)


func _draw_loupe(c: Control, rect: Rect2) -> void:
	if not _has_hover or _tex == null:
		return
	var lp := _to_canvas(_hover, rect)
	var half := Vector2(74, 74)
	var lrect := Rect2(lp - half, half * 2.0)
	lrect.position.x = clampf(lrect.position.x, 4.0, maxf(c.size.x - lrect.size.x - 4.0, 4.0))
	lrect.position.y = clampf(lrect.position.y, 4.0, maxf(c.size.y - lrect.size.y - 4.0, 4.0))
	var s := _pix_scale(rect)
	var src_w := lrect.size.x / maxf(s * ZOOM, 0.001)
	var src := Rect2(_hover - Vector2(src_w, src_w) * 0.5, Vector2(src_w, src_w))
	c.draw_texture_rect_region(_tex, lrect, src, Color.WHITE)
	c.draw_rect(lrect, WINE, false, 3.0)
	var centre := lrect.position + lrect.size * 0.5
	c.draw_line(centre - Vector2(8, 0), centre + Vector2(8, 0), Color(WINE, 0.7), 1.0)
	c.draw_line(centre - Vector2(0, 8), centre + Vector2(0, 8), Color(WINE, 0.7), 1.0)
	var f := UIUtil.font_bold(false)
	var lab := "LOUPE x%d" % int(round(ZOOM))
	c.draw_string(f, lrect.position + Vector2(6, 16), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, WINE)


func _draw_center_text(c: Control, txt: String, col: Color) -> void:
	var f := UIUtil.font_bold(true)
	var ts := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 38)
	c.draw_rect(Rect2(0.0, c.size.y * 0.5 - 34.0, c.size.x, 68.0), Color(CREAM, 0.72), true)
	c.draw_string(f, Vector2((c.size.x - ts.x) * 0.5, c.size.y * 0.5 + 13.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 38, col)


func _draw_meter(c: Control) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(WINE, 0.18), true)
	var w := c.size.x * clampf(_proximity, 0.0, 1.0)
	var col := SKY.lerp(HOT, clampf(_proximity, 0.0, 1.0))
	c.draw_rect(Rect2(Vector2.ZERO, Vector2(w, c.size.y)), col, true)
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(WINE, 0.5), false, 1.0)


# =====================================================================
# misc
# =====================================================================

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
	return t if t != "" else "Watermark Forensics"


func _prompt_text() -> String:
	var p := str(cfg.get("prompt", ""))
	return p if p != "" else "Inspect the still and mark the altered region."
