extends Control
## The main gameplay screen: renders chapters line-by-line with a typewriter
## effect, shows a code-drawn backdrop + speaker portrait, plays per-chapter
## BGM and gameplay SFX, tracks affection/ranks, and presents branching
## choices (with affection/flag gating).

var chapter_id: String = ""
var chapter: Dictionary = {}
var line_idx: int = 0

var is_typing: bool = false
var full_text: String = ""
var char_idx: int = 0
var type_speed: float = 0.018

var bg_rect: ColorRect
var bg_art: Control
var top_panel: PanelContainer
var title_label: Label
var location_label: Label
var bgm_label: Label
var speaker_label: Label
var speaker_plate: PanelContainer
var hint_wrap: Control
var text_label: RichTextLabel
var choice_box: VBoxContainer
var continue_hint: Label
var hearts_box: HBoxContainer
var heart_labels: Dictionary = {}
var num_labels: Dictionary = {}
var rank_labels: Dictionary = {}
var dialogue_panel: PanelContainer
var _dmargin: MarginContainer
var click_catcher: Control
var portrait_holder: Control
var portrait_node: Control
var ff_btn: Button
var auto_btn: Button
var log_btn: Button

var type_timer: Timer
var speed_mult: float = 1.0  # fast-forward multiplier (Timer has no speed_scale in 4.7)
var auto_mode: bool = false
var _last_skip_ms: int = 0  # throttle for the Ctrl-hold skip

# Line history for the dialogue log.
var history: Array = []
var _history_keys: Dictionary = {}

# Modal popup tracking so keyboard input doesn't advance dialogue behind it.
var modal: Control = null

# Minigame trigger state (set from the chapter's optional "minigame" key).
var _mg_active: bool = false
var _mg_attempts: int = 0
var _mg_cfg: Dictionary = {}
var _mg_retry_open: bool = false

# Cached affection values so points_changed can detect gains (chime SFX).
var _last_points: Dictionary = {}

# Scene transition: fade to black, show a location/time card, fade back in.
var transition_overlay: ColorRect
var transition_card: VBoxContainer
var card_place: Label
var card_time: Label
var transition_tween: Tween
var transitioning: bool = false
var _last_location: String = ""


## Tiny pixel-art icon drawn with vector rects — floppy disk (save), folder
## (load), double fast-forward triangles, chat lines (log).
class PixelIcon:
	extends Control
	var kind: String = "save"
	var icon_col: Color = UIUtil.TEXT_DARK

	func _draw() -> void:
		var s := size
		match kind:
			"save":  # floppy disk: outline body + inset shutter + label
				draw_rect(Rect2(Vector2.ZERO, s), icon_col, false, 2.0)
				draw_rect(Rect2(Vector2(s.x * 0.5, s.y * 0.15), Vector2(s.x * 0.3, s.y * 0.25)), icon_col, true)
				draw_rect(Rect2(Vector2(s.x * 0.2, s.y * 0.55), Vector2(s.x * 0.6, s.y * 0.25)), icon_col, true)
			"load":  # folder: outline body + tab
				draw_rect(Rect2(Vector2(0, s.y * 0.25), Vector2(s.x, s.y * 0.65)), icon_col, false, 2.0)
				draw_rect(Rect2(Vector2(s.x * 0.1, s.y * 0.05), Vector2(s.x * 0.4, s.y * 0.25)), icon_col, true)
			"ff":  # double fast-forward triangles
				draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(0, s.y), Vector2(s.x * 0.42, s.y / 2.0)]), icon_col)
				draw_colored_polygon(PackedVector2Array([Vector2(s.x * 0.55, 0), Vector2(s.x * 0.55, s.y), Vector2(s.x, s.y / 2.0)]), icon_col)
			"log":  # three stacked chat lines
				draw_rect(Rect2(Vector2(0, s.y * 0.1), Vector2(s.x, 2.0)), icon_col, true)
				draw_rect(Rect2(Vector2(0, s.y * 0.45), Vector2(s.x * 0.8, 2.0)), icon_col, true)
				draw_rect(Rect2(Vector2(0, s.y * 0.8), Vector2(s.x * 0.6, 2.0)), icon_col, true)
			"auto":  # play triangle with a pause bar
				draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(0, s.y), Vector2(s.x * 0.6, s.y / 2.0)]), icon_col)
				draw_rect(Rect2(Vector2(s.x * 0.75, 0), Vector2(s.x * 0.2, s.y)), icon_col, true)


## Center a PixelIcon of the given kind on a square-ish button.
func _add_icon(btn: Button, kind: String) -> void:
	var icon := PixelIcon.new()
	icon.kind = kind
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size = Vector2(18, 18)
	icon.position = (btn.custom_minimum_size - icon.size) / 2.0
	btn.add_child(icon)


func _ready() -> void:
	UIUtil.apply_saved_display()
	UIUtil.set_box_opacity_hook(Callable(self, "_apply_box_opacity"))
	UIUtil.set_settings_hook(Callable(self, "_apply_accessibility"))
	_build_ui()
	_apply_box_opacity(UIUtil.get_box_opacity())
	_apply_accessibility()
	GameState.points_changed.connect(_on_points_changed)
	_last_points = GameState.points.duplicate()
	_load_chapter(GameState.current_chapter_id, GameState.current_line_idx)
	UIUtil.fade_in(self)


