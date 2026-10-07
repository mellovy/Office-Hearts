class_name UIUtil
extends RefCounted
## Soft-anime UI kit for Office Hearts: pastel confetti backgrounds, glossy
## pink pills, gradient choice bars, deep-wine ornate cards with cream paper
## insets, a rounded display font, and gentle floating decorations.
## Dialogue text stays in the pixel body font (white fill + soft outline).

const FONT_UI := preload("res://assets/fonts/Nunito.ttf")                  # body + UI (400)
const FONT_BODY := FONT_UI                                                 # dialogue body
const FONT_DISPLAY := preload("res://assets/fonts/PlayfairDisplay.ttf")    # titles + names
const FONT_PIXEL := FONT_DISPLAY                                           # legacy alias

# Weighted instances of the variable fonts (cached).
static var _font_cache: Dictionary = {}

static func font_w(weight: int, display: bool = false) -> Font:
	var key := ("d" if display else "n") + str(weight)
	if _font_cache.has(key):
		return _font_cache[key]
	var base: Font = FONT_DISPLAY if display else FONT_UI
	if weight == 400:
		_font_cache[key] = base
		return base
	var fv := FontVariation.new()
	fv.base_font = base
	# OpenType 'wght' axis tag (0x77676874); a numeric tag key is required.
	fv.variation_opentype = {0x77676874: weight}
	_font_cache[key] = fv
	return fv


static func font_semi(display: bool = false) -> Font:
	return font_w(600, display)


static func font_bold(display: bool = false) -> Font:
	return font_w(700, display)

# ---- soft pastel palette (reference-matched) ----
const BLACK := Color("#57465F")          # soft ink (kept name for compatibility)
const BG_DEEP := Color("#7A2F52")        # deep wine/plum
const BG_MID := Color("#8B7FD4")         # periwinkle
const PANEL_CREAM := Color("#FDE8D0")    # cream paper
const PANEL_DARK := Color("#7A2F52")     # deep wine
const PINK := Color("#F4A0B8")           # blush
const PINK_DEEP := Color("#E8447E")      # hot pink
const PINK_PALE := Color("#F9C9D6")      # pale pink
const MINT := Color("#A99FE0")           # lavender (Leo accent; kept name)
const SKY := Color("#A8D8F0")            # sky
const GOLD := Color("#F5E08A")           # butter
const LAVENDER := Color("#A99FE0")       # lavender
const PERIWINKLE := Color("#8B7FD4")     # periwinkle
const WINE := Color("#7A2F52")           # deep wine/plum
const BLUSH := Color("#F4A0B8")          # blush
const BUTTER := Color("#F5E08A")         # butter
const CREAM := PANEL_CREAM
const TEXT_LIGHT := Color("#FFFFFF")     # white
const TEXT_DARK := Color("#57465F")      # soft ink
const TEXT_MUTED := Color("#7C6B86")
const SHADOW := Color(0.45, 0.15, 0.35, 0.16)
const SHADOW_STRONG := Color(0.45, 0.15, 0.35, 0.30)

# kept for backward-compat with older calls
const CREAM_DEEP := Color("#EBCFAE")
const PLUM := TEXT_DARK
const PLUM_SOFT := TEXT_MUTED
const WHITE_PANEL := PANEL_CREAM


# =====================================================================
# real UI asset pack (9-sliced)
# =====================================================================

const TEX_ROOT := "res://ui_assets/Exports/"
const TEX_DIALOGUE := TEX_ROOT + "Dialogue/DialogueContainer.png"
const TEX_REPLY := TEX_ROOT + "Dialogue/ReplyBtn.png"
const TEX_REPLY_P := TEX_ROOT + "Dialogue/ReplyBtnPressed.png"
const TEX_HOME := TEX_ROOT + "HomeScreen/Button.png"
const TEX_HOME_P := TEX_ROOT + "HomeScreen/ButtonPressed.png"
const TEX_GREEN := TEX_ROOT + "GreenBtn.png"
const TEX_GREEN_P := TEX_ROOT + "GreenBtnPressed.png"
const TEX_NEXT := TEX_ROOT + "NextBtn.png"
const TEX_NEXT_P := TEX_ROOT + "NextBtnPressed.png"
const TEX_POPUP := TEX_ROOT + "ExitPopup/PopUpContainer.png"
const TEX_RED := TEX_ROOT + "ExitPopup/RedBtn.png"
const TEX_RED_P := TEX_ROOT + "ExitPopup/RedBtnPressed.png"
const TEX_BLUE := TEX_ROOT + "ExitPopup/BlueBtn.png"
const TEX_BLUE_P := TEX_ROOT + "ExitPopup/BlueBtnPressed.png"
const TEX_CONTINUE := TEX_ROOT + "VictoryOrDefeat/ContinueBtn.png"
const TEX_CONTINUE_P := TEX_ROOT + "VictoryOrDefeat/ContinueBtnPressed.png"
const TEX_VICTORY := TEX_ROOT + "VictoryOrDefeat/VictoryTitleContainer.png"
const TEX_DEFEAT := TEX_ROOT + "VictoryOrDefeat/DefeatTitleContainer.png"
const TEX_TEXTBOX := TEX_ROOT + "VictoryOrDefeat/TextContainer.png"
const TEX_CHAR_FRAME := TEX_ROOT + "CharacterScreen/CharacterContainer.png"
const TEX_CHAR_SEL := TEX_ROOT + "CharacterScreen/SelectedCharacter.png"
const TEX_CHAR_UNKNOWN := TEX_ROOT + "CharacterScreen/UnknownCharacterContainer.png"
const TEX_LARGE_TEXT := TEX_ROOT + "CharacterScreen/LargeTextContainer.png"
const TEX_SMALL_TEXT := TEX_ROOT + "CharacterScreen/SmallTextContainer.png"
const TEX_BOTTOM_SHADOW := TEX_ROOT + "CharacterScreen/BottomShadow.png"
const TEX_SETTINGS_BG := TEX_ROOT + "Settings/SettingsBackground.png"
const TEX_MASTER_VOL := TEX_ROOT + "Settings/MasterVolumeContainer.png"
const TEX_SOUND_VOL := TEX_ROOT + "Settings/SoundSettingsContainer.png"
const TEX_SWITCH := TEX_ROOT + "Settings/Switch.png"
const TEX_SWITCH_BG := TEX_ROOT + "Settings/SwitchBackground.png"
const TEX_VOL_EMPTY := TEX_ROOT + "Settings/VolumeBarEmpty.png"
const TEX_VOL_FILL := TEX_ROOT + "Settings/VolumeFill.png"
const TEX_VOL_KNOB := TEX_ROOT + "Settings/VolumeKnob.png"
const TEX_ICON_SETTINGS := TEX_ROOT + "Icons/Settings.png"
const TEX_ICON_BACK := TEX_ROOT + "Icons/BackArrow.png"
const TEX_ICON_HEART_PINK := TEX_ROOT + "Icons/PinkHeart.png"
const TEX_ICON_HEART_BLUE := TEX_ROOT + "Icons/BlueHeart.png"
const TEX_ICON_CHECK := TEX_ROOT + "Icons/Checkmark.png"


static func tex(path: String) -> Texture2D:
	return load(path) as Texture2D


## Load a texture and resize it (used for slider knobs / small icons drawn at
## the pack's native 83px+ size). Optional flat tint baked into the pixels.
static func scaled_tex(path: String, w: int, h: int, tint: Color = Color.WHITE) -> ImageTexture:
	var t := load(path) as Texture2D
	if t == null:
		return null
	var img: Image = t.get_image()
	img.resize(max(w, 1), max(h, 1), Image.INTERPOLATE_LANCZOS)
	if tint != Color.WHITE:
		img.convert(Image.FORMAT_RGBA8)
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				var c := img.get_pixel(x, y)
				c.r *= tint.r
				c.g *= tint.g
				c.b *= tint.b
				c.a *= tint.a
				img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## Recolour a pack texture to a target hue while preserving its shading (each
