extends Control
## Main menu: title only (no sub-label) + Start / Load / Flowchart /
## Settings / Exit.

func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	add_child(UIUtil.cute_bg())

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	vbox.add_child(UIUtil.title_label("OFFICE HEARTS", 30))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(spacer)

	var start_btn := UIUtil.pill_button("Start")
	start_btn.pressed.connect(_on_new_game)
	vbox.add_child(start_btn)

	var load_btn := UIUtil.pill_button("Load")
	load_btn.disabled = not GameState.has_save
	load_btn.pressed.connect(_open_load)
	vbox.add_child(load_btn)

	var settings_btn := UIUtil.pill_button("Settings")
	settings_btn.pressed.connect(_open_settings)
	vbox.add_child(settings_btn)

	var exit_btn := UIUtil.pill_button("Exit")
	exit_btn.pressed.connect(func(): get_tree().quit())
	vbox.add_child(exit_btn)

	var gear := UIUtil.gear_button()
	gear.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	gear.position = Vector2(-68, -68)
	gear.pressed.connect(_open_settings)
	add_child(gear)


func _open_settings() -> void:
	var p := UIUtil.popup("Settings")
	var vbox: VBoxContainer = p["vbox"]

	vbox.add_child(UIUtil.volume_row())

	var flow_btn := UIUtil.pill_button("Flowchart", 260, 46)
	flow_btn.pressed.connect(func():
		p["overlay"].queue_free()
		get_tree().change_scene_to_file("res://scenes/Flowchart.tscn")
	)
	vbox.add_child(flow_btn)

	var close_btn := UIUtil.pill_button("Close", 260, 46)
	close_btn.pressed.connect(func(): p["overlay"].queue_free())
	vbox.add_child(close_btn)

	add_child(p["overlay"])


func _open_load() -> void:
	var p := UIUtil.popup("Load Game")
	var vbox: VBoxContainer = p["vbox"]
	vbox.add_child(UIUtil.slot_grid(GameState.all_slot_summaries(), _on_slot_picked, true))

	var cancel_btn := UIUtil.pill_button("Cancel", 260, 46)
	cancel_btn.pressed.connect(func(): p["overlay"].queue_free())
	vbox.add_child(cancel_btn)

	add_child(p["overlay"])


func _on_slot_picked(slot: int) -> void:
	if GameState.load_from_slot(slot):
		get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_new_game() -> void:
	GameState.reset_new_game()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