func _build_ui() -> void:
	bg_rect = ColorRect.new()
	bg_rect.color = Color("#eee1d3")
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)

	# Code-drawn pixel-art backdrop (sits above the flat tint).
	bg_art = Control.new()
	bg_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_art)

	# ---- Click catcher (advances dialogue when clicking the scene) ----
	click_catcher = Control.new()
	click_catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_catcher.mouse_filter = Control.MOUSE_FILTER_PASS
	click_catcher.gui_input.connect(_on_scene_input)
	add_child(click_catcher)

	# ---- Speaker portrait: bottom-left, waist cut by the screen's bottom edge.
	# One holder for every character → identical scale + baseline. Height is
	# 82% of the viewport (anchors), width a fixed 320px lane; both track
	# window resizes. Real PNG portraits fill this holder; the drawn fallback
	# keeps its own box.
	portrait_holder = Control.new()
	portrait_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_holder.anchor_left = 0.0
	portrait_holder.anchor_right = 0.0
	portrait_holder.anchor_top = 0.18
	portrait_holder.anchor_bottom = 1.0
	portrait_holder.offset_left = 56
	portrait_holder.offset_right = 56 + 420
	portrait_holder.offset_top = 0
	portrait_holder.offset_bottom = 0
	portrait_holder.visible = false
	add_child(portrait_holder)

	# ---- Top bar ----
	top_panel = PanelContainer.new()
	top_panel.add_theme_stylebox_override("panel", UIUtil.panel_style(Color(UIUtil.WINE, 0.92), 0, Color(0, 0, 0, 0), 0, false))
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_panel.clip_contents = true
	add_child(top_panel)

	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 20)
	top_margin.add_theme_constant_override("margin_right", 20)
	top_margin.add_theme_constant_override("margin_top", 10)
	top_margin.add_theme_constant_override("margin_bottom", 10)
	top_panel.add_child(top_margin)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 16)
	top_margin.add_child(top_row)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.clip_contents = true
	top_row.add_child(title_col)

	title_label = UIUtil.bar_label("", 20, UIUtil.CREAM, UIUtil.font_semi(true))
	title_col.add_child(title_label)

	var sub_row := HBoxContainer.new()
	sub_row.add_theme_constant_override("separation", 10)
	sub_row.clip_contents = true
	title_col.add_child(sub_row)
	location_label = UIUtil.bar_label("", 18, Color(UIUtil.CREAM, 0.95))
	sub_row.add_child(location_label)
	bgm_label = UIUtil.bar_label("", 18, Color(UIUtil.GOLD, 0.9))
	bgm_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	sub_row.add_child(bgm_label)

	hearts_box = HBoxContainer.new()
	hearts_box.add_theme_constant_override("separation", 16)
	top_row.add_child(hearts_box)
	_build_hearts()

	# ---- Fixed dialogue box (opaque cream panel), bottom-wide. Name in pink
	# Baloo2 above a ✦ ——— ✦ rule; dark body text on the panel surface. ----
	dialogue_panel = UIUtil.card_panel(24, 3)
	dialogue_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_panel.offset_left = 40
	dialogue_panel.offset_right = -40
	dialogue_panel.offset_bottom = -30
	dialogue_panel.offset_top = -280
	add_child(dialogue_panel)

	_dmargin = MarginContainer.new()
	_dmargin.add_theme_constant_override("margin_left", 28)
	_dmargin.add_theme_constant_override("margin_right", 28)
	_dmargin.add_theme_constant_override("margin_top", 6)
	_dmargin.add_theme_constant_override("margin_bottom", 6)
	dialogue_panel.add_child(_dmargin)

	# Stage lets the text block and the quick-button row be placed
	# independently: text fills the top, buttons pin to the panel's bottom
	# padding so they can never be clipped by the window edge.
	var stage := Control.new()
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dmargin.add_child(stage)

	var dvbox := VBoxContainer.new()
	dvbox.anchor_right = 1.0
	dvbox.offset_bottom = -50
	dvbox.add_theme_constant_override("separation", 4)
	stage.add_child(dvbox)

	var name_row := HBoxContainer.new()
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dvbox.add_child(name_row)

	# Transparent plate keeps the name centered; identity comes from the portrait.
	speaker_plate = PanelContainer.new()
	speaker_plate.add_theme_stylebox_override("panel", UIUtil.panel_style(Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0), 0, false))
	speaker_plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(speaker_plate)

	var name_col := VBoxContainer.new()
	name_col.alignment = BoxContainer.ALIGNMENT_CENTER
	name_col.add_theme_constant_override("separation", 0)
	name_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speaker_plate.add_child(name_col)

	speaker_label = Label.new()
	speaker_label.add_theme_font_override("font", UIUtil.font_bold(true))
	speaker_label.add_theme_font_size_override("font_size", 26)
	speaker_label.add_theme_color_override("font_color", UIUtil.PINK_DEEP)
	speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_col.add_child(speaker_label)

	name_col.add_child(UIUtil.sparkle_rule(UIUtil.PINK_DEEP, 220, 14))

	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.fit_content = false  # fixed box height — don't grow with line length
	text_label.scroll_active = false
	text_label.custom_minimum_size = Vector2(0, 128)
	text_label.add_theme_font_override("normal_font", UIUtil.FONT_BODY)
	text_label.add_theme_font_size_override("normal_font_size", 30)
	text_label.add_theme_constant_override("line_separation", -12)
	text_label.add_theme_color_override("default_color", UIUtil.TEXT_DARK)
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.clip_contents = true  # never spill onto the button row
	dvbox.add_child(text_label)

	# ---- Bottom row: continue hint + Save / Load / Log / Auto / Fast-forward.
	# Pinned to the panel's bottom padding (full width, 34px tall) ----
	var bottom_row := HBoxContainer.new()
	bottom_row.anchor_top = 1.0
	bottom_row.anchor_bottom = 1.0
	bottom_row.anchor_right = 1.0
	bottom_row.offset_top = -48
	bottom_row.add_theme_constant_override("separation", 8)
	stage.add_child(bottom_row)

	hint_wrap = Control.new()
	hint_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_wrap.custom_minimum_size = Vector2(260, 0)
	hint_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_row.add_child(hint_wrap)

	continue_hint = UIUtil.body_label("♥  click / space to continue", 20, UIUtil.PINK_DEEP)
	hint_wrap.add_child(continue_hint)
	var hint_tw := continue_hint.create_tween().set_loops()
	hint_tw.tween_property(continue_hint, "modulate:a", 0.4, 0.8).set_trans(Tween.TRANS_SINE)
	hint_tw.tween_property(continue_hint, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

	var save_btn := UIUtil.pill_button("", 56, 48, "green")
	save_btn.tooltip_text = "Save"
	_add_icon(save_btn, "save")
	save_btn.pressed.connect(func(): _open_slot_popup(true))
	bottom_row.add_child(save_btn)

	var load_btn := UIUtil.pill_button("", 56, 48, "green")
	load_btn.tooltip_text = "Load"
	_add_icon(load_btn, "load")
	load_btn.pressed.connect(func(): _open_slot_popup(false))
	bottom_row.add_child(load_btn)

	log_btn = UIUtil.pill_button("", 56, 48, "green")
	log_btn.tooltip_text = "Dialogue log (L)"
	_add_icon(log_btn, "log")
	log_btn.pressed.connect(_open_log)
	bottom_row.add_child(log_btn)

	auto_btn = UIUtil.pill_button("", 56, 48, "green")
	auto_btn.toggle_mode = true
	auto_btn.tooltip_text = "Auto-advance"
	_add_icon(auto_btn, "auto")
	auto_btn.pressed.connect(_on_auto_toggled)
	bottom_row.add_child(auto_btn)

	ff_btn = UIUtil.pill_button("", 56, 48, "green")
	ff_btn.toggle_mode = true
	ff_btn.tooltip_text = "Fast forward (5x, auto-advance)"
	_add_icon(ff_btn, "ff")
	ff_btn.pressed.connect(_on_ff_toggled)
	bottom_row.add_child(ff_btn)

	# ---- Choice box (overlay, centered) ----
	choice_box = VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 8)
	choice_box.set_anchors_preset(Control.PRESET_CENTER)
	choice_box.custom_minimum_size = Vector2(620, 0)
	choice_box.position = Vector2(330, 160)
	choice_box.visible = false
	add_child(choice_box)

	type_timer = Timer.new()
	type_timer.wait_time = type_speed
	type_timer.one_shot = false
	type_timer.timeout.connect(_on_type_tick)
	add_child(type_timer)

	# ---- Scene transition overlay (black + location card), always on top ----
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color(UIUtil.BLACK)
	transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_overlay.modulate.a = 0.0
	transition_overlay.visible = false
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # clicks pass through; _advance skips
	add_child(transition_overlay)

	# card centered dead-middle of the screen
	var card_center := CenterContainer.new()
	card_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.add_child(card_center)

	transition_card = VBoxContainer.new()
	transition_card.alignment = BoxContainer.ALIGNMENT_CENTER
	transition_card.add_theme_constant_override("separation", 18)
	transition_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_card.visible = false
	card_center.add_child(transition_card)

	card_place = Label.new()
	card_place.add_theme_font_override("font", UIUtil.font_bold(true))
	card_place.add_theme_font_size_override("font_size", 26)
	card_place.add_theme_color_override("font_color", UIUtil.CREAM)
	card_place.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_place.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_place.custom_minimum_size = Vector2(560, 0)
	transition_card.add_child(card_place)

	card_time = Label.new()
	card_time.add_theme_font_override("font", UIUtil.font_semi(true))
	card_time.add_theme_font_size_override("font_size", 18)
	card_time.add_theme_color_override("font_color", UIUtil.GOLD)
	card_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_card.add_child(card_time)


