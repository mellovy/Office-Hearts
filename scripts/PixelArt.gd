class_name PixelArt
extends RefCounted
## Soft-anime art placeholders for backdrops and character portraits.
## Everything is drawn in code: smooth gradient rooms, rounded soft shapes,
## and expressive character busts. No external assets.
##
##   var bg := PixelArt.backdrop("exec_office")
##   var p  := PixelArt.portrait("arthur", 240.0, "blush")
##
## Portraits support expressions: neutral | happy | blush | sad.

const _INK := Color("#4a3b52")


class Art extends Control:
	var kind: String = "backdrop"
	var key: String = "neutral"
	var expr: String = "neutral"
	func _draw() -> void:
		if kind == "portrait":
			PixelArt._paint_portrait(self, key, expr)
		else:
			PixelArt._paint_backdrop(self, key)


## Shows an imported portrait PNG: aspect preserved, scaled to fit the lane
## width, anchored to the top of the lane so the head stays clear of the
## dialogue box and the hip/waist falls behind it.
class TexturePortrait extends Control:
	const TARGET_H := 420.0     # base rendered height before the per-character fit
	const FACE_Y := 62.0        # lane y the detected face top is aligned to
	var tex: Texture2D
	var ref_h: float = 0.0      # per-character reference (neutral trimmed height)
	var anchor: float = 0.0     # source row of the face top (aligns eye-lines)
	var fit: float = 1.0        # per-character head-size calibration
	var _tr: TextureRect

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		# FULL_RECT so the control actually fills the holder.
		custom_minimum_size = Vector2.ZERO
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_tr = TextureRect.new()
		_tr.texture = tex
		_tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_tr.stretch_mode = TextureRect.STRETCH_SCALE
		_tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_tr)
		resized.connect(_layout)
		_layout()

	func _layout() -> void:
		if tex == null:
			return
		var tw := float(tex.get_width())
		var th := float(tex.get_height())
		# One scale per character (trimmed height + fit) so every pose — and
		# every character — renders the same head size.
		var rh: float = ref_h if ref_h > 0.0 else th
		var s: float = (TARGET_H * fit) / rh
		s = min(s, size.y / th)
		if s <= 0.0:
			s = 1.0
		var w := tw * s
		var h := th * s
		_tr.size = Vector2(w, h)
		# Align each character's face top to the same lane y so the eye-lines
		# match; the torso runs down behind the dialogue box.
		_tr.position = Vector2((size.x - w) * 0.5, FACE_Y - anchor * s)


## Background: real PNG if present (cover, aspect preserved, overflow
## cropped), else the code-drawn room.
static func backdrop(key: String) -> Control:
	var base := "res://assets/art/backgrounds/%s" % key
	for ext in [".png", ".jpeg", ".jpg", ".webp"]:
		var path: String = base + String(ext)
		if not ResourceLoader.exists(path):
			continue
		var tex := load(path) as Texture2D
		if tex != null:
			var tr := TextureRect.new()
			tr.texture = tex
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			tr.set_anchors_preset(Control.PRESET_FULL_RECT)
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			return tr
	var a := Art.new()
	a.kind = "backdrop"
	a.key = key
	a.set_anchors_preset(Control.PRESET_FULL_RECT)
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return a


## Portrait: real PNG if present, else the code-drawn bust. Signature kept.
static var _portrait_meta: Dictionary = {}

## Per-character calibration. The four crops are trimmed (so their heights
## differ) and the sheets draw the heads at slightly different sizes, so a
## plain height normalisation still leaves the heads off. `fit` equalises them.
const PORTRAIT_FIT := {"arthur": 1.063, "dante": 0.957, "leo": 0.957}

## Skin test used to find each crop's face top (the eye-line anchor). Tight
## enough to ignore warm suits, cravats and ties.
static func _is_skin(c: Color) -> bool:
	if c.a <= 0.6:
		return false
	if c.r < 0.80 or c.g < 0.58 or c.b < 0.42 or c.g > 0.92:
		return false
	var d := c.r - c.b
	return d > 0.18 and d < 0.46


