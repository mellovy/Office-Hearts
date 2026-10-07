extends Control
## Main menu: soft pastel title card with a rounded frame, decorative
## heart ornaments, and cute menu buttons.

func _ready() -> void:
	UIUtil.apply_saved_display()
	Audio.play_bgm("upbeat")
	_build_ui()
	UIUtil.fade_in(self)


func _unhandled_input(event: InputEvent) -> void:
	if UIUtil.handle_fullscreen_input(event):
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	add_child(UIUtil.cute_bg())

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var title := UIUtil.title_label("OFFICE HEARTS", 58, UIUtil.WINE, UIUtil.PINK_DEEP)
	title.modulate.a = 0.0
	vbox.add_child(title)
	title.create_tween().tween_property(title, "modulate:a", 1.0, 0.45)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(spacer)

	var start_btn := UIUtil.pill_button("Start", 360, 64)
	start_btn.pressed.connect(_on_new_game)
	vbox.add_child(start_btn)

	var continue_btn := UIUtil.pill_button("Continue", 360, 64)
	continue_btn.disabled = not GameState.has_save
	continue_btn.pressed.connect(_on_continue)
	vbox.add_child(continue_btn)

	var load_btn := UIUtil.pill_button("Load", 360, 64)
	load_btn.disabled = not GameState.has_save
	load_btn.pressed.connect(_open_load)
	vbox.add_child(load_btn)

	var gallery_btn := UIUtil.pill_button("Gallery", 360, 64)
	gallery_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Gallery.tscn"))
	vbox.add_child(gallery_btn)

	var settings_btn := UIUtil.pill_button("Settings", 360, 64)
	settings_btn.pressed.connect(_open_settings)
	vbox.add_child(settings_btn)

	var exit_btn := UIUtil.pill_button("Exit", 360, 64)
	exit_btn.pressed.connect(func(): get_tree().quit())
	vbox.add_child(exit_btn)

	UIUtil.focus_first(self)


func _open_settings() -> void:
	var ov := UIUtil.settings_overlay()
	add_child(ov)
	UIUtil.focus_first(ov)


func _open_load() -> void:
	var p := UIUtil.popup("Load Game")
	var vbox: VBoxContainer = p["vbox"]
	vbox.add_child(UIUtil.slot_grid(GameState.all_slot_summaries(), _on_slot_picked, true))

	var cancel_btn := UIUtil.pill_button("Cancel", 300, 48, "red")
	cancel_btn.pressed.connect(func(): p["overlay"].queue_free())
	vbox.add_child(cancel_btn)

	add_child(p["overlay"])
	UIUtil.focus_first(p["overlay"])


func _on_slot_picked(slot: int) -> void:
	if GameState.load_from_slot(slot):
		get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_new_game() -> void:
	GameState.reset_new_game()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


## Index of the most recently saved slot (0 when there is no save).
func _most_recent_slot() -> int:
	var best := 0
	var best_when := ""
	var summaries: Array = GameState.all_slot_summaries()
	for i in range(summaries.size()):
		var info: Dictionary = summaries[i]
		if not bool(info.get("exists", false)):
			continue
		var when := String(info.get("when", ""))
		if when >= best_when:
			best_when = when
			best = i + 1
	return best


## Continue: resume the most recent save through the same path Load uses.
func _on_continue() -> void:
	var slot := _most_recent_slot()
	if slot <= 0:
		return
	if GameState.load_from_slot(slot):
		get_tree().change_scene_to_file("res://scenes/Game.tscn")