## pixel is mapped by luminance). Used to make the blue slider art pink.
static func recolor_tex(path: String, target: Color, w: int = -1, h: int = -1) -> ImageTexture:
	var t := load(path) as Texture2D
	if t == null:
		return null
	var img: Image = t.get_image()
	img.convert(Image.FORMAT_RGBA8)
	if w > 0 and h > 0:
		img.resize(w, h, Image.INTERPOLATE_LANCZOS)
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a <= 0.001:
				continue
			var lum := clampf(c.r * 0.299 + c.g * 0.587 + c.b * 0.114, 0.0, 1.0)
			# Map mid-tone pixels to the target colour; keep darks dark.
			var k := clampf(lum / 0.62, 0.28, 1.0)
			img.set_pixel(x, y, Color(target.r * k, target.g * k, target.b * k, c.a))
	return ImageTexture.create_from_image(img)


## Composite a (translucent) pack texture over an opaque plate so it can be
## used directly as a panel background — one box, no nested panel. `crop`
## trims the soft outer shadow halo so the border sits at the panel edge.
static func opaque_tex(path: String, bg: Color = Color("#FDF0E1"), crop: int = 28) -> ImageTexture:
	var t := load(path) as Texture2D
	if t == null:
		return null
	var img: Image = t.get_image()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	if crop > 0 and w > crop * 2 and h > crop * 2:
		img = img.get_region(Rect2i(crop, crop, w - crop * 2, h - crop * 2))
		w = img.get_width()
		h = img.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.fill(bg)
	out.blend_rect(img, Rect2i(0, 0, w, h), Vector2i.ZERO)
	return ImageTexture.create_from_image(out)


static func tex_panel(path: String, m: int = 24, cm: int = -1, mod: Color = Color.WHITE) -> StyleBoxTexture:
	return tex_panel_xy(path, m, m, cm, cm, mod)


static func tex_panel_xy(path: String, mx: int, my: int, cmx: int = -1, cmy: int = -1, mod: Color = Color.WHITE) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex(path)
	sb.texture_margin_left = mx
	sb.texture_margin_right = mx
	sb.texture_margin_top = my
	sb.texture_margin_bottom = my
	if cmx >= 0:
		sb.content_margin_left = cmx
		sb.content_margin_right = cmx
	if cmy >= 0:
		sb.content_margin_top = cmy
		sb.content_margin_bottom = cmy
	sb.modulate_color = mod
	return sb


## StyleBoxTexture from an already-loaded texture (e.g. a recoloured one).
static func tex_panel_tex(t: Texture2D, mx: int, my: int, cmx: int = -1, cmy: int = -1, mod: Color = Color.WHITE) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = t
	sb.texture_margin_left = mx
	sb.texture_margin_right = mx
	sb.texture_margin_top = my
	sb.texture_margin_bottom = my
	if cmx >= 0:
		sb.content_margin_left = cmx
		sb.content_margin_right = cmx
	if cmy >= 0:
		sb.content_margin_top = cmy
		sb.content_margin_bottom = cmy
	sb.modulate_color = mod
	return sb


## Pull a face colour + text colour + tint for a button "kind".
static func _btn_kind(kind: String) -> Array:
	match kind:
		"reply": return [TEX_REPLY, TEX_REPLY_P, TEXT_DARK, Color(1, 1, 1, 0.65), Color.WHITE]
		"green": return [TEX_GREEN, TEX_GREEN_P, TEXT_DARK, Color(1, 1, 1, 0.5), Color(1.0, 0.78, 0.92)]
		"blue": return [TEX_BLUE, TEX_BLUE_P, TEXT_LIGHT, Color(WINE, 0.55), Color.WHITE]
		"red": return [TEX_RED, TEX_RED_P, TEXT_LIGHT, Color(WINE, 0.55), Color.WHITE]
		"continue": return [TEX_CONTINUE, TEX_CONTINUE_P, TEXT_LIGHT, Color(WINE, 0.55), Color.WHITE]
		_: return [TEX_HOME, TEX_HOME_P, TEXT_LIGHT, Color(WINE, 0.5), Color("#F27BAE")]


## Code-drawn button face: flat rectangle, small radius, palette-matched.
static func _rect_style(fill: Color, border: Color, border_w: int, radius: int, shadow_col: Color, shadow_off: Vector2, shadow_size: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border_w)
	sb.border_color = border
	sb.anti_aliasing = true
	sb.anti_aliasing_size = 1.0
	if shadow_size > 0:
		sb.shadow_color = shadow_col
		sb.shadow_size = shadow_size
		sb.shadow_offset = shadow_off
	return sb


## Applies the shared rectangular button look (cream fill, hot-pink border,
## dark ink label) to a Button. Radius is a consistent 5px.
static func _rect_btn_set(b: Button, radius: int = 5) -> void:
	var r := radius
	b.add_theme_stylebox_override("normal", _rect_style(CREAM, PINK_DEEP, 2, r, SHADOW, Vector2(0, 3), 6))
	b.add_theme_stylebox_override("hover", _rect_style(CREAM.lightened(0.06), PINK_DEEP, 2, r, SHADOW_STRONG, Vector2(0, 5), 9))
	b.add_theme_stylebox_override("pressed", _rect_style(CREAM.darkened(0.08), PINK_DEEP, 2, r, Color(0, 0, 0, 0), Vector2.ZERO, 0))
	b.add_theme_stylebox_override("disabled", _rect_style(Color("#E7DCD1"), Color("#CBB2C3"), 2, r, Color(0, 0, 0, 0), Vector2.ZERO, 0))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.set_border_width_all(3)
	focus.border_color = PINK_DEEP
	focus.set_corner_radius_all(r)
	focus.anti_aliasing = true
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_color_override("font_color", TEXT_DARK)
	b.add_theme_color_override("font_hover_color", TEXT_DARK)
	b.add_theme_color_override("font_pressed_color", TEXT_DARK)
	b.add_theme_color_override("font_focus_color", TEXT_DARK)
	b.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	b.add_theme_constant_override("outline_size", 0)
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))


## Legacy signature kept for callers: the pack texture paths are ignored and a
## rectangular code-drawn face is used instead.
static func _btn_set(b: Button, _normal: String, _pressed: String, _m: int, _font_col: Color, _outline: Color, _mod: Color = Color.WHITE) -> void:
	_rect_btn_set(b, 5)


## Small icon TextureRect, optionally parented + placed on a button.
static func icon_rect(path: String, size: float, mod: Color = Color.WHITE) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex(path)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(size, size)
	tr.modulate = mod
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


static func button_icon(b: Button, path: String, size: float = 22.0, mod: Color = Color.WHITE, align: int = 0) -> TextureRect:
	var tr := icon_rect(path, size, mod)
	# Anchor the icon so it stays centred regardless of when the button is laid
	# out (manual positioning ran before the button had a size).
	if align < 0:
		tr.anchor_left = 0.0
		tr.anchor_right = 0.0
		tr.offset_left = 9.0
		tr.offset_right = 9.0 + size
		tr.anchor_top = 0.5
		tr.anchor_bottom = 0.5
		tr.offset_top = -size * 0.5
		tr.offset_bottom = size * 0.5
	elif align > 0:
		tr.anchor_left = 1.0
		tr.anchor_right = 1.0
		tr.offset_left = -(9.0 + size)
		tr.offset_right = -9.0
		tr.anchor_top = 0.5
		tr.anchor_bottom = 0.5
		tr.offset_top = -size * 0.5
		tr.offset_bottom = size * 0.5
	else:
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(tr)
	return tr


# =====================================================================
# motion (fast, non-blocking feedback)
# =====================================================================

static func _scale_to(node: Control, to: Vector2, dur: float, trans: int = Tween.TRANS_BACK, ease: int = Tween.EASE_OUT) -> void:
	if not is_instance_valid(node):
		return
	if reduce_motion():
		node.scale = to   # reduced motion: snap instead of animating
		return
	var prev = node.get_meta("_ui_scale_tw") if node.has_meta("_ui_scale_tw") else null
	if prev is Tween and prev.is_valid():
		prev.kill()
	var tw := node.create_tween()
	node.set_meta("_ui_scale_tw", tw)
	tw.tween_property(node, "scale", to, dur).set_trans(trans).set_ease(ease)