func _build_hearts() -> void:
	for c in GameState.CHARACTERS:
		var key := String(c)
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 0)

		var name_lbl := UIUtil.bar_label(key.capitalize(), 18, UIUtil.CREAM)
		name_lbl.clip_text = false
		name_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(name_lbl)

		# Real heart icons replace the drawn ♥/♡ glyph row.
		var hr := UIUtil.heart_row(5, 0, PixelArt.char_color(key), 17.0)
		col.add_child(hr["row"])
		heart_labels[key] = hr["icons"]

		var num_lbl := UIUtil.bar_label("", 18, Color(UIUtil.CREAM, 0.95))
		num_lbl.clip_text = false
		num_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(num_lbl)

		num_labels[key] = num_lbl
		rank_labels[key] = name_lbl
		hearts_box.add_child(col)
	_refresh_hearts()


func _refresh_hearts(animate: bool = false) -> void:
	for c in heart_labels.keys():
		var key := String(c)
		var pts: int = GameState.affection(key)
		var full_hearts := int(min(5, ceil(pts / 2.0)))
		UIUtil.set_hearts(heart_labels[key], full_hearts, PixelArt.char_color(key), animate)
		num_labels[key].text = "%d · %s" % [pts, GameState.rank_name(key)]


func _on_points_changed(c: String, v: int) -> void:
	var key := String(c)
	var delta: int = v - int(_last_points.get(key, 0))
	if delta != 0 and key != "":
		# Floating toast so the change is actually noticed; chime only on gains.
		UIUtil.affection_toast(self, PixelArt.char_color(key), delta, key)
		if delta > 0:
			Audio.play_sfx("chime")
	_last_points = GameState.points.duplicate()
	_refresh_hearts(true)


func _exit_tree() -> void:
	# Never leave the music stuck quiet if the scene changes mid-minigame.
	Audio.unduck_bgm()
	UIUtil.set_box_opacity_hook(Callable())
	UIUtil.set_settings_hook(Callable())
	UIUtil.flush_read_lines()


# ------------------------------------------------------------ chapter flow