static func _portrait_info(char_key: String) -> Dictionary:
	if _portrait_meta.has(char_key):
		return _portrait_meta[char_key]
	var info := {"h": 0.0, "anchor": 0.0}
	var t = load("res://assets/art/portraits/%s_neutral.png" % char_key)
	if t is Texture2D:
		info["h"] = float(t.get_height())
		var img: Image = t.get_image()
		img.convert(Image.FORMAT_RGBA8)
		var w := img.get_width()
		var need := maxi(6, int(float(w) * 0.012))
		var face_top := -1
		var opaque_top := -1
		for y in img.get_height():
			var skin := 0
			var opaque := 0
			for x in w:
				var c := img.get_pixel(x, y)
				if c.a > 0.5:
					opaque += 1
					if _is_skin(c):
						skin += 1
			if opaque_top < 0 and opaque >= need:
				opaque_top = y
			if face_top < 0 and skin >= need:
				face_top = y
		info["anchor"] = float(face_top if face_top >= 0 else maxi(opaque_top, 0))
	_portrait_meta[char_key] = info
	return info


static func portrait(char_key: String, size: float = 220.0, expression: String = "neutral") -> Control:
	var path := "res://assets/art/portraits/%s_%s.png" % [char_key, expression]
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex != null:
			var info := _portrait_info(char_key)
			var p := TexturePortrait.new()
			p.tex = tex
			p.ref_h = float(info["h"])
			p.anchor = float(info["anchor"])
			p.fit = float(PORTRAIT_FIT.get(char_key, 1.0))
			p.custom_minimum_size = Vector2(size, size * 1.25)
			p.size = Vector2(size, size * 1.25)
			p.mouse_filter = Control.MOUSE_FILTER_IGNORE
			return p
	var a := Art.new()
	a.kind = "portrait"
	a.key = char_key
	a.expr = expression
	a.custom_minimum_size = Vector2(size, size * 1.25)
	a.size = Vector2(size, size * 1.25)
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return a


static func portrait_key_for_speaker(speaker: String) -> String:
	var s := speaker.strip_edges().to_upper()
	# Only the three love interests have user-supplied portrait art. Everyone
	# else (Sterling, Maya, narration) gets no portrait at all.
	match s:
		"ARTHUR", "MR. PENDELTON", "PENDELTON": return "arthur"
		"DANTE": return "dante"
		"LEO": return "leo"
		_: return ""


## Heuristic expression picker for a line of dialogue.
static func expression_for_text(text: String) -> String:
	var t := text.to_lower()
	if t.contains("blush") or t.contains("heart skips") or t.contains("heart pound") or t.contains("fluster"):
		return "blush"
	if t.contains("smil") or t.contains("grin") or t.contains("laugh") or t.contains("giggle") or t.contains("chuckl") or t.contains("snicker"):
		return "happy"
	if t.contains("sigh") or t.contains("tears") or t.contains("frown") or t.contains("sad") or t.contains("whisper") or t.contains("trembl"):
		return "sad"
	return "neutral"


static func char_color(char_key: String) -> Color:
	match char_key:
		"arthur": return UIUtil.SKY
		"dante": return UIUtil.GOLD
		"leo": return UIUtil.MINT
		"maya": return UIUtil.PINK
		"sterling": return Color("#b0a7bb")
		_: return UIUtil.TEXT_MUTED


static func scene_keys() -> PackedStringArray:
	return PackedStringArray([
		"office_floor", "common_office", "hub_office", "exec_office", "exec_lounge",
		"boardroom", "balcony_night", "office_lobby_night", "breakroom", "archive",
		"it_hub", "lobby_day", "branch_office", "design_studio", "roof_garden",
		"server_room", "roof_morning", "cubicle_empty", "neutral",
	])


