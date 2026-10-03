extends Control
## The main gameplay screen: renders chapters line-by-line with a typewriter
## effect, shows affection hearts, and presents branching choices.

var chapter_id: String = ""
var chapter: Dictionary = {}
var line_idx: int = 0

var is_typing: bool = false
var full_text: String = ""
var char_idx: int = 0
var type_speed: float = 0.018

var bg_rect: ColorRect
var top_panel: PanelContainer
var title_label: Label
var location_label: Label
var bgm_label: Label
var speaker_label: Label
var text_label: RichTextLabel
var choice_box: VBoxContainer
var continue_hint: Label
var hearts_box: HBoxContainer
var heart_labels: Dictionary = {}
var dialogue_panel: PanelContainer
var click_catcher: Control
var ff_btn: Button

var type_timer: Timer
var speed_mult: float = 1.0  # fast-forward multiplier (Timer has no speed_scale in 4.7)

# Scene transition: fade to black, show a location/time card, fade back in.
var transition_overlay: ColorRect
var transition_card: VBoxContainer
var card_place: Label
var card_time: Label
var transition_tween: Tween
var transitioning: bool = false
var _last_location: String = ""


## Tiny pixel-art icon drawn with vector rects — floppy disk (save), folder
## (load), double fast-forward triangles. No emoji — same hard-edge style.
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


## Center a PixelIcon of the given kind on a square-ish button.
func _add_icon(btn: Button, kind: String) -> void:
	var icon := PixelIcon.new()
	icon.kind = kind
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size = Vector2(16, 16)
	icon.position = (btn.custom_minimum_size - icon.size) / 2.0
	btn.add_child(icon)


func _ready() -> void:
	_build_ui()
	GameState.points_changed.connect(_on_points_changed)
	_load_chapter(GameState.current_chapter_id, GameState.current_line_idx)


