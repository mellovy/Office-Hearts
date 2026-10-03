class_name UIUtil
extends RefCounted
## Retro pixel-art UI kit: hard edges, thick black borders, chunky flat
## buttons, pixel fonts. No emoji anywhere — text/ascii glyphs only.

const FONT_PIXEL := preload("res://assets/fonts/PressStart2P-Regular.ttf")  # headings / buttons
const FONT_BODY := preload("res://assets/fonts/VT323-Regular.ttf")          # dialogue / body text

# ---- retro pixel palette ----
const BLACK := Color("#120e18")
const BG_DEEP := Color("#1c1428")
const BG_MID := Color("#2e2144")
const PANEL_CREAM := Color("#fffaf8")
const PANEL_DARK := Color("#2a2036")
const PINK := Color("#ff6fa0")
const PINK_DEEP := Color("#c94a78")
const PINK_PALE := Color("#ffd6e6")
const MINT := Color("#57e0ab")
const SKY := Color("#5fb0ec")
const GOLD := Color("#ffd25a")
const TEXT_LIGHT := Color("#fffaf8")
const TEXT_DARK := Color("#241b30")
const TEXT_MUTED := Color("#b9a8c4")

# kept for backward-compat with older calls
const CREAM := PANEL_CREAM
const CREAM_DEEP := Color("#e4d6b8")
const PLUM := TEXT_DARK
const PLUM_SOFT := TEXT_MUTED
const WHITE_PANEL := PANEL_CREAM


static func panel_style(color: Color, radius: int = 0, border_color: Color = Color(0, 0, 0, 0), border_w: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.anti_aliasing = false
	sb.shadow_size = 0
	if border_w > 0:
		sb.border_color = border_color
		sb.border_width_left = border_w
		sb.border_width_right = border_w
		sb.border_width_top = border_w
		sb.border_width_bottom = border_w
	return sb


## Chunky rectangular pixel button: flat fill, thick black border, hard
## corners, pixel font, no emoji.
static func pill_button(text: String, min_w: float = 320, min_h: float = 54) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.custom_minimum_size = Vector2(min_w, min_h)
	b.clip_text = true
	b.add_theme_stylebox_override("normal", panel_style(PINK_PALE, 0, BLACK, 4))
	b.add_theme_stylebox_override("hover", panel_style(TEXT_LIGHT, 0, PINK_DEEP, 4))
	b.add_theme_stylebox_override("pressed", panel_style(PINK_DEEP, 0, BLACK, 4))
	b.add_theme_stylebox_override("disabled", panel_style(TEXT_MUTED, 0, BLACK, 4))
	b.add_theme_stylebox_override("focus", panel_style(PINK_PALE, 0, TEXT_LIGHT, 4))
	b.add_theme_color_override("font_color", TEXT_DARK)
	b.add_theme_color_override("font_hover_color", TEXT_DARK)
	b.add_theme_color_override("font_pressed_color", TEXT_LIGHT)
	b.add_theme_color_override("font_disabled_color", TEXT_DARK.lightened(0.3))
	b.add_theme_font_override("font", FONT_PIXEL)
	b.add_theme_font_size_override("font_size", 13)
	return b


static func button_style(base: Color, hover: Color, pressed: Color, radius: int = 0) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 52)
	b.clip_text = true
	b.add_theme_stylebox_override("normal", panel_style(base, radius, BLACK, 3))
	b.add_theme_stylebox_override("hover", panel_style(hover, radius, BLACK, 3))
	b.add_theme_stylebox_override("pressed", panel_style(pressed, radius, BLACK, 3))
	b.add_theme_stylebox_override("disabled", panel_style(base.darkened(0.2), radius, BLACK, 3))
	b.add_theme_stylebox_override("focus", panel_style(hover, radius, TEXT_LIGHT, 3))
	b.add_theme_color_override("font_color", TEXT_DARK)
	b.add_theme_color_override("font_hover_color", TEXT_DARK)
	b.add_theme_color_override("font_pressed_color", TEXT_LIGHT)
	b.add_theme_color_override("font_disabled_color", TEXT_DARK.lightened(0.3))
	b.add_theme_font_override("font", FONT_PIXEL)
	b.add_theme_font_size_override("font_size", 12)
	return b


static func heading(text: String, size: int, color: Color = TEXT_DARK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT_PIXEL)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.clip_text = true
	return l