# =====================================================================
# drawing primitives
# =====================================================================

static func _r(c: Control, x: float, y: float, w: float, h: float, col: Color, radius: float = 14.0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(radius))
	sb.anti_aliasing = true
	c.draw_style_box(sb, Rect2(x, y, w, h))


static func _vgrad(c: Control, top: Color, bottom: Color, bands: int = 30) -> void:
	var s := c.size
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		var col := top.lerp(bottom, t)
		_r(c, -2, s.y * i / bands, s.x + 4, s.y / bands + 1.5, col, 0.0)


static func _ellipse(c: Control, center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(24):
		var a := TAU * i / 24.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	c.draw_colored_polygon(pts, col)


static func _bokeh(c: Control, seed_val: int, tint: Color, count: int = 12) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	for i in range(count):
		var r := rng.randf_range(28, 110)
		var p := Vector2(rng.randf_range(-20, c.size.x + 20), rng.randf_range(-20, c.size.y + 20))
		c.draw_circle(p, r, Color(tint, rng.randf_range(0.03, 0.09)))


static func _soft_window(c: Control, x: float, y: float, w: float, h: float, night: bool) -> void:
	var sky_top := Color("#1a2138") if night else Color("#bfe0f6")
	var sky_bot := Color("#3a4a72") if night else Color("#e6f3fb")
	_r(c, x, y, w, h, sky_top, 22)
	for i in range(14):
		var t := float(i) / 13.0
		_r(c, x, y + h * t, w, h / 14.0 + 1.5, sky_top.lerp(sky_bot, t), 0.0)
	# soft skyline
	var rng := RandomNumberGenerator.new()
	rng.seed = int(x) * 7 + int(w)
	var bx := x + 8
	while bx < x + w - 14:
		var bw := rng.randf_range(14, 40)
		var bh := rng.randf_range(h * 0.22, h * 0.55)
		_r(c, bx, y + h - bh, bw, bh, (Color("#0e1426") if night else Color("#7fa6c9")), 8)
		if night:
			for k in range(4):
				if rng.randf() > 0.45:
					_r(c, bx + 5, y + h - bh + 8 + k * 12, 5, 5, Color(UIUtil.GOLD, 0.8), 2)
		bx += bw + rng.randf_range(4, 12)
	# rounded frame
	_r(c, x, y, w, h, Color(0, 0, 0, 0), 22)


static func _plant(c: Control, x: float, y: float) -> void:
	_r(c, x, y, 30, 26, Color("#d8b48c"), 10)
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(x + 15, y), Vector2(x - 8, y - 34), Vector2(x + 15, y - 12)]), Color("#7fce9e"))
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(x + 15, y), Vector2(x + 38, y - 34), Vector2(x + 15, y - 12)]), Color("#9fe0b8"))


static func _desk(c: Control, x: float, y: float, w: float, col: Color) -> void:
	_r(c, x, y, w, 16, col, 8)
	_r(c, x + 10, y + 16, 10, 30, col.darkened(0.12), 4)
	_r(c, x + w - 20, y + 16, 10, 30, col.darkened(0.12), 4)


static func _monitor(c: Control, x: float, y: float, on: bool = true) -> void:
	_r(c, x, y, 52, 36, Color("#3a3145"), 8)
	_r(c, x + 5, y + 5, 42, 26, (Color("#8fc7f2") if on else Color("#6b6376")), 5)
	_r(c, x + 22, y + 36, 8, 10, Color("#3a3145"), 3)


# =====================================================================
# backdrops
# =====================================================================

