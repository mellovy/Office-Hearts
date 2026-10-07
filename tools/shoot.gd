extends Node
## Throwaway screenshot harness: loads the real scenes into the viewport and
## captures PNGs so the restyle can be eyeballed. Run:
##   godot --path . res://tools/shoot.tscn

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://_shots")
	await get_tree().process_frame
	await _main_menu()
	await _dialogue("common_ch1", 19, "02_dialogue")
	await _dialogue("common_ch1", 6, "02b_dialogue_dante")
	await _dialogue("common_ch1", 11, "02c_dialogue_leo")
	await _pause()
	await _choices()
	await _status()
	await _fallback()
	await _tall()
	await _gallery()
	await _flowchart()
	await _settings()
	await _accessibility()
	await _slots()
	await _save_slots()
	await _sterling()
	await _toasts()
	await _box_opacity()
	await _continue_states()
	await _end_screen()
	get_tree().quit()


func _load(path: String) -> Node:
	for c in get_children():
		c.free()
	await get_tree().process_frame
	var inst: Node = load(path).instantiate()
	add_child(inst)
	return inst


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://_shots/%s.png" % name)
	print("SHOT ", name)


func _main_menu() -> void:
	await _load("res://scenes/MainMenu.tscn")
	await _wait(1.2)
	await _shot("01_mainmenu")


func _dialogue(chapter: String, line: int, name: String) -> void:
	GameState.current_chapter_id = chapter
	GameState.current_line_idx = line
	var game := await _load("res://scenes/Game.tscn")
	await _wait(3.2)
	if game.has_method("_complete_typing"):
		game._complete_typing()
	await _wait(0.4)
	await _shot(name)


func _pause() -> void:
	var game := get_child(get_child_count() - 1)
	if game.has_method("_open_pause_menu"):
		game._open_pause_menu()
	await _wait(0.5)
	await _shot("03_pause")
	var ov := game.get_node_or_null("PauseOverlay")
	if ov:
		ov.queue_free()
	await _wait(0.2)
	# In-game Settings screen (pause → Settings).
	if game.has_method("_open_settings"):
		game._open_settings()
	await _wait(0.6)
	await _shot("19_pause_settings")
	if game.modal != null and is_instance_valid(game.modal):
		game.modal.queue_free()
	await _wait(0.2)


func _choices() -> void:
	var game := get_child(get_child_count() - 1)
	var ch: Dictionary = Story.get_chapter("hub")
	if game.has_method("_show_choices") and ch.has("choice"):
		game._show_choices(ch["choice"])
	await _wait(0.6)
	await _shot("04_choices")


func _status() -> void:
	GameState.points["arthur"] = 14
	GameState.points["dante"] = 6
	GameState.points["leo"] = 22
	var game := get_child(get_child_count() - 1)
	if game.has_method("_open_status"):
		game._open_status()
	await _wait(0.5)
	await _shot("05_status")


func _fallback() -> void:
	GameState.current_chapter_id = "hub_arthur"
	GameState.current_line_idx = 1
	var game := await _load("res://scenes/Game.tscn")
	await _wait(3.2)
	if game.has_method("_complete_typing"):
		game._complete_typing()
	await _wait(0.4)
	await _shot("08_fallback")


func _tall() -> void:
	GameState.current_chapter_id = "common_ch1"
	GameState.current_line_idx = 19
	var game := await _load("res://scenes/Game.tscn")
	await _wait(3.2)
	if game.has_method("_complete_typing"):
		game._complete_typing()
	var w := get_window()
	w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	w.size = Vector2i(960, 1080)
	await _wait(0.8)
	await _shot("09_dialogue_tall")
	w.size = Vector2i(1280, 720)
	w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	await _wait(0.4)


func _gallery() -> void:
	await _load("res://scenes/Gallery.tscn")
	await _wait(0.8)
	await _shot("06_gallery")


func _flowchart() -> void:
	await _load("res://scenes/Flowchart.tscn")
	await _wait(0.8)
	await _shot("07_flowchart")