func _load_chapter(id: String, resume_line: int = 0) -> void:
	if id == "game_end":
		_show_end_screen()
		return

	chapter_id = id
	chapter = Story.get_chapter(id)
	if chapter.is_empty():
		push_warning("Unknown chapter id: %s" % id)
		return

	GameState.current_chapter_id = id
	GameState.mark_visited(id)
	# Defensive: a fresh chapter never inherits an in-flight minigame state.
	_mg_active = false
	_mg_attempts = 0
	_mg_cfg = {}
	if chapter.has("ending"):
		GameState.mark_ending(id)
	if resume_line == 0:
		history.clear()
		_history_keys.clear()

	title_label.text = chapter.get("title", "")
	location_label.text = chapter.get("location", "")
	bgm_label.text = String(chapter.get("bgm_key", "")).to_upper()
	Audio.play_bgm(String(chapter.get("bgm_key", "")))

	var bg_hex: String = chapter.get("bg", "#eee1d3")
	var tw := create_tween()
	tw.tween_property(bg_rect, "color", Color(bg_hex), 0.6)

	_set_backdrop(String(chapter.get("bg_scene", "neutral")))

	var lines: Array = chapter.get("lines", [])
	line_idx = clamp(resume_line, 0, lines.size())
	choice_box.visible = false
	_play_transition()


## Swap the code-drawn backdrop for the chapter's location.
func _set_backdrop(scene_key: String) -> void:
	for child in bg_art.get_children():
		child.queue_free()
	var art := PixelArt.backdrop(scene_key)
	art.modulate.a = 0.0
	bg_art.add_child(art)
	create_tween().tween_property(art, "modulate:a", 1.0, 0.6)


## Fade to black (hiding the HUD), show a location/time card when the setting
## changed, then fade back in. Same-location chapters get a quick dip only.
func _play_transition() -> void:
	var new_loc: String = chapter.get("location", "")
	var changed := new_loc != _last_location
	_last_location = new_loc

	transitioning = true
	type_timer.stop()
	is_typing = false
	_set_hint(false)
	portrait_holder.visible = false
	Audio.play_sfx("whoosh")

	if changed:
		var parts := new_loc.split("—")
		if parts.size() > 1:
			card_place.text = "—".join(parts.slice(0, parts.size() - 1)).strip_edges()
			var t: String = parts[parts.size() - 1].strip_edges()
			card_time.text = "~ %s ~" % t
			card_time.visible = t != ""
		else:
			card_place.text = new_loc
			card_time.visible = false
		transition_card.visible = true

	transition_overlay.visible = true
	var long_fade := 0.5 if changed else 0.2
	transition_tween = create_tween()
	transition_tween.tween_property(transition_overlay, "modulate:a", 1.0, long_fade)
	transition_tween.tween_callback(func(): _set_hud_visible(false))
	if changed:
		transition_tween.tween_interval(1.2)
		transition_tween.tween_callback(func(): transition_card.visible = false)
	transition_tween.tween_property(transition_overlay, "modulate:a", 0.0, 0.4)
	transition_tween.tween_callback(_finish_transition)


func _set_hud_visible(v: bool) -> void:
	for node in [top_panel, dialogue_panel]:
		if node:
			node.visible = v


func _finish_transition() -> void:
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()
	transition_overlay.visible = false
	transition_overlay.modulate.a = 0.0
	transition_card.visible = false
	_set_hud_visible(true)
	transitioning = false
	_show_current_line()


func _skip_transition() -> void:
	if transitioning:
		_finish_transition()


func _show_current_line() -> void:
	GameState.current_line_idx = line_idx  # keep in sync so saves capture the exact spot
	var lines: Array = chapter.get("lines", [])
	if line_idx >= lines.size():
		_on_lines_finished()
		return
	var line: Dictionary = lines[line_idx]
	var speaker: String = line.get("speaker", "")
	speaker_label.text = speaker
	speaker_plate.visible = speaker != ""

	var text: String = String(line.get("text", ""))

	# Portrait + expression + name-plate tint.
	var override_key: String = String(line.get("portrait", ""))
	var pkey: String = override_key if override_key != "" else PixelArt.portrait_key_for_speaker(speaker)
	var expr: String = String(line.get("expr", ""))
	if expr == "":
		expr = PixelArt.expression_for_text(text)
	_set_portrait(pkey, expr)
	# Name stays hot-pink Baloo2; character identity lives in the portrait.

	_remember_line(speaker, text)
	_start_typing(text)
	# Subtle slide-up of the box on each new line.
	if dialogue_panel.visible:
		UIUtil.slide_up(dialogue_panel, 12.0, 0.18)


func _set_portrait(pkey: String, expr: String = "neutral") -> void:
	for child in portrait_holder.get_children():
		child.queue_free()
	if pkey == "":
		portrait_holder.visible = false
		return
	var p := PixelArt.portrait(pkey, 230.0, expr)
	p.modulate.a = 0.0
	portrait_holder.add_child(p)
	portrait_holder.visible = true
	create_tween().tween_property(p, "modulate:a", 1.0, 0.25)


func _remember_line(speaker: String, text: String) -> void:
	var key := "%s:%d" % [chapter_id, line_idx]
	if _history_keys.has(key):
		return
	_history_keys[key] = true
	history.append({"speaker": speaker, "text": text})


## A leading parenthetical aside is moved onto its own line so it reads
## separately from the spoken dialogue.
func _format_dialogue(t: String) -> String:
	var s := t.strip_edges()
	# bbcode-italic aside, e.g. "[i](Pointing the marker at him)[/i] ..."
	var itag := s.find("[/i]")
	if itag > 0 and s.begins_with("[i]("):
		var aside_i := s.substr(0, itag + 4)
		var rest_i := s.substr(itag + 4).strip_edges()
		if rest_i != "":
			return aside_i + "\n" + rest_i
	# plain leading parenthetical
	if s.begins_with("("):
		var i := s.find(")")
		if i > 0:
			var aside := s.substr(0, i + 1)
			var rest := s.substr(i + 1).strip_edges()
			if rest != "":
				return aside + "\n" + rest
	return s


func _start_typing(t: String) -> void:
	full_text = _format_dialogue(t)
	char_idx = 0
	is_typing = true
	_set_dialogue_text("")
	_set_hint(false)
	type_timer.start()