static func _scene_style(key: String) -> Dictionary:
	match key:
		"exec_office":      return {"top": "#3a4066", "bot": "#242a45", "floor": "#1d2237", "glow": UIUtil.SKY, "night": true, "prop": "desk"}
		"exec_lounge":      return {"top": "#4a3a5e", "bot": "#2c2340", "floor": "#221a33", "glow": UIUtil.LAVENDER, "night": true, "prop": "sofa"}
		"boardroom":        return {"top": "#5a4a42", "bot": "#332a26", "floor": "#241d1a", "glow": UIUtil.GOLD, "night": false, "prop": "table"}
		"balcony_night":    return {"top": "#232c4a", "bot": "#141a30", "floor": "#101426", "glow": UIUtil.SKY, "night": true, "prop": "railing"}
		"office_lobby_night": return {"top": "#2e3550", "bot": "#1c2138", "floor": "#161a2c", "glow": UIUtil.LAVENDER, "night": true, "prop": "elevator"}
		"archive":          return {"top": "#3d3a52", "bot": "#26243a", "floor": "#1c1a2c", "glow": UIUtil.GOLD, "night": true, "prop": "shelves"}
		"it_hub":           return {"top": "#2b3550", "bot": "#1a2236", "floor": "#141a2a", "glow": UIUtil.MINT, "night": true, "prop": "racks"}
		"design_studio":    return {"top": "#2f3350", "bot": "#1e2238", "floor": "#181b2c", "glow": UIUtil.MINT, "night": true, "prop": "easel"}
		"roof_garden":      return {"top": "#28344f", "bot": "#171f33", "floor": "#131a2a", "glow": UIUtil.SKY, "night": true, "prop": "garden"}
		"server_room":      return {"top": "#2a3140", "bot": "#1a2029", "floor": "#151a22", "glow": UIUtil.SKY, "night": true, "prop": "racks"}
		"common_office", "office_floor", "hub_office":
			return {"top": "#f7e6d6", "bot": "#e9c9a8", "floor": "#d3ab84", "glow": UIUtil.GOLD, "night": false, "prop": "office"}
		"breakroom":        return {"top": "#eef3dc", "bot": "#d6e0bc", "floor": "#b8c49a", "glow": UIUtil.MINT, "night": false, "prop": "counter"}
		"lobby_day":        return {"top": "#eef4fb", "bot": "#dbe6f2", "floor": "#c2cddd", "glow": UIUtil.SKY, "night": false, "prop": "reception"}
		"branch_office":    return {"top": "#ececec", "bot": "#d6d6d6", "floor": "#bcbcbc", "glow": UIUtil.TEXT_MUTED, "night": false, "prop": "desk"}
		"roof_morning":     return {"top": "#bfe0f6", "bot": "#f6e0c8", "floor": "#e6d3b8", "glow": UIUtil.GOLD, "night": false, "prop": "garden"}
		"cubicle_empty":    return {"top": "#dcd3c6", "bot": "#c2b8a8", "floor": "#a89e8e", "glow": UIUtil.GOLD, "night": false, "prop": "desk"}
		_:                  return {"top": "#efe0f2", "bot": "#d8c6e6", "floor": "#c0adcf", "glow": UIUtil.PINK, "night": false, "prop": "office"}