func _settings() -> void:
	# Show the reworked panel with some non-default values applied.
	UIUtil.set_text_speed(2.0)
	UIUtil.set_auto_delay(2.6)
	UIUtil.set_skip_mode(UIUtil.SKIP_READ)
	UIUtil.set_box_opacity(0.85)
	var menu := await _load("res://scenes/MainMenu.tscn")
	await _wait(0.6)
	if menu.has_method("_open_settings"):
		menu._open_settings()
	await _wait(0.5)
	await _shot("10_settings")
	UIUtil.set_text_speed(UIUtil.TEXT_SPEED_DEFAULT)
	UIUtil.set_auto_delay(UIUtil.AUTO_DELAY_DEFAULT)
	UIUtil.set_skip_mode(UIUtil.SKIP_OFF)
	UIUtil.set_box_opacity(UIUtil.BOX_OPACITY_DEFAULT)


func _box_opacity() -> void:
	UIUtil.set_box_opacity(UIUtil.BOX_OPACITY_MIN)
	GameState.current_chapter_id = "common_ch1"
	GameState.current_line_idx = 19
	var game := await _load("res://scenes/Game.tscn")
	await _wait(3.2)
	if game.has_method("_complete_typing"):
		game._complete_typing()
	await _wait(0.4)
	await _shot("18_box_opacity")
	UIUtil.set_box_opacity(UIUtil.BOX_OPACITY_DEFAULT)


func _slots() -> void:
	var menu := await _load("res://scenes/MainMenu.tscn")
	await _wait(0.6)
	if menu.has_method("_open_load"):
		menu._open_load()
	await _wait(0.6)
	await _shot("12_slots_load")


func _save_slots() -> void:
	var game := await _load("res://scenes/Game.tscn")
	await _wait(3.0)
	if game.has_method("_open_slot_popup"):
		game._open_slot_popup(true)
	await _wait(0.6)
	await _shot("13_slots_save")


func _sterling() -> void:
	GameState.current_chapter_id = "arthur_ch6"
	GameState.current_line_idx = 1
	var game := await _load("res://scenes/Game.tscn")
	await _wait(3.2)
	if game.has_method("_complete_typing"):
		game._complete_typing()
	await _wait(0.4)
	await _shot("15_no_portrait")


func _toasts() -> void:
	var game := await _load("res://scenes/Game.tscn")
	await _wait(3.2)
	if game.has_method("_complete_typing"):
		game._complete_typing()
	# +3 toast
	GameState.points["arthur"] = 4
	game._last_points["arthur"] = 4
	GameState.add_affection("arthur", 3)
	await _wait(0.35)
	await _shot("16_toast_pos")
	# -2 toast (replaces the previous one)
	GameState.points["dante"] = 6
	game._last_points["dante"] = 6
	GameState.add_affection("dante", -2)
	await _wait(0.35)
	await _shot("17_toast_neg")


func _accessibility() -> void:
	UIUtil.set_large_text(true)
	UIUtil.set_reduce_motion(true)
	var menu := await _load("res://scenes/MainMenu.tscn")
	await _wait(0.6)
	if menu.has_method("_open_settings"):
		menu._open_settings()
	await _wait(0.5)
	await _shot("22_settings_access")
	# Large Text: Arthur's 4-line briefing must not clip.
	GameState.current_chapter_id = "common_ch1"
	GameState.current_line_idx = 19
	var game := await _load("res://scenes/Game.tscn")
	await _wait(3.2)
	if game.has_method("_complete_typing"):
		game._complete_typing()
	await _wait(0.4)
	await _shot("23_large_text")
	UIUtil.set_large_text(false)
	UIUtil.set_reduce_motion(false)


func _continue_states() -> void:
	# No saves → Continue is muted.
	for i in range(1, GameState.SLOT_COUNT + 1):
		GameState.delete_slot(i)
	await _load("res://scenes/MainMenu.tscn")
	await _wait(0.8)
	await _shot("20_continue_off")
	# A save exists → Continue is enabled.
	GameState.save_to_slot(1)
	await _load("res://scenes/MainMenu.tscn")
	await _wait(0.8)
	await _shot("21_continue_on")


func _end_screen() -> void:
	GameState.last_ending_id = "arthur_end_true"
	GameState.endings_unlocked["arthur_end_true"] = true
	var game := await _load("res://scenes/Game.tscn")
	await _wait(3.0)
	if game.has_method("_show_end_screen"):
		game._show_end_screen()
	await _wait(1.0)
	await _shot("11_end")