## Center-aligned dialogue body (bbcode wrap) — typing stays intact because
## the RichTextLabel text is rebuilt from the substring each tick.
func _set_dialogue_text(s: String) -> void:
	text_label.text = "[center]%s[/center]" % s


func _on_type_tick() -> void:
	if char_idx >= full_text.length():
		type_timer.stop()
		is_typing = false
		_set_hint(true)
		_maybe_auto_advance()
		return
	# Text Speed = instant (top of the slider) reveals the whole line at once.
	if UIUtil.is_text_instant():
		_complete_typing()
		_maybe_auto_advance()
		return
	# advance a few chars at a time for snappier feel without skipping bbcode
	char_idx = min(char_idx + _type_step(), full_text.length())
	_set_dialogue_text(full_text.substr(0, char_idx))
	if char_idx % 6 == 0:
		Audio.play_sfx("blip")


## Characters revealed per typewriter tick (scales with the Text Speed setting
## and the fast-forward toggle).
func _type_step() -> int:
	return maxi(1, int(round(2.0 * speed_mult * UIUtil.get_text_speed())))


func _maybe_auto_advance() -> void:
	if choice_box.visible or transitioning:
		return
	if ff_btn != null and ff_btn.button_pressed:
		get_tree().create_timer(0.3).timeout.connect(func():
			if not transitioning and not choice_box.visible:
				_advance())
	elif auto_mode:
		get_tree().create_timer(_auto_delay()).timeout.connect(func():
			if not transitioning and not choice_box.visible and not is_typing:
				_advance())


## Delay before auto-advance steps to the next line (Auto-Mode Speed setting).
func _auto_delay() -> float:
	return UIUtil.get_auto_delay()


func _complete_typing() -> void:
	type_timer.stop()
	_set_dialogue_text(full_text)
	char_idx = full_text.length()
	is_typing = false
	_set_hint(true)
	# Remember that this line has been fully seen, for "Skip read".
	UIUtil.mark_line_read(chapter_id, line_idx)


## Fade the continue hint instead of hiding it, so the bottom button row
## never reflows while a line is typing.
func _set_hint(v: bool) -> void:
	if hint_wrap == null:
		return
	hint_wrap.modulate.a = 1.0 if v else 0.0


func _on_ff_toggled(on: bool) -> void:
	speed_mult = 5.0 if on else 1.0
	if on and not is_typing and not choice_box.visible and not transitioning:
		_maybe_auto_advance()


func _on_auto_toggled(on: bool) -> void:
	auto_mode = on
	if on and not is_typing and not choice_box.visible and not transitioning:
		_maybe_auto_advance()


## Box Opacity setting applied to the panel only — the text stays fully opaque.
func _apply_box_opacity(v: float) -> void:
	if dialogue_panel != null and is_instance_valid(dialogue_panel):
		dialogue_panel.self_modulate = Color(1, 1, 1, UIUtil.clamp_box_opacity(v))


## Accessibility settings applied live to the dialogue box.
func _apply_accessibility() -> void:
	if text_label == null or speaker_label == null:
		return
	var lt: bool = UIUtil.get_large_text()
	text_label.add_theme_font_size_override("normal_font_size", 34 if lt else 30)
	text_label.add_theme_constant_override("line_separation", -17 if lt else -12)
	text_label.custom_minimum_size = Vector2(0, 124 if lt else 128)
	speaker_label.add_theme_font_size_override("font_size", 30 if lt else 26)
	if _dmargin != null and is_instance_valid(_dmargin):
		var m: int = 4 if lt else 6
		_dmargin.add_theme_constant_override("margin_top", m)
		_dmargin.add_theme_constant_override("margin_bottom", m)


## True when the current line may be fast-forwarded under the Skip setting.
func _can_skip_line() -> bool:
	match UIUtil.get_skip_mode():
		UIUtil.SKIP_ALL:
			return true
		UIUtil.SKIP_READ:
			return UIUtil.is_line_read(chapter_id, line_idx)
	return false


## Held-Ctrl fast-forward (gated by the Skip setting).
func _process(_delta: float) -> void:
	if not is_instance_valid(choice_box) or not is_instance_valid(dialogue_panel):
		return
	if modal != null and is_instance_valid(modal):
		return
	if transitioning or choice_box.visible:
		return
	if not Input.is_key_pressed(KEY_CTRL):
		return
	if not _can_skip_line():
		return
	var now := Time.get_ticks_msec()
	if now - _last_skip_ms < 90:
		return
	_last_skip_ms = now
	if is_typing:
		_complete_typing()
	line_idx += 1
	_show_current_line()


func _advance() -> void:
	if modal != null and is_instance_valid(modal):
		return
	if transitioning:
		_skip_transition()  # clicks/space skip the transition
		return
	if choice_box.visible:
		return
	if is_typing:
		_complete_typing()
		return
	Audio.play_sfx("click")
	line_idx += 1
	_show_current_line()


func _on_lines_finished() -> void:
	# A chapter may gate its beat behind a minigame: run it first, then fall
	# through to the choice / next chapter.
	if _mg_active:
		return
	var mg = chapter.get("minigame", null)
	if typeof(mg) == TYPE_DICTIONARY and not (mg as Dictionary).is_empty():
		_begin_minigame_chapter(mg)
		return
	_after_lines()


## The normal end-of-lines flow, shared by the no-minigame and post-minigame paths.
func _after_lines() -> void:
	if chapter.has("choice"):
		_show_choices(chapter["choice"])
	elif chapter.has("next"):
		_load_chapter(chapter["next"])
	else:
		_show_end_screen()


# ------------------------------------------------------------- minigames