static func _paint_backdrop(c: Control, key: String) -> void:
	var st := _scene_style(key)
	_vgrad(c, Color(st["top"]), Color(st["bot"]))
	_bokeh(c, abs(key.hash()), st["glow"], 14)

	# floor band
	var fy: float = c.size.y * 0.68
	_r(c, -2, fy, c.size.x + 4, c.size.y - fy + 2, Color(st["floor"]), 0.0)

	var night: bool = st["night"]
	match String(st["prop"]):
		"office":
			_soft_window(c, c.size.x * 0.06, c.size.y * 0.14, c.size.x * 0.30, c.size.y * 0.38, night)
			_soft_window(c, c.size.x * 0.64, c.size.y * 0.14, c.size.x * 0.30, c.size.y * 0.38, night)
			_desk(c, c.size.x * 0.10, c.size.y * 0.60, c.size.x * 0.26, Color("#c9a06e"))
			_desk(c, c.size.x * 0.64, c.size.y * 0.60, c.size.x * 0.26, Color("#c9a06e"))
			_monitor(c, c.size.x * 0.13, c.size.y * 0.46)
			_monitor(c, c.size.x * 0.67, c.size.y * 0.46)
			_plant(c, c.size.x * 0.47, c.size.y * 0.64)
		"desk":
			_soft_window(c, c.size.x * 0.52, c.size.y * 0.14, c.size.x * 0.44, c.size.y * 0.46, night)
			_desk(c, c.size.x * 0.08, c.size.y * 0.60, c.size.x * 0.38, Color("#8a6a4a") if not night else Color("#5a4a58"))
			_monitor(c, c.size.x * 0.13, c.size.y * 0.44)
			_plant(c, c.size.x * 0.46, c.size.y * 0.64)
		"sofa":
			_soft_window(c, c.size.x * 0.56, c.size.y * 0.16, c.size.x * 0.38, c.size.y * 0.42, night)
			_r(c, c.size.x * 0.10, c.size.y * 0.62, c.size.x * 0.36, 44, Color("#b06a86"), 18)
			_r(c, c.size.x * 0.10, c.size.y * 0.56, c.size.x * 0.36, 20, Color("#c47e98"), 12)
		"table":
			_r(c, c.size.x * 0.12, c.size.y * 0.62, c.size.x * 0.76, c.size.y * 0.13, Color("#8a5a3c"), 16)
			_soft_window(c, c.size.x * 0.30, c.size.y * 0.14, c.size.x * 0.40, c.size.y * 0.32, night)
		"railing":
			_r(c, 0, c.size.y * 0.62, c.size.x, 8, Color("#2a3550"), 4)
			for i in range(0, int(c.size.x), 46):
				_r(c, i, c.size.y * 0.62, 4, c.size.y * 0.12, Color("#2a3550"), 2)
			_bokeh(c, 99, UIUtil.SKY, 16)
		"elevator":
			_soft_window(c, c.size.x * 0.10, c.size.y * 0.14, c.size.x * 0.80, c.size.y * 0.42, night)
			_r(c, c.size.x * 0.42, c.size.y * 0.24, c.size.x * 0.16, c.size.y * 0.44, Color("#6b7388"), 12)
			_r(c, c.size.x * 0.50 - 2, c.size.y * 0.24, 4, c.size.y * 0.44, Color("#4a5060"), 2)
		"shelves":
			for i in range(4):
				_r(c, c.size.x * (0.06 + i * 0.23), c.size.y * 0.22, c.size.x * 0.17, c.size.y * 0.48, Color("#6b6386"), 14)
				for j in range(3):
					_r(c, c.size.x * (0.075 + i * 0.23), c.size.y * (0.27 + j * 0.13), c.size.x * 0.14, 6, Color("#8a82a6"), 3)
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(c.size.x * 0.10, c.size.y * 0.88), Vector2(c.size.x * 0.52, c.size.y * 0.36), Vector2(c.size.x * 0.92, c.size.y * 0.88)]),
				Color(UIUtil.GOLD, 0.14))
		"racks":
			for i in range(4):
				_r(c, c.size.x * (0.07 + i * 0.23), c.size.y * 0.20, c.size.x * 0.15, c.size.y * 0.52, Color("#4a5568"), 12)
				for j in range(4):
					c.draw_circle(Vector2(c.size.x * (0.09 + i * 0.23), c.size.y * (0.26 + j * 0.11)), 5, st["glow"])
		"easel":
			_r(c, c.size.x * 0.10, c.size.y * 0.12, c.size.x * 0.80, 6, st["glow"], 3)
			_monitor(c, c.size.x * 0.16, c.size.y * 0.44)
			_desk(c, c.size.x * 0.10, c.size.y * 0.60, c.size.x * 0.62, Color("#5a5f7a"))
			for i in range(4):
				_r(c, c.size.x * (0.66 + (i % 2) * 0.14), c.size.y * (0.22 + (i / 2) * 0.17), c.size.x * 0.10, c.size.y * 0.13, Color("#f2ead8"), 8)
		"garden":
			_soft_window(c, 0, c.size.y * 0.10, c.size.x, c.size.y * 0.52, night)
			for i in range(5):
				_plant(c, c.size.x * (0.07 + i * 0.20), c.size.y * 0.66)
		"counter":
			_r(c, c.size.x * 0.05, c.size.y * 0.58, c.size.x * 0.90, 24, Color("#a8b88a"), 12)
			_r(c, c.size.x * 0.72, c.size.y * 0.30, c.size.x * 0.20, c.size.y * 0.40, Color("#e88ab0"), 16)
		"reception":
			_soft_window(c, c.size.x * 0.05, c.size.y * 0.10, c.size.x * 0.90, c.size.y * 0.44, night)
			_r(c, c.size.x * 0.34, c.size.y * 0.60, c.size.x * 0.32, c.size.y * 0.14, Color("#aab3c2"), 14)
		_:
			_plant(c, c.size.x * 0.12, c.size.y * 0.66)

	# Pastel wash + faint glitter so the code-drawn fallback reads soft and
	# pale like the reference (primary art is AI-generated PNGs).
	_wash(c)
	_sparkle(c, abs(key.hash()))