static func _mod_to(node: CanvasItem, to: Color, dur: float) -> void:
	if not is_instance_valid(node):
		return
	var prev = node.get_meta("_ui_mod_tw") if node.has_meta("_ui_mod_tw") else null
	if prev is Tween and prev.is_valid():
		prev.kill()
	var tw := node.create_tween()
	node.set_meta("_ui_mod_tw", tw)
	tw.tween_property(node, "modulate", to, dur).set_trans(Tween.TRANS_SINE)


## Hover/focus pop + press squash for any button.
static func polish_button(btn: Button, pop: float = 1.05) -> void:
	btn.pivot_offset = btn.size * 0.5
	btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)
	btn.mouse_entered.connect(func(): UIUtil._scale_to(btn, Vector2(pop, pop), 0.12))
	btn.focus_entered.connect(func(): UIUtil._scale_to(btn, Vector2(pop, pop), 0.12))
	btn.mouse_exited.connect(func(): UIUtil._scale_to(btn, Vector2.ONE, 0.12, Tween.TRANS_SINE))
	btn.focus_exited.connect(func(): UIUtil._scale_to(btn, Vector2.ONE, 0.12, Tween.TRANS_SINE))
	btn.button_down.connect(func(): UIUtil._scale_to(btn, Vector2(0.94, 0.94), 0.07, Tween.TRANS_SINE))
	btn.button_up.connect(func(): UIUtil._scale_to(btn, Vector2(pop, pop), 0.09))


## Hover pop + brighten for non-button cards (gallery cards, flowchart nodes).
static func hover_scale(c: Control, amount: float = 1.04) -> void:
	c.pivot_offset = c.size * 0.5
	c.resized.connect(func(): c.pivot_offset = c.size * 0.5)
	c.mouse_entered.connect(func():
		UIUtil._scale_to(c, Vector2(amount, amount), 0.12)
		UIUtil._mod_to(c, Color(1.07, 1.07, 1.07), 0.12))
	c.mouse_exited.connect(func():
		UIUtil._scale_to(c, Vector2.ONE, 0.12, Tween.TRANS_SINE)
		UIUtil._mod_to(c, Color.WHITE, 0.12))


## Popup / overlay: fade the dim in, spring the frame.
static func pop_in(overlay: Control, frame: Control = null) -> void:
	if overlay == null:
		return
	overlay.modulate.a = 0.0
	var tw := overlay.create_tween()
	tw.tween_property(overlay, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE)
	if frame != null and is_instance_valid(frame) and not reduce_motion():
		await overlay.get_tree().process_frame
		frame.pivot_offset = frame.size * 0.5
		frame.scale = Vector2(0.94, 0.94)
		frame.create_tween().tween_property(frame, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Stagger a set of freshly-added controls (choice bars, cards).
static func stagger_in(controls: Array, step: float = 0.045) -> void:
	for i in range(controls.size()):
		var c: Control = controls[i]
		if not is_instance_valid(c):
			continue
		if reduce_motion():
			c.modulate.a = 1.0
			c.scale = Vector2.ONE
			continue
		c.modulate.a = 0.0
		c.pivot_offset = c.size * 0.5
		c.scale = Vector2(0.92, 0.92)
		var tw := c.create_tween()
		tw.set_parallel(true)
		tw.tween_property(c, "modulate:a", 1.0, 0.16).set_delay(i * step)
		tw.tween_property(c, "scale", Vector2.ONE, 0.2).set_delay(i * step).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Slide a control up into place (dialogue box per line).
static func slide_up(control: Control, dy: float = 12.0, dur: float = 0.18) -> void:
	if not is_instance_valid(control) or reduce_motion():
		return
	var prev = control.get_meta("_ui_slide_tw") if control.has_meta("_ui_slide_tw") else null
	if prev is Tween and prev.is_valid():
		prev.kill()
	var base: Vector2 = control.position
	control.position = base + Vector2(0.0, dy)
	var tw := control.create_tween()
	control.set_meta("_ui_slide_tw", tw)
	tw.tween_property(control, "position", base, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Full-screen fade-in on scene entry (never blocks input).
static func fade_in(host: Control, color: Color = Color(0.28, 0.15, 0.24, 1.0)) -> void:
	if host == null:
		return
	var r := ColorRect.new()
	r.color = color
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(r)
	var tw := r.create_tween()
	tw.tween_property(r, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(r.queue_free)


## Ornate backing strip behind a label, sized to the text (not the full label
## width) so no end-caps leak out. No layout change.
static func title_strip(label: Control, path: String, pad_x: float = 30.0, pad_y: float = 12.0, mod: Color = Color.WHITE) -> void:
	if label == null:
		return
	var tr := TextureRect.new()
	tr.texture = tex(path)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.modulate = mod
	tr.show_behind_parent = true
	label.add_child(tr)
	var place := func():
		var f: Font = label.get_theme_font("font")
		var fs: int = label.get_theme_font_size("font_size")
		var tw := 200.0
		if f != null and fs > 0:
			tw = f.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var w := tw + pad_x * 2.0
		var h := float(maxi(fs, 1)) + pad_y * 2.0
		tr.size = Vector2(w, h)
		tr.position = Vector2((label.size.x - w) * 0.5, (label.size.y - h) * 0.5)
	place.call()
	label.resized.connect(place)


# =====================================================================
# ornate card internals
# =====================================================================

## Deep-wine rounded frame drawn in code: dashed inner border + heart corner
## ornaments. Children (cream paper insets) draw on top of it.
class FrameCard extends PanelContainer:
	var radius: int = 26
	var frame_col: Color = UIUtil.WINE
	var dash_col: Color = Color(UIUtil.PINK_PALE, 0.55)
	var heart_col: Color = UIUtil.PINK
	var dashed: bool = true
	var hearts: bool = true
	var tex_path: String = UIUtil.TEX_POPUP

	func _ready() -> void:
		# The pack texture IS the frame (composited opaque) — no nested panel.
		var sb := StyleBoxTexture.new()
		sb.texture = UIUtil.opaque_tex(tex_path)
		sb.texture_margin_left = 30
		sb.texture_margin_right = 30
		sb.texture_margin_top = 28
		sb.texture_margin_bottom = 28
		sb.content_margin_left = 0
		sb.content_margin_right = 0
		sb.content_margin_top = 0
		sb.content_margin_bottom = 0
		add_theme_stylebox_override("panel", sb)

	func _draw() -> void:
		pass


## Rounded horizontal-gradient pill painted behind a button (via
## show_behind_parent), so white button text stays crisp on top.
class GradientPill extends Control:
	var col_a: Color = UIUtil.PINK_DEEP
	var col_b: Color = UIUtil.PERIWINKLE
	var radius: float = 29.0
	var alpha: float = 0.92
	var border_col: Color = Color(1, 1, 1, 0.35)
	var border_w: float = 2.0
	var bright: bool = false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		if size.x <= 0.0 or size.y <= 0.0:
			return
		var disabled := false
		var p := get_parent()
		if p is Button:
			disabled = p.disabled
		var ca := col_a
		var cb := col_b
		if bright:
			ca = ca.lightened(0.07)
			cb = cb.lightened(0.07)
		if disabled:
			ca = Color("#cbb7c4")
			cb = Color("#b3a6bd")
		var a: float = alpha if not bright else min(1.0, alpha + 0.06)
		if disabled:
			a = 0.55
		var rect := Rect2(Vector2.ZERO, size)
		var pts := UIUtil._rounded_points(rect, radius, 8)
		var cols := PackedColorArray()
		var w: float = max(1.0, rect.size.x)
		for pt in pts:
			var t: float = clamp((pt.x - rect.position.x) / w, 0.0, 1.0)
			var cc := ca.lerp(cb, t)
			cc.a = a
			cols.append(cc)
		draw_polygon(pts, cols)
		if border_w > 0.0:
			var out := pts.duplicate()
			out.append(pts[0])
			draw_polyline(out, border_col if not disabled else Color(1, 1, 1, 0.15), border_w, true)


## White polka dots on the pastel gradient. Rendered as a single tiled texture
## rather than ~260 per-frame draw_circle calls (that cost ~16k primitives
## every frame; the tile costs 1).
class DotLayer extends Control:
	var tint: Color = Color(1, 1, 1, 0.5)
	var step: float = 64.0
	var dot: float = 4.5

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		var tr := TextureRect.new()
		tr.texture = UIUtil._dot_tile(step, dot, tint)
		tr.stretch_mode = TextureRect.STRETCH_TILE
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tr)


## Pastel confetti (hearts / stars / squares / triangles) drifting gently.
class Confetti extends Control:
	var items: Array = []
	var t: float = 0.0
	var _static_drawn := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _process(delta: float) -> void:
		# Reduce Motion: draw once, then stop animating entirely.
		if UIUtil.reduce_motion():
			if not _static_drawn:
				_static_drawn = true
				queue_redraw()
			return
		_static_drawn = false
		t += delta
		queue_redraw()

	func _draw() -> void:
		for it in items:
			var p: Vector2 = it["p"]
			var y := fposmod(p.y + t * float(it["sp"]), size.y + 80.0) - 40.0
			var x := p.x + sin(t * 0.5 + float(it["ph"])) * 10.0
			UIUtil._draw_shape(self, String(it["k"]), Vector2(x, y), float(it["s"]), it["c"])


# =====================================================================
# primitives
# =====================================================================

## A seamless polka-dot tile (2 rows, alternating offset) for DotLayer.
static func _dot_tile(step: float, radius: float, tint: Color) -> ImageTexture:
	var w := maxi(2, int(round(step)))
	var h := w * 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var centers := [Vector2(step * 0.5, step * 0.5), Vector2(0.0, step * 1.5)]
	for c in centers:
		for dx in [0.0, step, -step]:
			for dy in [0.0, float(h), -float(h)]:
				_stamp_dot(img, c + Vector2(dx, dy), radius, tint)
	return ImageTexture.create_from_image(img)


static func _stamp_dot(img: Image, c: Vector2, r: float, tint: Color) -> void:
	var x0 := int(floor(c.x - r - 1.0))
	var x1 := int(ceil(c.x + r + 1.0))
	var y0 := int(floor(c.y - r - 1.0))
	var y1 := int(ceil(c.y + r + 1.0))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var d := Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(c)
			var a := clampf(r - d + 0.5, 0.0, 1.0) * tint.a
			if a > 0.0:
				img.set_pixel(x, y, Color(tint.r, tint.g, tint.b, a))

static func _rounded_points(rect: Rect2, r: float, seg: int) -> PackedVector2Array:
	r = min(r, min(rect.size.x, rect.size.y) * 0.5)
	var pts := PackedVector2Array()
	var corners := [
		[Vector2(rect.position.x + rect.size.x - r, rect.position.y + r), -PI * 0.5],
		[Vector2(rect.position.x + rect.size.x - r, rect.position.y + rect.size.y - r), 0.0],
		[Vector2(rect.position.x + r, rect.position.y + rect.size.y - r), PI * 0.5],
		[Vector2(rect.position.x + r, rect.position.y + r), PI],
	]
	for cn in corners:
		var c: Vector2 = cn[0]
		var a0: float = cn[1]
		for i in range(seg + 1):
			var a := a0 + (PI * 0.5) * float(i) / float(seg)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


static func _heart(c: Control, center: Vector2, r: float, col: Color) -> void:
	c.draw_circle(center + Vector2(-r * 0.5, -r * 0.32), r * 0.56, col)
	c.draw_circle(center + Vector2(r * 0.5, -r * 0.32), r * 0.56, col)
	c.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-r * 1.04, -r * 0.14),
		center + Vector2(r * 1.04, -r * 0.14),
		center + Vector2(0.0, r * 1.05),
	]), col)