## Validate the chapter's minigame config, then launch (or skip if unusable /
## already satisfied).
func _begin_minigame_chapter(cfg: Dictionary) -> void:
	_mg_cfg = cfg
	_mg_attempts = 0
	var id := String(cfg.get("id", ""))
	if id == "" or not MinigameRegistry.has(id):
		_after_lines()
		return
	var flag := String(cfg.get("success_flag", ""))
	if flag != "" and GameState.has_flag(flag):
		_after_lines()
		return
	_launch_minigame()


## Full-rect modal overlay: dim backdrop + the minigame centred. Blocks all
## dialogue input while it is up.
func _launch_minigame() -> void:
	_mg_active = true
	var id := String(_mg_cfg.get("id", ""))
	var mg := MinigameRegistry.create(id)
	if mg == null:
		_mg_active = false
		_after_lines()
		return

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(UIUtil.WINE, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	mg.setup({
		"title": String(_mg_cfg.get("title", "")),
		"prompt": String(_mg_cfg.get("prompt", "")),
		"difficulty": float(_mg_cfg.get("difficulty", 0.5)),
		"seed": int(Time.get_unix_time_from_system()),
		"accent": UIUtil.route_color(String(chapter.get("route", ""))),
	})
	center.add_child(mg)
	mg.finished.connect(_on_minigame_finished.bind(overlay))
	_present(overlay)
	# Duck the music while the minigame is up; always unduck when it leaves the
	# tree (finish, forfeit, or any other dismissal) so it can never stick.
	Audio.duck_bgm()
	overlay.tree_exited.connect(func() -> void: Audio.unduck_bgm())


func _on_minigame_finished(success: bool, _result: Dictionary, overlay: Control) -> void:
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()
	if success:
		var flag := String(_mg_cfg.get("success_flag", ""))
		if flag != "":
			GameState.set_flag(flag)
		_finish_minigame()
		return
	# Failure (or {forfeit:true}) → offer exactly one retry at an affection cost.
	if _mg_attempts < 1:
		_mg_attempts += 1
		_offer_minigame_retry()
	else:
		_finish_minigame()


func _finish_minigame() -> void:
	_mg_active = false
	_mg_cfg = {}
	_after_lines()


## Small confirm popup: retry (costs affection) or continue without the flag.
func _offer_minigame_retry() -> void:
	var route := String(chapter.get("route", ""))
	var who: String = Story.ROUTE_NAMES.get(route, route.capitalize())
	var p := UIUtil.popup("Second Chance")
	var vbox: VBoxContainer = p["vbox"]

	var msg := UIUtil.body_label("Try again? Costs 2 affection with %s." % who, 18, UIUtil.TEXT_MUTED)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.clip_text = false
	msg.custom_minimum_size = Vector2(360, 0)
	vbox.add_child(msg)

	var retry := UIUtil.pill_button("Try Again", 300, 48)
	retry.pressed.connect(func():
		_mg_retry_open = false
		p["overlay"].queue_free()
		GameState.add_affection(route, -2)
		_launch_minigame())
	vbox.add_child(retry)

	var skip := UIUtil.pill_button("Continue", 300, 48)
	skip.pressed.connect(func():
		_mg_retry_open = false
		p["overlay"].queue_free()
		_finish_minigame())
	vbox.add_child(skip)

	# If the popup is dismissed another way (Esc), still continue — never deadlock.
	_mg_retry_open = true
	p["overlay"].tree_exited.connect(func():
		if _mg_retry_open:
			_mg_retry_open = false
			_finish_minigame())
	_present(p["overlay"])


## True when every condition in an option's `requires` dict is satisfied.
func _option_available(opt: Dictionary) -> bool:
	var req = opt.get("requires", null)
	if req == null or typeof(req) != TYPE_DICTIONARY:
		return true
	if req.has("char"):
		if GameState.affection(String(req.get("char", ""))) < int(req.get("min", 0)):
			return false
	if req.has("flag") and not GameState.has_flag(String(req.get("flag", ""))):
		return false
	if req.has("not_flag") and GameState.has_flag(String(req.get("not_flag", ""))):
		return false
	return true


func _show_choices(choice_data: Dictionary) -> void:
	for c in choice_box.get_children():
		c.queue_free()

	var prompt := UIUtil.heading(choice_data.get("prompt", "What do you do?"), 22, UIUtil.TEXT_LIGHT)
	prompt.clip_text = false
	var prompt_panel := PanelContainer.new()
	prompt_panel.add_theme_stylebox_override("panel", UIUtil.tex_panel(UIUtil.TEX_REPLY, 16, -1, UIUtil.WINE))
	prompt_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var pm := UIUtil.margin(28, 10, 28, 10)
	pm.add_child(prompt)
	prompt_panel.add_child(pm)
	choice_box.add_child(prompt_panel)

	var options: Array = choice_data.get("options", [])
	var any_enabled := false
	var first_btn: Button = null
	for opt in options:
		var available: bool = _option_available(opt)
		# Hidden gates stay hidden; a locked_hint shows the option disabled.
		if not available and not opt.has("locked_hint"):
			continue
		var label := String(opt.get("text", "..."))
		if not available:
			label += "  " + String(opt.get("locked_hint", ""))
		var btn := UIUtil.choice_button(label, 640, 64)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.disabled = not available
		if available:
			any_enabled = true
			if first_btn == null:
				first_btn = btn
			btn.pressed.connect(_on_choice_selected.bind(opt))
		choice_box.add_child(btn)

	if not any_enabled:
		# Safety net: never strand the player (contract says a choice always has
		# an ungated option, but fall back to the first one if data is wrong).
		if options.size() > 0:
			var opt: Dictionary = options[0]
			var btn := UIUtil.choice_button(String(opt.get("text", "...")), 640, 64)
			btn.pressed.connect(_on_choice_selected.bind(opt))
			if first_btn == null:
				first_btn = btn
			choice_box.add_child(btn)

	# Choices take the stage: hide the dialogue box so a tall choice list fits.
	dialogue_panel.visible = false
	choice_box.visible = true
	# re-center based on content, keeping clear of the top bar
	await get_tree().process_frame
	var vp := get_viewport_rect().size
	choice_box.position = Vector2(
		(vp.x - choice_box.size.x) / 2.0,
		clamp((vp.y - choice_box.size.y) / 2.0, 70.0, vp.y)
	)
	# Focus the first real option so arrow keys + Enter work without a mouse.
	if first_btn != null:
		first_btn.grab_focus()
	# Stagger the choice bars in (fast, non-blocking).
	var choice_btns: Array = []
	for ch in choice_box.get_children():
		if ch is Button:
			choice_btns.append(ch)
	UIUtil.stagger_in(choice_btns)


func _on_choice_selected(opt: Dictionary) -> void:
	Audio.play_sfx("choice")
	var ch: String = opt.get("char", "")
	var pts: int = int(opt.get("points", 0))
	if ch != "" and pts != 0:
		GameState.add_affection(ch, pts)
	var flag: String = String(opt.get("sets_flag", ""))
	if flag != "":
		GameState.set_flag(flag)
	choice_box.visible = false
	_load_chapter(String(opt.get("next", "game_end")))
	GameState.save_game()  # after loading: save points at the next chapter's start, not a replayable choice


func _on_scene_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not choice_box.visible:
			_advance()


func _unhandled_input(event: InputEvent) -> void:
	if UIUtil.handle_fullscreen_input(event):
		get_viewport().set_input_as_handled()
		return
	if modal != null and is_instance_valid(modal):
		if event.is_action_pressed("ui_cancel"):
			modal.queue_free()
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		if not choice_box.visible:
			_advance()
	elif event.is_action_pressed("ui_cancel"):
		_open_pause_menu()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_L:
		_open_log()


# ------------------------------------------------------------- popups

func _present(overlay: Control) -> void:
	modal = overlay
	overlay.tree_exited.connect(func(): if modal == overlay: modal = null)
	add_child(overlay)
	UIUtil.focus_first(overlay)


## In-game Settings screen (same grouped rows as the main menu).
func _open_settings() -> void:
	_present(UIUtil.settings_overlay())


## Esc: pause overlay — Resume, Settings, Save, Load, Relationships,
## Flowchart, Main Menu.
func _open_pause_menu() -> void:
	if has_node("PauseOverlay"):
		return
	var p := UIUtil.popup("Paused")
	p["overlay"].name = "PauseOverlay"
	var vbox: VBoxContainer = p["vbox"]

	var resume_btn := UIUtil.pill_button("Resume", 260, 48, "blue")
	resume_btn.pressed.connect(func(): p["overlay"].queue_free())
	vbox.add_child(resume_btn)

	var settings_btn := UIUtil.pill_button("Settings", 260, 48)
	settings_btn.pressed.connect(func():
		p["overlay"].queue_free()
		_open_settings())
	vbox.add_child(settings_btn)

	var save_btn := UIUtil.pill_button("Save", 260, 48, "blue")
	save_btn.pressed.connect(func(): _open_slot_popup(true))
	vbox.add_child(save_btn)

	var load_btn := UIUtil.pill_button("Load", 260, 48, "blue")
	load_btn.disabled = not GameState.has_save
	load_btn.pressed.connect(func(): _open_slot_popup(false))
	vbox.add_child(load_btn)

	var status_btn := UIUtil.pill_button("Relationships", 260, 48, "blue")
	status_btn.pressed.connect(_open_status)
	vbox.add_child(status_btn)

	var flow_btn := UIUtil.pill_button("Flowchart", 260, 48, "blue")
	flow_btn.pressed.connect(func():
		GameState.save_game()
		get_tree().change_scene_to_file("res://scenes/Flowchart.tscn")
	)
	vbox.add_child(flow_btn)

	var menu_btn := UIUtil.pill_button("Main Menu", 260, 48, "red")
	menu_btn.pressed.connect(func():
		GameState.save_game()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	vbox.add_child(menu_btn)

	_present(p["overlay"])


## Relationships status screen: per-character affection, rank, and progress.
func _open_status() -> void:
	var p := UIUtil.popup("Relationships")
	var vbox: VBoxContainer = p["vbox"]

	for c in GameState.CHARACTERS:
		var key := String(c)
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UIUtil.panel_style(UIUtil.PANEL_CREAM, 6, Color(UIUtil.PINK_DEEP, 0.55), 2, false))
		var cm := UIUtil.margin(16, 16, 16, 16)
		card.add_child(cm)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		cm.add_child(col)

		# Header line: heart + name (left) ... rank · n/30 (right)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 8)
		col.add_child(head)
		var dot := UIUtil.icon_rect(UIUtil.TEX_ICON_HEART_PINK, 20, PixelArt.char_color(key))
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(dot)
		var nm := UIUtil.body_label(Story.ROUTE_NAMES.get(key, key.capitalize()), 22, UIUtil.TEXT_DARK)
		nm.clip_text = false
		nm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(nm)
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(spacer)
		var rk := UIUtil.body_label("%s · %d/%d" % [GameState.rank_name(key), GameState.affection(key), GameState.MAX_AFFECTION], 20, UIUtil.PINK_DEEP)
		rk.clip_text = false
		rk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(rk)

		# Full-width bar on its own line: pink fill on a muted cream track.
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = GameState.MAX_AFFECTION
		bar.value = GameState.affection(key)
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 18)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var track := StyleBoxFlat.new()
		track.bg_color = Color("#EBDCC6")
		track.set_corner_radius_all(9)
		bar.add_theme_stylebox_override("background", track)
		var pfill := StyleBoxFlat.new()
		pfill.bg_color = UIUtil.PINK_DEEP
		pfill.set_corner_radius_all(9)
		bar.add_theme_stylebox_override("fill", pfill)
		col.add_child(bar)
		vbox.add_child(card)

	var note := UIUtil.body_label("Affection grows through choices. High affection unlocks better endings.", 18, UIUtil.TEXT_MUTED)
	note.clip_text = false
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(340, 0)
	vbox.add_child(note)

	var close_btn := UIUtil.pill_button("Close", 260, 48, "blue")
	close_btn.pressed.connect(func(): p["overlay"].queue_free())
	vbox.add_child(close_btn)

	p["overlay"].tree_exited.connect(func():
		if has_node("PauseOverlay"):
			get_node("PauseOverlay").queue_free())
	_present(p["overlay"])