## Translucent pink -> lavender gradient laid over a room to unify it into
## the washed pastel look.
static func _wash(c: Control) -> void:
	var s := c.size
	var top := Color(UIUtil.PINK, 0.16)
	var bot := Color(UIUtil.LAVENDER, 0.24)
	for i in range(30):
		var t := float(i) / 29.0
		_r(c, -2, s.y * i / 30.0, s.x + 4, s.y / 30.0 + 1.5, top.lerp(bot, t), 0.0)


## Faint 4-point glitter scattered over a backdrop.
static func _sparkle(c: Control, seed_val: int, count: int = 14) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	for i in range(count):
		var p := Vector2(rng.randf_range(0, c.size.x), rng.randf_range(0, c.size.y))
		var r := rng.randf_range(2.5, 7.0)
		var col := Color(1, 1, 1, rng.randf_range(0.22, 0.6))
		c.draw_colored_polygon(PackedVector2Array([
			p + Vector2(0, -r), p + Vector2(r * 0.22, 0), p + Vector2(0, r), p + Vector2(-r * 0.22, 0)]), col)
		c.draw_colored_polygon(PackedVector2Array([
			p + Vector2(-r, 0), p + Vector2(0, r * 0.22), p + Vector2(r, 0), p + Vector2(0, -r * 0.22)]), col)
		c.draw_circle(p, r * 0.28, col)


# =====================================================================
# portraits
# =====================================================================

static func _char_style(k: String) -> Dictionary:
	match k:
		"arthur":
			return {"hair": Color("#3a2f42"), "skin": Color("#f2d0ae"), "outfit": Color("#454f66"),
					"accent": UIUtil.SKY, "shape": "slick", "glasses": false}
		"dante":
			return {"hair": Color("#f4c85a"), "skin": Color("#f6d6b0"), "outfit": Color("#c08a3a"),
					"accent": UIUtil.GOLD, "shape": "spiky", "glasses": false}
		"leo":
			return {"hair": Color("#3a3346"), "skin": Color("#edcba8"), "outfit": Color("#3f6459"),
					"accent": UIUtil.MINT, "shape": "shaggy", "glasses": false}
		"maya":
			return {"hair": Color("#7a5540"), "skin": Color("#f8dcbe"), "outfit": Color("#e0709c"),
					"accent": UIUtil.PINK, "shape": "long", "glasses": false}
		"sterling":
			return {"hair": Color("#b0a7bb"), "skin": Color("#eccfae"), "outfit": Color("#6b6f7a"),
					"accent": Color("#b0a7bb"), "shape": "slick", "glasses": true}
		_:
			return {"hair": Color("#4a3b52"), "skin": Color("#f0d4b4"), "outfit": Color("#6b5a72"),
					"accent": UIUtil.TEXT_MUTED, "shape": "short", "glasses": false}