static func _draw_shape(c: Control, kind: String, center: Vector2, r: float, col: Color) -> void:
	match kind:
		"square":
			c.draw_rect(Rect2(center - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), col, true)
		"triangle":
			c.draw_colored_polygon(PackedVector2Array([
				center + Vector2(-r, r * 0.85), center + Vector2(r, r * 0.85), center + Vector2(0, -r)]), col)
		"star":
			var pts := PackedVector2Array()
			for i in range(10):
				var a := -PI * 0.5 + TAU * float(i) / 10.0
				var rr := r if i % 2 == 0 else r * 0.45
				pts.append(center + Vector2(cos(a), sin(a)) * rr)
			c.draw_colored_polygon(pts, col)
		_:
			_heart(c, center, r, col)


static func _dashed_rect(c: Control, rect: Rect2, dash: float, gap: float, col: Color, w: float) -> void:
	var corners := [
		[Vector2(rect.position.x, rect.position.y), Vector2(rect.position.x + rect.size.x, rect.position.y)],
		[Vector2(rect.position.x + rect.size.x, rect.position.y), Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y)],
		[Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y), Vector2(rect.position.x, rect.position.y + rect.size.y)],
		[Vector2(rect.position.x, rect.position.y + rect.size.y), Vector2(rect.position.x, rect.position.y)],
	]
	for seg in corners:
		c.draw_dashed_line(seg[0], seg[1], col, w, dash, true, true)


# =====================================================================
# cards + panels
# =====================================================================

static func panel_style(color: Color, radius: int = 20, border_color: Color = Color(0, 0, 0, 0), border_w: int = 0, shadow: bool = true) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	sb.anti_aliasing_size = 1.0
	if border_w > 0:
		sb.border_color = border_color
		sb.set_border_width_all(border_w)
	if shadow:
		sb.shadow_color = SHADOW
		sb.shadow_size = 8
		sb.shadow_offset = Vector2(0, 4)
	return sb


## Panel skinned directly with a real pack texture (composited opaque) — the
## texture IS the box, so there is no double/nested frame.
static func card_panel(radius: int = 24, border_w: int = 0, tex_path: String = TEX_DIALOGUE) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxTexture.new()
	sb.texture = opaque_tex(tex_path)
	sb.texture_margin_left = 28
	sb.texture_margin_right = 28
	sb.texture_margin_top = 26
	sb.texture_margin_bottom = 26
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	p.add_theme_stylebox_override("panel", sb)
	return p


## Deep-wine rounded frame + dashed inner border + heart corner ornaments,
## with a cream paper inset for content. Returns {frame, inner, content}.
static func frame_card(outer_radius: int = 26, inner_radius: int = 16, tex_path: String = TEX_POPUP) -> Dictionary:
	var frame := FrameCard.new()
	frame.radius = outer_radius
	frame.tex_path = tex_path
	# The texture is the frame; a single padding container holds the content.
	var content := margin(32, 32, 32, 32)
	frame.add_child(content)
	return {"frame": frame, "inner": content, "content": content}


static func margin(l: int = 28, t: int = 24, r: int = 28, b: int = 24) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	return m


# =====================================================================
# buttons
# =====================================================================

## Rectangular menu/popup button (cream face, hot-pink border, dark ink).
## `kind` is kept for call-site compatibility but no longer changes the face.
static func pill_button(text: String, min_w: float = 320, min_h: float = 54, _kind: String = "home") -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, min_h)
	b.clip_text = true
	b.focus_mode = Control.FOCUS_ALL
	_rect_btn_set(b, 5)
	b.add_theme_font_override("font", font_bold())
	b.add_theme_font_size_override("font_size", 20)
	b.mouse_entered.connect(func(): Audio.play_sfx("blip"))
	b.pressed.connect(func(): Audio.play_sfx("click"))
	polish_button(b)
	return b


## Rectangular button with a back-arrow icon (flowchart, gallery, popups).
static func back_button(text: String, min_w: float = 120, min_h: float = 46) -> Button:
	var b := pill_button(text, min_w, min_h)
	button_icon(b, TEX_ICON_BACK, 18.0, Color(WINE, 0.92), -1)
	return b


## Full-width rectangular choice bar (dark ink label). Keeps keyboard focus +
## hover feedback.
static func choice_button(text: String, min_w: float = 640, min_h: float = 64) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, min_h)
	b.clip_text = true
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.focus_mode = Control.FOCUS_ALL
	_rect_btn_set(b, 5)
	b.add_theme_font_override("font", font_bold())
	b.add_theme_font_size_override("font_size", 22)
	b.mouse_entered.connect(func(): Audio.play_sfx("blip"))
	b.pressed.connect(func(): Audio.play_sfx("click"))
	polish_button(b)
	return b