## Big pixel-font title with a hard drop-shadow (offset duplicate label).
## Measures the string directly instead of relying on Label minimum-size
## (clip_text collapses that to 0-width, which is what ate the title).
static func title_label(text: String, size: int, color: Color = TEXT_DARK, shadow_color: Color = PINK_DEEP) -> Control:
	var wrap := Control.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text_size: Vector2 = FONT_PIXEL.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)

	var shadow := heading(text, size, shadow_color)
	shadow.clip_text = false
	shadow.position = Vector2(4, 4)
	shadow.size = text_size
	wrap.add_child(shadow)

	var front := heading(text, size, color)
	front.clip_text = false
	front.size = text_size
	wrap.add_child(front)

	wrap.custom_minimum_size = text_size + Vector2(4, 4)
	return wrap


static func body_label(text: String, size: int = 20, color: Color = TEXT_MUTED) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT_BODY)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.clip_text = true
	return l


## Single-line label that never wraps and never overflows its box —
## use for anything sitting in a tight bar (chapter title, location, bgm).
static func bar_label(text: String, size: int, color: Color, font: Font = FONT_BODY) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func bg_gradient(top: Color, bottom: Color) -> Control:
	var rect := ColorRect.new()
	rect.color = top
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grad := Gradient.new()
	grad.set_color(0, top)
	grad.set_color(1, bottom)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	var trect := TextureRect.new()
	trect.texture = tex
	trect.stretch_mode = TextureRect.STRETCH_SCALE
	trect.set_anchors_preset(Control.PRESET_FULL_RECT)
	trect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return trect


## Flat two-tone night-sky pixel backdrop + a grid of tiny pixel "stars".
static func dreamy_bg() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var grad := Gradient.new()
	grad.set_color(0, BG_DEEP)
	grad.set_color(1, BG_MID)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	var trect := TextureRect.new()
	trect.texture = tex
	trect.stretch_mode = TextureRect.STRETCH_SCALE
	trect.set_anchors_preset(Control.PRESET_FULL_RECT)
	trect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(trect)

	root.add_child(heart_pattern())
	return root


## Grid of tiny pixel hearts/dots (no emoji — drawn with block glyphs).
static func heart_pattern(tint: Color = Color(PINK, 0.12)) -> Control:
	var wrap := Control.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var glyphs := ["♥", "·", "✦"]
	for row in range(6):
		for col in range(9):
			var h := Label.new()
			h.text = glyphs[rng.randi_range(0, glyphs.size() - 1)]
			h.add_theme_font_size_override("font_size", rng.randi_range(10, 20))
			h.add_theme_color_override("font_color", tint)
			h.position = Vector2(col * 92 - 20 + rng.randi_range(-14, 14), row * 90 - 10 + rng.randi_range(-14, 14))
			wrap.add_child(h)
	return wrap


## Soft pink + white backdrop for the main menu, with a scattered heart
## pattern on top — the "cute" counterpart to dreamy_bg().
static func cute_bg() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var grad := Gradient.new()
	grad.set_color(0, Color("#fff6f9"))
	grad.add_point(0.55, PINK_PALE)
	grad.set_color(1, Color("#ffc2dd"))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(1, 1)
	var trect := TextureRect.new()
	trect.texture = tex
	trect.stretch_mode = TextureRect.STRETCH_SCALE
	trect.set_anchors_preset(Control.PRESET_FULL_RECT)
	trect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(trect)

	root.add_child(heart_pattern(Color(PINK_DEEP, 0.16)))
	return root


## Pixel-bordered box: black outline + solid fill, zero rounding. Returns
## the INNER container — add your content/margin to it directly.
static func card_panel(radius: int = 0, border_w: int = 4) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style(PANEL_CREAM, radius, BLACK, border_w))
	return p


static func margin(l: int = 28, t: int = 24, r: int = 28, b: int = 24) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	return m


## Small square icon button (options/menu) — plain glyph, no emoji.
static func gear_button() -> Button:
	var b := Button.new()
	b.text = "❖"
	b.custom_minimum_size = Vector2(46, 46)
	b.clip_text = true
	b.add_theme_stylebox_override("normal", panel_style(PINK_PALE, 0, BLACK, 3))
	b.add_theme_stylebox_override("hover", panel_style(TEXT_LIGHT, 0, PINK_DEEP, 3))
	b.add_theme_stylebox_override("pressed", panel_style(PINK_DEEP, 0, BLACK, 3))
	b.add_theme_color_override("font_color", TEXT_DARK)
	b.add_theme_font_override("font", FONT_PIXEL)
	b.add_theme_font_size_override("font_size", 16)
	return b