func _build_ui() -> void:
	bg_rect = ColorRect.new()
	bg_rect.color = Color("#eee1d3")
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)

	# ---- Click catcher (advances dialogue when clicking the scene) ----
	click_catcher = Control.new()
	click_catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_catcher.mouse_filter = Control.MOUSE_FILTER_PASS
	click_catcher.gui_input.connect(_on_scene_input)
	add_child(click_catcher)

	# ---- Top bar ----
	top_panel = PanelContainer.new()
	top_panel.add_theme_stylebox_override("panel", UIUtil.panel_style(UIUtil.PANEL_DARK, 0, UIUtil.BLACK, 0))
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

	title_label = UIUtil.bar_label("", 15, UIUtil.CREAM, UIUtil.FONT_PIXEL)
	title_col.add_child(title_label)

	var sub_row := HBoxContainer.new()
	sub_row.add_theme_constant_override("separation", 10)
	sub_row.clip_contents = true
	title_col.add_child(sub_row)
	location_label = UIUtil.bar_label("", 18, Color(UIUtil.CREAM, 0.8))
	sub_row.add_child(location_label)
	bgm_label = UIUtil.bar_label("", 18, Color(UIUtil.GOLD, 0.9))
	bgm_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	sub_row.add_child(bgm_label)

	hearts_box = HBoxContainer.new()
	hearts_box.add_theme_constant_override("separation", 14)
	top_row.add_child(hearts_box)
	_build_hearts()

	var menu_btn := UIUtil.gear_button()
	menu_btn.tooltip_text = "Options (Esc)"
	menu_btn.pressed.connect(_open_pause_menu)
	top_row.add_child(menu_btn)

	# ---- Dialogue panel ----
	dialogue_panel = UIUtil.card_panel(24, 3)
	dialogue_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_panel.offset_left = 40
	dialogue_panel.offset_right = -40
	dialogue_panel.offset_bottom = -30
	dialogue_panel.offset_top = -250
	add_child(dialogue_panel)

	var dmargin := MarginContainer.new()
	dmargin.add_theme_constant_override("margin_left", 28)
	dmargin.add_theme_constant_override("margin_right", 28)
	dmargin.add_theme_constant_override("margin_top", 18)
	dmargin.add_theme_constant_override("margin_bottom", 14)
	dialogue_panel.add_child(dmargin)

	var dvbox := VBoxContainer.new()
	dvbox.add_theme_constant_override("separation", 6)
	dmargin.add_child(dvbox)

	speaker_label = Label.new()
	speaker_label.add_theme_font_override("font", UIUtil.FONT_PIXEL)
	speaker_label.add_theme_font_size_override("font_size", 14)
	speaker_label.add_theme_color_override("font_color", UIUtil.PINK_DEEP)
	dvbox.add_child(speaker_label)

	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.fit_content = false  # fixed box height — don't grow with line length
	text_label.scroll_active = false
	text_label.custom_minimum_size = Vector2(0, 120)
	text_label.add_theme_font_override("normal_font", UIUtil.FONT_BODY)
	text_label.add_theme_font_size_override("normal_font_size", 24)
	text_label.add_theme_color_override("default_color", UIUtil.TEXT_DARK)
	dvbox.add_child(text_label)

	# ---- Bottom row: continue hint + Save / Load / Fast-forward ----
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 10)
	dvbox.add_child(bottom_row)

	continue_hint = UIUtil.body_label("▼ click / space to continue", 16, UIUtil.TEXT_MUTED)
	continue_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(continue_hint)

	var save_btn := UIUtil.pill_button("", 46, 34)
	save_btn.tooltip_text = "Save"
	_add_icon(save_btn, "save")
	save_btn.pressed.connect(func(): _open_slot_popup(true))
	bottom_row.add_child(save_btn)

	var load_btn := UIUtil.pill_button("", 46, 34)
	load_btn.tooltip_text = "Load"
	_add_icon(load_btn, "load")
	load_btn.pressed.connect(func(): _open_slot_popup(false))
	bottom_row.add_child(load_btn)

	ff_btn = UIUtil.pill_button("", 46, 34)
	ff_btn.toggle_mode = true
	ff_btn.tooltip_text = "Fast forward (5x, auto-advance)"
	_add_icon(ff_btn, "ff")
	ff_btn.pressed.connect(_on_ff_toggled)
	bottom_row.add_child(ff_btn)

	# ---- Choice box (overlay, centered) ----
	choice_box = VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 12)
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
	card_place.add_theme_font_override("font", UIUtil.FONT_PIXEL)
	card_place.add_theme_font_size_override("font_size", 16)
	card_place.add_theme_color_override("font_color", UIUtil.CREAM)
	card_place.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_place.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_place.custom_minimum_size = Vector2(560, 0)
	transition_card.add_child(card_place)

	card_time = Label.new()
	card_time.add_theme_font_override("font", UIUtil.FONT_PIXEL)
	card_time.add_theme_font_size_override("font_size", 11)
	card_time.add_theme_color_override("font_color", UIUtil.GOLD)
	card_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_card.add_child(card_time)

	# card self-sizes; the CenterContainer keeps it dead-center


func _build_hearts() -> void:
	for c in ["arthur", "dante", "leo"]:
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		var name_lbl := UIUtil.bar_label(c.capitalize(), 12, Color(UIUtil.CREAM, 0.8))
		name_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(name_lbl)
		var heart_lbl := Label.new()
		heart_lbl.add_theme_font_size_override("font_size", 16)
		heart_lbl.add_theme_color_override("font_color", UIUtil.route_color(c))
		heart_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(heart_lbl)
		heart_labels[c] = heart_lbl
		hearts_box.add_child(col)
	_refresh_hearts()


func _refresh_hearts() -> void:
	for c in heart_labels.keys():
		var pts: int = GameState.points.get(c, 0)
		var full_hearts := int(min(5, ceil(pts / 2.0)))
		var s := ""
		for i in range(5):
			s += "♥" if i < full_hearts else "♡"
		heart_labels[c].text = s