static func button_style(base: Color, hover: Color, pressed: Color, radius: int = 20) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 52)
	b.clip_text = true
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_stylebox_override("normal", panel_style(base, radius, Color(TEXT_DARK, 0.2), 2, true))
	b.add_theme_stylebox_override("hover", panel_style(hover, radius, Color(TEXT_DARK, 0.2), 2, true))
	b.add_theme_stylebox_override("pressed", panel_style(pressed, radius, Color(TEXT_DARK, 0.2), 2, false))
	b.add_theme_stylebox_override("disabled", panel_style(base.darkened(0.12), radius, Color(TEXT_DARK, 0.15), 2, false))
	b.add_theme_stylebox_override("focus", panel_style(hover, radius, PINK, 3, true))
	b.add_theme_color_override("font_color", TEXT_DARK)
	b.add_theme_color_override("font_pressed_color", TEXT_LIGHT)
	b.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	b.add_theme_font_override("font", FONT_UI)
	b.add_theme_font_size_override("font_size", 18)
	return b


## Small round icon button (options/menu) — real Settings gear icon.
static func gear_button() -> Button:
	var b := Button.new()
	b.text = ""
	b.custom_minimum_size = Vector2(46, 46)
	b.clip_text = true
	b.focus_mode = Control.FOCUS_ALL
	_btn_set(b, TEX_REPLY, TEX_REPLY_P, 13, TEXT_LIGHT, Color(WINE, 0.4))
	b.add_theme_font_override("font", FONT_UI)
	b.add_theme_font_size_override("font_size", 22)
	button_icon(b, TEX_ICON_SETTINGS, 24.0, Color(WINE, 0.95), 0)
	polish_button(b, 1.08)
	return b


# =====================================================================
# labels
# =====================================================================

static func heading(text: String, size: int, color: Color = TEXT_DARK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font_semi())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.clip_text = true
	return l


## Big rounded title: white sticker fill + colored outline + soft drop-shadow.
static func title_label(text: String, size: int, color: Color = TEXT_DARK, shadow_color: Color = PINK_DEEP) -> Control:
	var wrap := Control.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tfont := font_bold(true)
	var text_size: Vector2 = tfont.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size) + Vector2(28, 22)

	var shadow := heading(text, size, Color(shadow_color, 0.26))
	shadow.add_theme_font_override("font", tfont)
	shadow.clip_text = false
	shadow.position = Vector2(2, 5)
	shadow.size = text_size
	wrap.add_child(shadow)

	var front := heading(text, size, TEXT_LIGHT)
	front.add_theme_font_override("font", tfont)
	front.clip_text = false
	front.size = text_size
	front.add_theme_constant_override("outline_size", max(4, int(size * 0.28)))
	front.add_theme_color_override("font_outline_color", color)
	wrap.add_child(front)

	wrap.custom_minimum_size = text_size
	return wrap


## Centered `✦ ——— ✦` sparkle rule for name plates.
static func sparkle_rule(color: Color = PINK, line_w: int = 240, glyph_size: int = 18) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var left := heading("✦", glyph_size, color)
	var right := heading("✦", glyph_size, color)
	left.clip_text = false
	right.clip_text = false
	var line := ColorRect.new()
	line.color = Color(color, 0.6)
	line.custom_minimum_size = Vector2(line_w, 2)
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(left)
	row.add_child(line)
	row.add_child(right)
	return row


static func body_label(text: String, size: int = 20, color: Color = TEXT_MUTED) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT_UI)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.clip_text = true
	return l


## Single-line label for tight bars (chapter title, location, HUD).
static func bar_label(text: String, size: int, color: Color, font: Font = FONT_UI) -> Label:
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


# =====================================================================
# backgrounds
# =====================================================================

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


static func _make_confetti(seed_val: int, count: int, colors: Array) -> Confetti:
	var c := Confetti.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var kinds := ["heart", "star", "square", "triangle"]
	for i in range(count):
		c.items.append({
			"p": Vector2(rng.randf_range(0, 1280), rng.randf_range(0, 720)),
			"k": kinds[rng.randi_range(0, 3)],
			"c": colors[rng.randi_range(0, colors.size() - 1)],
			"s": rng.randf_range(7.0, 15.0),
			"sp": rng.randf_range(4.0, 12.0),
			"ph": rng.randf_range(0.0, TAU),
		})
	return c


## White -> pale-pink -> blush gradient + white polka dots + drifting pastel
## confetti (hearts, stars, squares, triangles). Reference title motif.
static func cute_bg() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var grad := Gradient.new()
	grad.set_color(0, Color("#ffffff"))
	grad.add_point(0.42, Color("#ffe4ef"))
	grad.add_point(0.78, Color("#ffd0e4"))
	grad.set_color(1, Color("#f6d7f1"))
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

	var dots := DotLayer.new()
	dots.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dots)

	var conf := _make_confetti(7, 18, [
		Color(0.91, 0.27, 0.49, 0.78),
		Color(0.66, 0.62, 0.85, 0.72),
		Color(0.66, 0.85, 0.94, 0.82),
		Color(0.96, 0.88, 0.54, 0.88),
		Color(0.96, 0.63, 0.72, 0.82),
	])
	root.add_child(conf)
	return root


## Deep-wine -> periwinkle night gradient + soft bokeh + floating stars.
static func dreamy_bg() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var grad := Gradient.new()
	grad.set_color(0, BG_DEEP)
	grad.add_point(0.55, Color("#8E5A8E"))
	grad.set_color(1, Color("#B7A6E6"))
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

	var conf := _make_confetti(23, 16, [
		Color(1, 1, 1, 0.5),
		Color(0.96, 0.63, 0.72, 0.55),
		Color(0.96, 0.88, 0.54, 0.5),
	])
	root.add_child(conf)
	_add_decor(root, Color(PINK, 0.26), 8, ["✦", "✧", "·"])
	return root


static func heart_pattern(tint: Color = Color(PINK, 0.14)) -> Control:
	var wrap := Control.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_decor(wrap, tint, 9)
	return wrap