static func _paint_portrait(c: Control, k: String, expr: String) -> void:
	var s := c.size
	if s.x <= 0.0:
		return
	var u := s.x / 22.0
	var st := _char_style(k)
	var hair: Color = st["hair"]
	var skin: Color = st["skin"]
	var outfit: Color = st["outfit"]
	var accent: Color = st["accent"]
	var shape: String = st["shape"]
	var cc := char_color(k)

	# soft rounded backing panel
	_r(c, 0, 0, s.x, s.y, Color("#fff3fa"), 20)
	_r(c, 4, 4, s.x - 8, s.y - 8, cc.darkened(0.25), 18)
	_bokeh(c, int(k.hash()), cc, 8)

	# shoulders / torso
	_r(c, 2 * u, 14.5 * u, 18 * u, s.y - 14.5 * u, outfit, 10)
	# collar accent
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(8 * u, 15 * u), Vector2(11 * u, 15 * u), Vector2(11 * u, 20.5 * u)]), accent)
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(14 * u, 15 * u), Vector2(11 * u, 15 * u), Vector2(11 * u, 20.5 * u)]), skin.darkened(0.1))

	# neck
	_r(c, 9.6 * u, 12.4 * u, 2.8 * u, 3.2 * u, skin.darkened(0.08), 3)

	# head (soft rounded)
	_r(c, 6 * u, 3 * u, 10 * u, 10.2 * u, skin, 4.6 * u)

	# ears
	_ellipse(c, Vector2(5.7 * u, 8 * u), 0.9 * u, 1.5 * u, skin)
	_ellipse(c, Vector2(16.3 * u, 8 * u), 0.9 * u, 1.5 * u, skin)

	# hair per shape
	match shape:
		"slick":
			_r(c, 5.5 * u, 2.2 * u, 11 * u, 3.4 * u, hair, 4 * u)
			_r(c, 8 * u, 2.4 * u, 3 * u, 1.1 * u, hair.lightened(0.18), 2)
		"spiky":
			for i in range(5):
				c.draw_colored_polygon(PackedVector2Array([
					Vector2((6 + i * 2) * u, 3.4 * u), Vector2((7 + i * 2) * u, 0.4 * u),
					Vector2((8 + i * 2) * u, 3.4 * u)]), hair)
			_r(c, 5.6 * u, 2.4 * u, 10.8 * u, 2.2 * u, hair, 3.5 * u)
		"shaggy":
			_r(c, 5.3 * u, 2.0 * u, 11.4 * u, 4.6 * u, hair, 4.5 * u)
			_r(c, 5.1 * u, 3.6 * u, 2.2 * u, 7 * u, hair, 3 * u)
			_r(c, 14.7 * u, 3.6 * u, 2.2 * u, 7 * u, hair, 3 * u)
		"long":
			_r(c, 5.3 * u, 2.0 * u, 11.4 * u, 4 * u, hair, 4 * u)
			_r(c, 4.9 * u, 3.2 * u, 2.4 * u, 12 * u, hair, 3.5 * u)
			_r(c, 14.7 * u, 3.2 * u, 2.4 * u, 12 * u, hair, 3.5 * u)
		_:
			_r(c, 5.7 * u, 2.3 * u, 10.6 * u, 3.2 * u, hair, 4 * u)

	var eye_y := 7.8 * u
	var lx := 8.1 * u
	var rx := 13.9 * u

	# expression: brows / eyes / mouth / blush
	var blush := expr == "blush"
	if expr == "happy":
		# closed happy eyes: upward arcs
		c.draw_arc(Vector2(lx, eye_y + 0.6 * u), 1.4 * u, PI * 1.15, PI * 1.85, 16, _INK, 0.55 * u, true)
		c.draw_arc(Vector2(rx, eye_y + 0.6 * u), 1.4 * u, PI * 1.15, PI * 1.85, 16, _INK, 0.55 * u, true)
		_ellipse(c, Vector2(9.2 * u, 10.7 * u), 2 * u, 1.4 * u, Color("#a24a5a"))  # open smile
		_ellipse(c, Vector2(6.6 * u, 10.8 * u), 1.1 * u, 0.7 * u, Color(UIUtil.PINK, 0.45))
		_ellipse(c, Vector2(15.4 * u, 10.8 * u), 1.1 * u, 0.7 * u, Color(UIUtil.PINK, 0.45))
	elif expr == "sad":
		_r(c, 6.6 * u, 6.2 * u, 2.6 * u, 0.5 * u, hair.darkened(0.15), 1)   # inner-up brows
		_r(c, 12.8 * u, 6.2 * u, 2.6 * u, 0.5 * u, hair.darkened(0.15), 1)
		c.draw_arc(Vector2(lx, 8.4 * u), 1.5 * u, PI * 1.15, PI * 1.85, 16, _INK, 0.5 * u, true)
		c.draw_arc(Vector2(rx, 8.4 * u), 1.5 * u, PI * 1.15, PI * 1.85, 16, _INK, 0.5 * u, true)
		c.draw_arc(Vector2(11 * u, 11 * u), 1.6 * u, PI * 1.15, PI * 1.85, 16, Color("#a25a5a"), 0.4 * u, true)
	else:
		# open eyes
		_ellipse(c, Vector2(lx, eye_y), 1.5 * u, 1.9 * u, Color("#fff7fb"))
		_ellipse(c, Vector2(rx, eye_y), 1.5 * u, 1.9 * u, Color("#fff7fb"))
		_ellipse(c, Vector2(lx, eye_y), 0.95 * u, 1.35 * u, _INK)
		_ellipse(c, Vector2(rx, eye_y), 0.95 * u, 1.35 * u, _INK)
		_ellipse(c, Vector2(lx - 0.45 * u, eye_y - 0.5 * u), 0.4 * u, 0.5 * u, Color("#fff7fb"))
		_ellipse(c, Vector2(rx - 0.45 * u, eye_y - 0.5 * u), 0.4 * u, 0.5 * u, Color("#fff7fb"))
		# brows
		_r(c, 6.8 * u, 5.7 * u, 2.6 * u, 0.5 * u, hair.darkened(0.15), 1)
		_r(c, 12.6 * u, 5.7 * u, 2.6 * u, 0.5 * u, hair.darkened(0.15), 1)
		if expr == "blush":
			_ellipse(c, Vector2(11 * u, 10.8 * u), 1.1 * u, 0.9 * u, Color("#a24a5a"))
		else:
			_r(c, 9.8 * u, 10.7 * u, 2.6 * u, 0.5 * u, Color("#a25a5a"), 1)

	if blush or expr == "happy":
		_ellipse(c, Vector2(7 * u, 9.8 * u), 1.6 * u, 0.9 * u, Color(UIUtil.PINK, 0.4))
		_ellipse(c, Vector2(15 * u, 9.8 * u), 1.6 * u, 0.9 * u, Color(UIUtil.PINK, 0.4))

	if bool(st["glasses"]):
		c.draw_arc(Vector2(lx, eye_y), 2.2 * u, 0, TAU, 24, _INK, 0.28 * u, true)
		c.draw_arc(Vector2(rx, eye_y), 2.2 * u, 0, TAU, 24, _INK, 0.28 * u, true)
		_r(c, 9.4 * u, eye_y - 0.14 * u, 3.2 * u, 0.28 * u, _INK, 1)