func _on_points_changed(_c: String, _v: int) -> void:
	_refresh_hearts()


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
	if chapter.has("ending"):
		GameState.mark_ending(id)

	title_label.text = chapter.get("title", "")
	location_label.text = chapter.get("location", "")
	bgm_label.text = chapter.get("bgm", "")

	var bg_hex: String = chapter.get("bg", "#eee1d3")
	var tw := create_tween()
	tw.tween_property(bg_rect, "color", Color(bg_hex), 0.6)

	var lines: Array = chapter.get("lines", [])
	line_idx = clamp(resume_line, 0, lines.size())
	choice_box.visible = false
	_play_transition()


## Fade to black (hiding the HUD), show a location/time card when the setting
## changed, then fade back in. Same-location chapters get a quick dip only.
## Clicking / space during the transition skips it.
func _play_transition() -> void:
	var new_loc: String = chapter.get("location", "")
	var changed := new_loc != _last_location
	_last_location = new_loc

	transitioning = true
	type_timer.stop()
	is_typing = false
	continue_hint.visible = false

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
	speaker_label.visible = speaker != ""
	_start_typing(String(line.get("text", "")))


func _start_typing(t: String) -> void:
	full_text = t
	char_idx = 0
	is_typing = true
	text_label.text = ""
	continue_hint.visible = false
	type_timer.start()


func _on_type_tick() -> void:
	if char_idx >= full_text.length():
		type_timer.stop()
		is_typing = false
		continue_hint.visible = true
		if ff_btn != null and ff_btn.button_pressed and not transitioning:
			get_tree().create_timer(0.3).timeout.connect(func():
				if not transitioning:
					_advance())
		return
	# advance a few chars at a time for snappier feel without skipping bbcode
	char_idx = min(char_idx + int(2.0 * speed_mult), full_text.length())
	text_label.text = full_text.substr(0, char_idx)


func _complete_typing() -> void:
	type_timer.stop()
	text_label.text = full_text
	char_idx = full_text.length()
	is_typing = false
	continue_hint.visible = true


func _on_ff_toggled(on: bool) -> void:
	speed_mult = 5.0 if on else 1.0
	# if toggled on while already waiting at a finished line, start advancing
	if on and not is_typing and not choice_box.visible and not transitioning:
		get_tree().create_timer(0.3).timeout.connect(func():
			if not transitioning:
				_advance())


func _advance() -> void:
	if transitioning:
		_skip_transition()  # clicks/space skip the transition
		return
	if choice_box.visible:
		return
	if is_typing:
		_complete_typing()
		return
	line_idx += 1
	_show_current_line()


func _on_lines_finished() -> void:
	if chapter.has("choice"):
		_show_choices(chapter["choice"])
	elif chapter.has("next"):
		_load_chapter(chapter["next"])
	else:
		_show_end_screen()


func _show_choices(choice_data: Dictionary) -> void:
	for c in choice_box.get_children():
		c.queue_free()

	var prompt := UIUtil.heading(choice_data.get("prompt", "What do you do?"), 20, UIUtil.PINK_DEEP)
	var prompt_panel := UIUtil.card_panel(16, 3)
	var pm := UIUtil.margin(18, 10, 18, 10)
	pm.add_child(prompt)
	prompt_panel.add_child(pm)
	choice_box.add_child(prompt_panel)

	var options: Array = choice_data.get("options", [])
	for opt in options:
		var btn := UIUtil.pill_button(String(opt.get("text", "...")), 620, 64)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_choice_selected.bind(opt))
		choice_box.add_child(btn)

	choice_box.visible = true
	# re-center based on content
	await get_tree().process_frame
	choice_box.position = Vector2(
		(get_viewport_rect().size.x - choice_box.size.x) / 2.0,
		max(90, (get_viewport_rect().size.y - choice_box.size.y) / 2.0 - 40)
	)