## Scatter bokeh dots + soft hearts and float them gently.
static func _add_decor(root: Control, tint: Color, count: int, glyphs: Array = ["♥", "✿", "✦", "·"]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var moving: Array = []
	for i in range(count):
		var node := Label.new()
		node.text = glyphs[rng.randi_range(0, glyphs.size() - 1)]
		node.add_theme_font_override("font", FONT_UI)
		node.add_theme_font_size_override("font_size", rng.randi_range(16, 40))
		node.add_theme_color_override("font_color", tint)
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.position = Vector2(rng.randf_range(-20, 1260), rng.randf_range(-20, 720))
		root.add_child(node)
		moving.append(node)

	root.tree_entered.connect(func():
		if UIUtil.reduce_motion():
			return
		for node in moving:
			var base_y: float = node.position.y
			var tw: Tween = node.create_tween().set_loops()
			tw.set_parallel(false)
			tw.tween_property(node, "position:y", base_y - rng.randf_range(10, 22), rng.randf_range(2.6, 4.4)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(node, "position:y", base_y, rng.randf_range(2.6, 4.4)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	)


# =====================================================================
# popups
# =====================================================================

## Full-screen soft dim + centered ornate card (cream paper inset) skinned
## with the real popup texture. Returns {overlay, vbox}. Fades + springs in.
static func popup(title: String, tex_path: String = TEX_POPUP) -> Dictionary:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(WINE, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var fc := frame_card(30, 18, tex_path)
	var frame: PanelContainer = fc["frame"]
	frame.custom_minimum_size = Vector2(440, 0)
	center.add_child(frame)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	fc["content"].add_child(vbox)

	if title != "":
		var h := heading(title, 30, WINE)
		vbox.add_child(h)
		title_strip(h, TEX_TEXTBOX)
		vbox.add_child(sparkle_rule(PINK_DEEP, 200))

	overlay.tree_entered.connect(func(): pop_in(overlay, frame))

	return {"overlay": overlay, "vbox": vbox}


# =====================================================================
# save slots + volume
# =====================================================================

## One pack-skinned save/load slot card.
static func slot_button(idx: int, exists: bool, chapter_title: String, when_text: String, enabled: bool = true) -> Button:
	var b := Button.new()
	var subtitle := chapter_title if exists else "— empty —"
	var lines := ["Slot %d" % idx, subtitle]
	if exists and when_text != "":
		lines.append(when_text)
	b.text = "\n".join(lines)
	b.custom_minimum_size = Vector2(288, 144)
	b.clip_text = true
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.disabled = not enabled
	b.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var fill := PINK_PALE if exists else Color("#F7EEF3")
	b.add_theme_stylebox_override("normal", _rect_style(fill, PINK_DEEP, 2, 5, SHADOW, Vector2(0, 3), 6))
	b.add_theme_stylebox_override("hover", _rect_style(fill.lightened(0.06), PINK_DEEP, 2, 5, SHADOW_STRONG, Vector2(0, 5), 9))
	b.add_theme_stylebox_override("pressed", _rect_style(fill.darkened(0.09), PINK_DEEP, 2, 5, Color(0, 0, 0, 0), Vector2.ZERO, 0))
	b.add_theme_stylebox_override("disabled", _rect_style(Color("#E7DCD1"), Color("#CBB2C3"), 2, 5, Color(0, 0, 0, 0), Vector2.ZERO, 0))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.set_border_width_all(3)
	focus.border_color = PINK_DEEP
	focus.set_corner_radius_all(5)
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_color_override("font_color", TEXT_DARK)
	b.add_theme_color_override("font_hover_color", TEXT_DARK)
	b.add_theme_color_override("font_pressed_color", TEXT_DARK)
	b.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	b.add_theme_color_override("font_focus_color", TEXT_DARK)
	b.add_theme_font_override("font", font_semi())
	b.add_theme_font_size_override("font_size", 18)
	polish_button(b)
	return b


static func slot_grid(slots: Array, on_pick: Callable, load_mode: bool) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for i in range(6):
		var info: Dictionary = slots[i] if i < slots.size() else {"exists": false, "title": "", "when": ""}
		var enabled: bool = bool(info.get("exists", false)) or not load_mode
		var btn := slot_button(i + 1, info.get("exists", false), info.get("title", ""), info.get("when", ""), enabled)
		btn.pressed.connect(on_pick.bind(i + 1))
		grid.add_child(btn)
	return grid


static func volume_row(bus_name: String = "Master") -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

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
	# Pack slider art recoloured to the palette: pink fill + round pink knob.
	slider.custom_minimum_size = Vector2(180, 26)
	slider.add_theme_stylebox_override("slider", tex_panel(TEX_VOL_EMPTY, 8, 6, Color("#F2D9CB")))
	var pink_fill := recolor_tex(TEX_VOL_FILL, PINK_DEEP)
	if pink_fill != null:
		slider.add_theme_stylebox_override("grabber_area", tex_panel_tex(pink_fill, 6, 5))
		slider.add_theme_stylebox_override("grabber_area_highlight", tex_panel_tex(pink_fill, 6, 5))
	var knob := recolor_tex(TEX_VOL_KNOB, PINK_DEEP, 24, 24)
	if knob != null:
		slider.add_theme_icon_override("grabber", knob)
		slider.add_theme_icon_override("grabber_highlight", knob)
	row.add_child(slider)

	# Row frame (real Settings pack containers) drawn behind the row.
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", panel_style(Color("#F7D9E9"), 10, Color(PINK_DEEP, 0.20), 1, false))
	frame.add_child(row)
	return frame


static func volume_row_music() -> Control:
	return volume_row("Music")

static func volume_row_sfx() -> Control:
	return volume_row("SFX")


# =====================================================================
# display / fullscreen
# =====================================================================

const SETTINGS_PATH := "user://settings.cfg"


static func is_fullscreen() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return false
	return bool(cfg.get_value("display", "fullscreen", false))


static func _apply_fullscreen_mode(on: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)


## Apply + persist the fullscreen choice.
static func set_fullscreen(on: bool) -> void:
	_apply_fullscreen_mode(on)
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)  # keep any other stored keys
	cfg.set_value("display", "fullscreen", on)
	cfg.save(SETTINGS_PATH)


static func toggle_fullscreen() -> bool:
	var on := not is_fullscreen()
	set_fullscreen(on)
	return on


## Restore the saved display mode at scene startup.
static func apply_saved_display() -> void:
	_apply_fullscreen_mode(is_fullscreen())


## F11 / Alt+Enter. Returns true when the event was consumed.
static func handle_fullscreen_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			if k.keycode == KEY_F11 or (k.alt_pressed and (k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER)):
				toggle_fullscreen()
				return true
	return false


## Two-state Settings row for the Display group (Windowed ↔ Fullscreen).
static func fullscreen_row() -> Control:
	return window_mode_row()


# =====================================================================
# settings store (user://settings.cfg) + read-line tracking
# =====================================================================

const READ_LINES_PATH := "user://read_lines.cfg"

const TEXT_SPEED_MIN := 0.25
const TEXT_SPEED_MAX := 8.0
const TEXT_SPEED_DEFAULT := 1.0
const AUTO_DELAY_MIN := 0.5
const AUTO_DELAY_MAX := 6.0
const AUTO_DELAY_DEFAULT := 2.2
const BOX_OPACITY_MIN := 0.7    # below this the dark body text loses contrast
const BOX_OPACITY_MAX := 1.0
const BOX_OPACITY_DEFAULT := 1.0

const SKIP_OFF := 0
const SKIP_READ := 1
const SKIP_ALL := 2

static var _settings_cache: Dictionary = {}
static var _settings_loaded := false
static var _box_opacity_hook: Callable = Callable()


static func _settings() -> Dictionary:
	if not _settings_loaded:
		_settings_cache = {}
		var cfg := ConfigFile.new()
		if cfg.load(SETTINGS_PATH) == OK:
			for section in cfg.get_sections():
				for key in cfg.get_section_keys(section):
					_settings_cache["%s/%s" % [section, key]] = cfg.get_value(section, key)
		_settings_loaded = true
	return _settings_cache


## Drop the cache and re-read settings.cfg (used by tests / external edits).
static func reload_settings() -> void:
	_settings_loaded = false
	_settings_cache = {}
	_settings()


static func _get_setting(section: String, key: String, def: Variant) -> Variant:
	var c := _settings()
	var k := "%s/%s" % [section, key]
	return c[k] if c.has(k) else def


static func _set_setting(section: String, key: String, value: Variant) -> void:
	_settings()["%s/%s" % [section, key]] = value
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)  # keep unrelated keys
	cfg.set_value(section, key, value)
	cfg.save(SETTINGS_PATH)


# --- box opacity -----------------------------------------------------------

static func clamp_box_opacity(v: float) -> float:
	return clampf(v, BOX_OPACITY_MIN, BOX_OPACITY_MAX)


static func get_box_opacity() -> float:
	return clamp_box_opacity(float(_get_setting("display", "box_opacity", BOX_OPACITY_DEFAULT)))


static func set_box_opacity(v: float) -> void:
	var clamped := clamp_box_opacity(v)
	_set_setting("display", "box_opacity", clamped)
	if _box_opacity_hook.is_valid():
		_box_opacity_hook.call(clamped)


## The live dialogue box registers itself here so the slider updates it.
static func set_box_opacity_hook(cb: Callable) -> void:
	_box_opacity_hook = cb


# --- text speed / auto delay / skip mode -----------------------------------

static func clamp_text_speed(v: float) -> float:
	return clampf(v, TEXT_SPEED_MIN, TEXT_SPEED_MAX)


static func get_text_speed() -> float:
	return clamp_text_speed(float(_get_setting("text", "speed", TEXT_SPEED_DEFAULT)))


static func set_text_speed(v: float) -> void:
	_set_setting("text", "speed", clamp_text_speed(v))


## The top of the slider means "instant".
static func is_text_instant() -> bool:
	return get_text_speed() >= TEXT_SPEED_MAX - 0.001


static func get_auto_delay() -> float:
	return clampf(float(_get_setting("text", "auto_delay", AUTO_DELAY_DEFAULT)), AUTO_DELAY_MIN, AUTO_DELAY_MAX)


static func set_auto_delay(v: float) -> void:
	_set_setting("text", "auto_delay", clampf(v, AUTO_DELAY_MIN, AUTO_DELAY_MAX))


static func get_skip_mode() -> int:
	return clampi(int(_get_setting("text", "skip_mode", SKIP_OFF)), 0, 2)


static func set_skip_mode(m: int) -> void:
	_set_setting("text", "skip_mode", clampi(m, 0, 2))


static func skip_mode_label(m: int) -> String:
	match m:
		SKIP_READ: return "Skip read"
		SKIP_ALL: return "Skip all"
		_: return "Off"


# --- accessibility ---------------------------------------------------------

const KEY_LARGE_TEXT := "access/large_text"
const KEY_REDUCE_MOTION := "access/reduce_motion"

static var _settings_hook: Callable = Callable()


static func get_large_text() -> bool:
	return bool(_get_setting("access", "large_text", false))


static func set_large_text(on: bool) -> void:
	_set_setting("access", "large_text", on)
	notify_settings_changed()


static func get_reduce_motion() -> bool:
	return bool(_get_setting("access", "reduce_motion", false))


static func set_reduce_motion(on: bool) -> void:
	_set_setting("access", "reduce_motion", on)
	notify_settings_changed()


## Cheap per-frame check used by the decor / motion helpers.
static func reduce_motion() -> bool:
	var c := _settings()
	return bool(c[KEY_REDUCE_MOTION]) if c.has(KEY_REDUCE_MOTION) else false


## Scenes with live UI register here so settings re-apply immediately.
static func set_settings_hook(cb: Callable) -> void:
	_settings_hook = cb


static func notify_settings_changed() -> void:
	if _settings_hook.is_valid():
		_settings_hook.call()


# --- read-line tracking (own store, never touches saves) -------------------

static var _read_lines: Dictionary = {}
static var _read_loaded := false
static var _read_dirty := false
static var _read_saved_ms := 0


static func _read_store() -> Dictionary:
	if not _read_loaded:
		_read_lines = {}
		var cfg := ConfigFile.new()
		if cfg.load(READ_LINES_PATH) == OK:
			for key in cfg.get_section_keys("read"):
				if bool(cfg.get_value("read", key, false)):
					_read_lines[key] = true
		_read_loaded = true
	return _read_lines


static func _read_key(chapter_id: String, line_idx: int) -> String:
	return "%s.%d" % [chapter_id, line_idx]


static func is_line_read(chapter_id: String, line_idx: int) -> bool:
	if chapter_id == "":
		return false
	return _read_store().has(_read_key(chapter_id, line_idx))


static func mark_line_read(chapter_id: String, line_idx: int) -> void:
	if chapter_id == "":
		return
	var store := _read_store()
	var k := _read_key(chapter_id, line_idx)
	if store.has(k):
		return
	store[k] = true
	_read_dirty = true
	# Throttle disk writes; skip-all can mark lines very quickly.
	if Time.get_ticks_msec() - _read_saved_ms > 1000:
		flush_read_lines()


static func flush_read_lines() -> void:
	if not _read_dirty:
		return
	var cfg := ConfigFile.new()
	cfg.load(READ_LINES_PATH)
	for k in _read_store().keys():
		cfg.set_value("read", String(k), true)
	cfg.save(READ_LINES_PATH)
	_read_dirty = false
	_read_saved_ms = Time.get_ticks_msec()


static func reset_read_lines() -> void:
	_read_lines = {}
	_read_loaded = true
	_read_dirty = true
	flush_read_lines()


# =====================================================================
# settings rows (grouped)
# =====================================================================

static func _group_label(t: String) -> Control:
	var l := heading(t, 16, WINE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.clip_text = false
	return l


static func _row_label(t: String) -> Label:
	var l := body_label(t, 20, TEXT_DARK)
	l.custom_minimum_size = Vector2(160, 0)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


static func _value_label(t: String = "") -> Label:
	var l := body_label(t, 18, TEXT_MUTED)
	l.custom_minimum_size = Vector2(58, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.clip_text = false
	return l


static func _framed_row(row: Control, _frame_tex: String) -> Control: # _frame_tex is ignored
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", panel_style(Color("#F7D9E9"), 10, Color(PINK_DEEP, 0.20), 1, false))
	frame.add_child(row)
	return frame


static func _pink_slider(mn: float, mx: float, step: float, val: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = mn
	slider.max_value = mx
	slider.step = step
	slider.custom_minimum_size = Vector2(140, 26)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value = val
	slider.add_theme_stylebox_override("slider", tex_panel(TEX_VOL_EMPTY, 8, 6, Color("#F2D9CB")))
	var pink_fill := recolor_tex(TEX_VOL_FILL, PINK_DEEP)
	if pink_fill != null:
		slider.add_theme_stylebox_override("grabber_area", tex_panel_tex(pink_fill, 6, 5))
		slider.add_theme_stylebox_override("grabber_area_highlight", tex_panel_tex(pink_fill, 6, 5))
	var knob := recolor_tex(TEX_VOL_KNOB, PINK_DEEP, 24, 24)
	if knob != null:
		slider.add_theme_icon_override("grabber", knob)
		slider.add_theme_icon_override("grabber_highlight", knob)
	return slider


## Display: Windowed ↔ Fullscreen (persisted, same hotkeys).
static func window_mode_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_row_label("Window Mode"))

	var btn := pill_button("", 140, 40)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var refresh := func() -> void:
		btn.text = "Fullscreen" if is_fullscreen() else "Windowed"
	refresh.call()
	btn.pressed.connect(func():
		toggle_fullscreen()
		refresh.call())
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(btn)
	return _framed_row(row, TEX_SOUND_VOL)


## Display: dialogue box opacity, applied live and clamped readable.
static func box_opacity_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_row_label("Box Opacity"))

	var val := _value_label()
	var slider := _pink_slider(BOX_OPACITY_MIN, BOX_OPACITY_MAX, 0.05, get_box_opacity())
	var refresh := func(v: float) -> void:
		val.text = "%d%%" % int(round(v * 100.0))
	refresh.call(slider.value)
	slider.value_changed.connect(func(v: float):
		set_box_opacity(v)
		refresh.call(v))
	row.add_child(slider)
	row.add_child(val)
	return _framed_row(row, TEX_SOUND_VOL)


## Text: typewriter rate (top of the slider = instant).
static func text_speed_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_row_label("Text Speed"))

	var val := _value_label()
	var slider := _pink_slider(TEXT_SPEED_MIN, TEXT_SPEED_MAX, 0.25, get_text_speed())
	var refresh := func(v: float) -> void:
		val.text = "Instant" if v >= TEXT_SPEED_MAX - 0.001 else ("%.2fx" % v)
	refresh.call(slider.value)
	slider.value_changed.connect(func(v: float):
		set_text_speed(v)
		refresh.call(v))
	row.add_child(slider)
	row.add_child(val)
	return _framed_row(row, TEX_SOUND_VOL)


## Text: auto-advance delay.
static func auto_speed_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_row_label("Auto-Mode Speed"))

	var val := _value_label()
	var slider := _pink_slider(AUTO_DELAY_MIN, AUTO_DELAY_MAX, 0.1, get_auto_delay())
	var refresh := func(v: float) -> void:
		val.text = "%.1fs" % v
	refresh.call(slider.value)
	slider.value_changed.connect(func(v: float):
		set_auto_delay(v)
		refresh.call(v))
	row.add_child(slider)
	row.add_child(val)
	return _framed_row(row, TEX_SOUND_VOL)


## Text: three-state skip control (Off → Skip read → Skip all).
static func skip_mode_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_row_label("Skip Mode"))

	var btn := pill_button("", 140, 40)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var refresh := func() -> void:
		btn.text = skip_mode_label(get_skip_mode())
	refresh.call()
	btn.pressed.connect(func():
		set_skip_mode((get_skip_mode() + 1) % 3)
		refresh.call())
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(btn)
	return _framed_row(row, TEX_SOUND_VOL)