## Scrollable dialogue history.
func _open_log() -> void:
	if history.is_empty():
		return
	var p := UIUtil.popup("Dialogue Log")
	var vbox: VBoxContainer = p["vbox"]

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var rich := RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.fit_content = true
	rich.scroll_active = false
	rich.custom_minimum_size = Vector2(600, 0)
	rich.add_theme_font_override("normal_font", UIUtil.FONT_BODY)
	rich.add_theme_font_size_override("normal_font_size", 32)
	rich.add_theme_color_override("default_color", UIUtil.TEXT_DARK)
	scroll.add_child(rich)

	var bb := ""
	for entry in history:
		var speaker: String = entry.get("speaker", "")
		var text: String = _format_dialogue(entry.get("text", ""))
		if speaker != "":
			var pkey := PixelArt.portrait_key_for_speaker(speaker)
			var col := PixelArt.char_color(pkey).to_html(false) if pkey != "" else "c94a78"
			bb += "[color=#%s][b]%s[/b][/color]\n%s\n\n" % [col, speaker, text]
		else:
			bb += "[color=#b9a8c4]%s[/color]\n\n" % text
	rich.text = bb

	var close_btn := UIUtil.pill_button("Close", 260, 48, "blue")
	close_btn.pressed.connect(func(): p["overlay"].queue_free())
	vbox.add_child(close_btn)

	_present(p["overlay"])
	await get_tree().process_frame
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