func _on_choice_selected(opt: Dictionary) -> void:
	var ch: String = opt.get("char", "")
	var pts: int = int(opt.get("points", 0))
	if ch != "" and pts != 0:
		GameState.add_points(ch, pts)
	choice_box.visible = false
	_load_chapter(String(opt.get("next", "game_end")))
	GameState.save_game()  # after loading: save points at the next chapter's start, not a replayable choice


func _on_scene_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		_advance()
	elif event.is_action_pressed("ui_cancel"):
		_open_pause_menu()


## Esc / gear icon: pause overlay — Resume, Save, Load, Flowchart, Main Menu.
func _open_pause_menu() -> void:
	if has_node("PauseOverlay"):
		return
	var p := UIUtil.popup("Settings")
	p["overlay"].name = "PauseOverlay"
	var vbox: VBoxContainer = p["vbox"]

	var resume_btn := UIUtil.pill_button("Resume", 260, 46)
	resume_btn.pressed.connect(func(): p["overlay"].queue_free())
	vbox.add_child(resume_btn)

	var save_btn := UIUtil.pill_button("Save", 260, 46)
	save_btn.pressed.connect(func(): _open_slot_popup(true))
	vbox.add_child(save_btn)

	var load_btn := UIUtil.pill_button("Load", 260, 46)
	load_btn.disabled = not GameState.has_save
	load_btn.pressed.connect(func(): _open_slot_popup(false))
	vbox.add_child(load_btn)

	var flow_btn := UIUtil.pill_button("Flowchart", 260, 46)
	flow_btn.pressed.connect(func():
		GameState.save_game()
		get_tree().change_scene_to_file("res://scenes/Flowchart.tscn")
	)
	vbox.add_child(flow_btn)

	var menu_btn := UIUtil.pill_button("Main Menu", 260, 46)
	menu_btn.pressed.connect(func():
		GameState.save_game()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	vbox.add_child(menu_btn)

	add_child(p["overlay"])


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
				_load_chapter(GameState.current_chapter_id, GameState.current_line_idx)
	, not is_save)
	vbox.add_child(grid)

	var cancel_btn := UIUtil.pill_button("Cancel", 260, 46)
	cancel_btn.pressed.connect(func(): p["overlay"].queue_free())
	vbox.add_child(cancel_btn)

	add_child(p["overlay"])


# --------------------------------------------------------------- end screen

func _show_end_screen() -> void:
	GameState.current_chapter_id = "game_end"
	GameState.save_game()

	for c in get_children():
		c.queue_free()

	add_child(UIUtil.dreamy_bg())

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := UIUtil.card_panel(28, 3)
	card.custom_minimum_size = Vector2(460, 0)
	center.add_child(card)

	var margin := UIUtil.margin(40, 36, 40, 36)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	vbox.add_child(UIUtil.heading("~ The End ~", 34, UIUtil.PINK_DEEP))

	var lead := GameState.get_leading_character()
	var lead_name: String = Story.ROUTE_NAMES.get(lead, lead.capitalize())
	vbox.add_child(UIUtil.body_label("Thanks for playing Office Hearts!", 16, UIUtil.PLUM_SOFT))
	vbox.add_child(UIUtil.body_label("Route taken: %s" % lead_name, 15, UIUtil.PLUM_SOFT))

	var endings_count: int = GameState.endings_unlocked.size()
	vbox.add_child(UIUtil.body_label("Endings unlocked: %d / 6" % endings_count, 15, UIUtil.PLUM_SOFT))

	vbox.add_child(HSeparator.new())

	var again_btn := UIUtil.pill_button("Play Again", 340, 50)
	again_btn.pressed.connect(func():
		GameState.reset_new_game()
		get_tree().change_scene_to_file("res://scenes/Game.tscn")
	)
	vbox.add_child(again_btn)

	var flow_btn := UIUtil.pill_button("Flowchart", 340, 50)
	flow_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Flowchart.tscn"))
	vbox.add_child(flow_btn)

	var menu_btn2 := UIUtil.pill_button("Main Menu", 340, 50)
	menu_btn2.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	vbox.add_child(menu_btn2)