## Generic two-state row (label + On/Off button), same frames as the rest.
static func _toggle_row(label_text: String, is_on: Callable, on_press: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_row_label(label_text))

	var btn := pill_button("", 140, 40)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var refresh := func() -> void:
		btn.text = "On" if bool(is_on.call()) else "Off"
	refresh.call()
	btn.pressed.connect(func():
		on_press.call()
		refresh.call())
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(btn)
	return _framed_row(row, TEX_SOUND_VOL)


## Accessibility: larger dialogue text (body 30 → 34, name 26 → 30).
static func large_text_row() -> Control:
	return _toggle_row(
		"Large Text",
		func() -> bool: return get_large_text(),
		func() -> void: set_large_text(not get_large_text()))


## Accessibility: minimal decorative motion.
static func reduce_motion_row() -> Control:
	return _toggle_row(
		"Reduce Motion",
		func() -> bool: return get_reduce_motion(),
		func() -> void: set_reduce_motion(not get_reduce_motion()))


## The grouped settings body (Display + Text | Audio + Accessibility).
static func settings_content() -> Control:
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.add_child(_group_label("Display"))
	left.add_child(window_mode_row())
	left.add_child(box_opacity_row())
	left.add_child(_group_label("Text"))
	left.add_child(text_speed_row())
	left.add_child(auto_speed_row())
	left.add_child(skip_mode_row())
	cols.add_child(left)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	right.add_child(_group_label("Audio"))
	right.add_child(volume_row("Master"))
	right.add_child(volume_row("Music"))
	right.add_child(volume_row("SFX"))
	right.add_child(_group_label("Accessibility"))
	right.add_child(large_text_row())
	right.add_child(reduce_motion_row())
	cols.add_child(right)

	return cols