## Full-screen dim + centered pixel popup card. Returns {overlay, vbox}.
static func popup(title: String) -> Dictionary:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(BLACK, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var card := card_panel(0, 4)
	card.custom_minimum_size = Vector2(360, 0)
	center.add_child(card)

	var m := margin(30, 26, 30, 26)
	card.add_child(m)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	m.add_child(vbox)

	if title != "":
		vbox.add_child(heading(title.to_upper(), 16, PINK_DEEP))
		vbox.add_child(HSeparator.new())

	return {"overlay": overlay, "vbox": vbox}


## One save/load slot card. `exists` controls the subtitle/greyed look;
## `enabled` controls whether it can be clicked (e.g. disable empty slots
## in Load mode, but keep them clickable in Save mode).
static func slot_button(idx: int, exists: bool, chapter_title: String, when_text: String, enabled: bool = true) -> Button:
	var b := Button.new()
	var subtitle := chapter_title if exists else "— empty —"
	var lines := ["SLOT %d" % idx, subtitle]
	if exists and when_text != "":
		lines.append(when_text)
	b.text = "\n".join(lines)
	b.custom_minimum_size = Vector2(230, 86)
	b.clip_text = true
	b.disabled = not enabled
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var fill := PINK_PALE if exists else TEXT_LIGHT
	b.add_theme_stylebox_override("normal", panel_style(fill, 0, BLACK, 3))
	b.add_theme_stylebox_override("hover", panel_style(TEXT_LIGHT, 0, PINK_DEEP, 3))
	b.add_theme_stylebox_override("pressed", panel_style(PINK_DEEP, 0, BLACK, 3))
	b.add_theme_stylebox_override("disabled", panel_style(fill.darkened(0.05), 0, BLACK.lightened(0.3), 3))
	b.add_theme_color_override("font_color", TEXT_DARK)
	b.add_theme_color_override("font_hover_color", TEXT_DARK)
	b.add_theme_color_override("font_pressed_color", TEXT_LIGHT)
	b.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	b.add_theme_font_override("font", FONT_BODY)
	b.add_theme_font_size_override("font_size", 20)
	return b


## 3x2 grid of the 6 save/load slots. `slots` is an Array of 6 Dictionaries
## {"exists":bool, "title":String, "when":String}. `on_pick` is called with
## the 1-based slot index. `load_mode` disables empty slots.
static func slot_grid(slots: Array, on_pick: Callable, load_mode: bool) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for i in range(6):
		var info: Dictionary = slots[i] if i < slots.size() else {"exists": false, "title": "", "when": ""}
		var enabled: bool = bool(info.get("exists", false)) or not load_mode
		var btn := slot_button(i + 1, info.get("exists", false), info.get("title", ""), info.get("when", ""), enabled)
		btn.pressed.connect(on_pick.bind(i + 1))
		grid.add_child(btn)
	return grid


## Master-volume row: a label + an HSlider wired to the "Master" audio bus.
static func volume_row(bus_name: String = "Master") -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)

	var lbl := body_label(bus_name + " Volume", 20, TEXT_DARK)
	lbl.custom_minimum_size = Vector2(160, 0)
	row.add_child(lbl)

	var bus := AudioServer.get_bus_index(bus_name)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.custom_minimum_size = Vector2(180, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus)) if not AudioServer.is_bus_mute(bus) else 0.0
	slider.value_changed.connect(func(v: float):
		AudioServer.set_bus_mute(bus, v <= 0.001)
		if v > 0.001:
			AudioServer.set_bus_volume_db(bus, linear_to_db(v))
	)
	row.add_child(slider)
	return row


static func volume_row_music() -> HBoxContainer:
	return volume_row("Music")

static func volume_row_sfx() -> HBoxContainer:
	return volume_row("SFX")

static func route_color(route: String) -> Color:
	match route:
		"arthur": return SKY
		"dante": return GOLD
		"leo": return MINT
		_: return PINK
