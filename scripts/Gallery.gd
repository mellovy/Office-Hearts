extends Control
## Endings gallery: shows all 9 route endings. Unlocked ones reveal the
## ending name + blurb with a route-colored border; locked ones stay hidden.

func _ready() -> void:
	Audio.play_bgm("warm")
	_build_ui()
	UIUtil.fade_in(self)


func _build_ui() -> void:
	add_child(UIUtil.cute_bg())

	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 20
	top.offset_top = 16
	top.offset_right = -20
	add_child(top)

	var back_btn := UIUtil.back_button("Back", 128, 48)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	top.add_child(back_btn)

	var title_center := CenterContainer.new()
	title_center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_center.offset_left = 20
	title_center.offset_top = 10
	title_center.offset_right = -20
	title_center.offset_bottom = 62
	title_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_center.add_child(UIUtil.title_label("ENDINGS GALLERY", 28, UIUtil.TEXT_DARK))
	add_child(title_center)

	var total: int = Story.ENDING_IDS.size()
	var unlocked: int = 0
	for id in Story.ENDING_IDS:
		if GameState.endings_unlocked.has(id):
			unlocked += 1

	var progress := UIUtil.body_label("Endings unlocked: %d / %d" % [unlocked, total], 20, UIUtil.TEXT_DARK)
	progress.set_anchors_preset(Control.PRESET_TOP_WIDE)
	progress.offset_top = 58
	progress.offset_bottom = 84
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(progress)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 92
	scroll.offset_left = 16
	scroll.offset_right = -16
	scroll.offset_bottom = -16
	add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	center.add_child(grid)

	var cards: Array = []
	for id in Story.ENDING_IDS:
		var card := _ending_card(String(id))
		cards.append(card)
		grid.add_child(card)

	UIUtil.focus_first(self)
	await get_tree().process_frame
	UIUtil.stagger_in(cards)


func _ending_card(id: String) -> Control:
	var route := id.split("_")[0]
	var unlocked: bool = GameState.endings_unlocked.has(id)
	var is_true := id.ends_with("_end_true")
	var col: Color = UIUtil.route_color(route)

	var fc := UIUtil.frame_card(22, 14)
	var card: PanelContainer = fc["frame"]
	card.custom_minimum_size = Vector2(380, 210)
	UIUtil.hover_scale(card, 1.03)
	var border: Color = UIUtil.GOLD if (unlocked and is_true) else (col if unlocked else Color("#B9A9B4"))
	fc["frame"].frame_col = border
	fc["frame"].heart_col = Color(1, 1, 1, 0.8) if unlocked else Color(1, 1, 1, 0.4)

	var m: MarginContainer = fc["content"]
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	m.add_child(v)

	var route_lbl := UIUtil.body_label(Story.ROUTE_NAMES.get(route, route.capitalize()), 18, col if unlocked else UIUtil.TEXT_MUTED)
	route_lbl.clip_text = false
	v.add_child(route_lbl)
	# Real checkmark badge for unlocked endings (no layout change).
	if unlocked:
		var chk := UIUtil.icon_rect(UIUtil.TEX_ICON_CHECK, 22, UIUtil.GOLD if is_true else UIUtil.SKY)
		route_lbl.add_child(chk)
		var place_chk := func(): chk.position = Vector2(route_lbl.size.x - 24.0, -4.0)
		place_chk.call()
		route_lbl.resized.connect(place_chk)

	if not unlocked:
		var locked := UIUtil.heading("??? LOCKED", 18, UIUtil.TEXT_MUTED)
		locked.clip_text = false
		v.add_child(locked)
		var hint := UIUtil.body_label("Reach this ending to reveal it.", 18, UIUtil.TEXT_MUTED)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.custom_minimum_size = Vector2(320, 0)
		v.add_child(hint)
		return card

	var chapter: Dictionary = Story.get_chapter(id)
	var name_lbl := UIUtil.heading(String(chapter.get("ending_name", chapter.get("title", id))), 18, UIUtil.TEXT_DARK)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_lbl.clip_text = false
	v.add_child(name_lbl)

	var desc := UIUtil.body_label(String(chapter.get("ending_desc", chapter.get("location", ""))), 19, UIUtil.TEXT_MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.clip_text = false
	desc.custom_minimum_size = Vector2(320, 0)
	v.add_child(desc)

	if is_true:
		var star := UIUtil.body_label("★ TRUE ENDING", 18, UIUtil.GOLD)
		star.clip_text = false
		v.add_child(star)

	return card