## Ready-to-add Settings overlay (title + groups + Close). Caller adds it.
static func settings_overlay() -> Control:
	var p := popup("Settings", TEX_SETTINGS_BG)
	var vbox: VBoxContainer = p["vbox"]
	vbox.add_child(settings_content())
	var close_btn := pill_button("Close", 300, 48)
	close_btn.pressed.connect(func(): p["overlay"].queue_free())
	vbox.add_child(close_btn)
	return p["overlay"]


static func route_color(route: String) -> Color:
	match route:
		"arthur": return SKY
		"dante": return BUTTER
		"leo": return LAVENDER
		_: return PINK_DEEP


## Focus the first usable Button under `root` so menus and popups are
## keyboard/gamepad navigable (arrow keys + Enter) without a mouse.
static func focus_first(root: Node) -> void:
	var btns := root.find_children("*", "Button", true, false)
	for b in btns:
		if b is Button and not b.disabled and b.focus_mode != Control.FOCUS_NONE:
			b.grab_focus.call_deferred()
			return


# =====================================================================
# hearts (affection HUD)
# =====================================================================

## One affection heart: filled = the pack heart tinted to the character colour;
## empty = a crisp code-drawn outline on the wine bar.
class HeartSlot extends Control:
	var filled: bool = false
	var col: Color = Color.WHITE
	var outline_col: Color = Color(1, 1, 1, 0.9)
	var icon: TextureRect

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon = TextureRect.new()
		icon.texture = UIUtil.tex(UIUtil.TEX_ICON_HEART_PINK)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(icon)

	func apply_state() -> void:
		icon.visible = filled
		icon.modulate = col
		queue_redraw()

	func _draw() -> void:
		if filled or size.x <= 0.0:
			return
		# Parametric heart outline, scaled to leave the same margin as the icon.
		var s: float = min(size.x / 32.0, size.y / 30.0) * 0.87
		var c := size * 0.5 + Vector2(0.0, -2.5 * s)
		var pts := PackedVector2Array()
		for i in range(65):
			var t := TAU * float(i) / 64.0
			var x := 16.0 * pow(sin(t), 3.0)
			var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
			pts.append(c + Vector2(x, -y) * s)
		draw_polyline(pts, outline_col, 1.6, true)


## A row of `count` affection hearts. Returns {row, icons}.
static func heart_row(count: int = 5, filled: int = 0, color: Color = Color.WHITE, size: float = 16.0) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var icons: Array = []
	for i in range(count):
		var slot := HeartSlot.new()
		slot.custom_minimum_size = Vector2(size, size)
		row.add_child(slot)
		icons.append(slot)
	_fill_hearts(icons, filled, color)
	return {"row": row, "icons": icons}


static func _fill_hearts(icons: Array, filled: int, color: Color) -> void:
	for i in range(icons.size()):
		var slot: HeartSlot = icons[i]
		slot.filled = i < filled
		slot.col = color
		slot.outline_col = Color(CREAM, 0.9)
		slot.apply_state()


## Update an existing heart row (from heart_row) and pop the newly-filled one.
static func set_hearts(icons: Array, filled: int, color: Color, animate: bool = true) -> void:
	var before := 0
	for slot in icons:
		if slot.filled:
			before += 1
	_fill_hearts(icons, filled, color)
	if animate and filled > before:
		for i in range(before, min(filled, icons.size())):
			var slot: Control = icons[i]
			slot.pivot_offset = slot.size * 0.5
			slot.scale = Vector2(0.4, 0.4)
			var tw := slot.create_tween()
			tw.tween_property(slot, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# =====================================================================
# affection toast
# =====================================================================

static var _toast_ref: WeakRef = null


## Brief floating "+3 ♥ ARTHUR" toast under the top bar. Any toast still on
## screen is replaced so rapid changes can't pile up. Never blocks input.
static func affection_toast(host: Control, char_color: Color, delta: int, char_name: String) -> void:
	if host == null or delta == 0:
		return
	if _toast_ref != null:
		var prev = _toast_ref.get_ref()
		if prev != null and is_instance_valid(prev):
			prev.queue_free()
	_toast_ref = null

	var accent := PINK_DEEP if delta > 0 else WINE
	var num_col := char_color if delta > 0 else WINE

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _rect_style(CREAM, PINK_DEEP, 2, 8, SHADOW_STRONG, Vector2(0, 3), 8))

	var m := margin(14, 6, 14, 6)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(m)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(hb)

	var num := Label.new()
	num.text = ("+%d" % delta) if delta > 0 else ("-%d" % absi(delta))
	num.add_theme_font_override("font", font_bold())
	num.add_theme_font_size_override("font_size", 22)
	num.add_theme_color_override("font_color", num_col)
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(num)

	var heart := Label.new()
	heart.text = "♥"
	heart.add_theme_font_override("font", font_bold())
	heart.add_theme_font_size_override("font_size", 20)
	heart.add_theme_color_override("font_color", accent)
	heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(heart)

	var who := Label.new()
	who.text = char_name.to_upper()
	who.add_theme_font_override("font", font_semi())
	who.add_theme_font_size_override("font_size", 20)
	who.add_theme_color_override("font_color", TEXT_DARK)
	who.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(who)

	# Sits just below the top bar, centred — clear of the title, location and
	# heart groups, and centred so it can't reach the portrait lane.
	var holder := CenterContainer.new()
	holder.anchor_left = 0.0
	holder.anchor_right = 1.0
	holder.anchor_top = 0.0
	holder.anchor_bottom = 0.0
	holder.offset_top = 84
	holder.offset_bottom = 132
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(panel)
	host.add_child(holder)
	_toast_ref = weakref(holder)

	# Fade + drift up, hold ~0.6s, fade out. ~1.1s total, non-blocking.
	holder.modulate.a = 0.0
	var base_y := holder.position.y
	if reduce_motion():
		# Reduced motion: appear and fade in place, no drift.
		var tws := holder.create_tween()
		tws.tween_property(holder, "modulate:a", 1.0, 0.12)
		tws.tween_interval(0.8)
		tws.tween_property(holder, "modulate:a", 0.0, 0.2)
		tws.tween_callback(holder.queue_free)
		return
	holder.position.y = base_y + 10.0
	var tw := holder.create_tween()
	tw.tween_property(holder, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(holder, "position:y", base_y, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.55)
	tw.tween_property(holder, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(holder, "position:y", base_y - 18.0, 0.3).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(holder.queue_free)