## Nested 6-slot picker for Save (is_save=true, all slots pickable) or
## Load (is_save=false, only occupied slots pickable).
func _open_slot_popup(is_save: bool) -> void:
	var p := UIUtil.popup("Save Game" if is_save else "Load Game")
	var vbox: VBoxContainer = p["vbox"]
	var grid := UIUtil.slot_grid(GameState.all_slot_summaries(), func(slot: int):
		if is_save:
			GameState.save_to_slot(slot)
			p["overlay"].queue_free()
		else:
			if GameState.load_from_slot(slot):
				p["overlay"].queue_free()
				var pause := get_node_or_null("PauseOverlay")
				if pause:
					pause.queue_free()
				_last_points = GameState.points.duplicate()
				_load_chapter(GameState.current_chapter_id, GameState.current_line_idx)
	, not is_save)
	vbox.add_child(grid)

	var cancel_btn := UIUtil.pill_button("Cancel", 260, 48, "red")
	cancel_btn.pressed.connect(func(): p["overlay"].queue_free())
	vbox.add_child(cancel_btn)

	_present(p["overlay"])


# --------------------------------------------------------------- end screen

func _show_end_screen() -> void:
	GameState.current_chapter_id = "game_end"
	GameState.save_game()
	Audio.play_bgm("warm")
	Audio.play_sfx("ending")

	for c in get_children():
		c.queue_free()
	modal = null

	add_child(UIUtil.dreamy_bg())

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var last_ending := _last_ending_id()
	var is_bad := last_ending.ends_with("_end_bad")
	var card := UIUtil.card_panel(28, 3, UIUtil.TEX_TEXTBOX)
	card.custom_minimum_size = Vector2(500, 0)
	center.add_child(card)

	var margin := UIUtil.margin(40, 36, 40, 36)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var end_title := UIUtil.heading("~ The End ~", 40, UIUtil.PINK_DEEP)
	vbox.add_child(end_title)
	UIUtil.title_strip(end_title, UIUtil.TEX_DEFEAT if is_bad else UIUtil.TEX_VICTORY, 36, 14)
	vbox.add_child(UIUtil.body_label("Thanks for playing Office Hearts!", 18, UIUtil.PLUM_SOFT))

	# Show which route/ending was just reached, plus total collection progress.
	if last_ending != "":
		var ec: Dictionary = Story.get_chapter(last_ending)
		vbox.add_child(UIUtil.body_label("Ending: %s" % ec.get("ending_name", ec.get("title", last_ending)), 18, UIUtil.PINK_DEEP))

	var lead := GameState.get_leading_character()
	var lead_name: String = Story.ROUTE_NAMES.get(lead, lead.capitalize())
	vbox.add_child(UIUtil.body_label("Closest to: %s (%d · %s)" % [lead_name, GameState.affection(lead), GameState.rank_name(lead)], 18, UIUtil.PLUM_SOFT))

	vbox.add_child(UIUtil.body_label("Endings unlocked: %d / %d" % [GameState.endings_unlocked.size(), Story.ENDING_IDS.size()], 18, UIUtil.PLUM_SOFT))

	vbox.add_child(HSeparator.new())

	var again_btn := UIUtil.pill_button("Play Again", 340, 56, "continue")
	again_btn.pressed.connect(func():
		GameState.reset_new_game()
		get_tree().change_scene_to_file("res://scenes/Game.tscn")
	)
	vbox.add_child(again_btn)

	var flow_btn := UIUtil.pill_button("Flowchart", 340, 56, "blue")
	flow_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Flowchart.tscn"))
	vbox.add_child(flow_btn)

	var gallery_btn := UIUtil.pill_button("Endings Gallery", 340, 56, "blue")
	gallery_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Gallery.tscn"))
	vbox.add_child(gallery_btn)

	var menu_btn2 := UIUtil.pill_button("Main Menu", 340, 56, "red")
	menu_btn2.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	vbox.add_child(menu_btn2)


## The route ending the player most recently reached.
func _last_ending_id() -> String:
	return GameState.last_ending_id
