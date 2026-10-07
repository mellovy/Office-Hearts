extends Node
## TEMPORARY performance harness (delete after use).
## Run: godot --path . res://tools/perf_test.tscn
## Disables vsync so the frame time reflects real work, then samples the
## renderer counters for a few seconds per scene.

const FRAMES := 240

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await get_tree().process_frame
	await _measure("res://scenes/MainMenu.tscn", "MainMenu(cute_bg)")
	await _measure("res://scenes/Game.tscn", "Game")
	get_tree().quit()


func _measure(path: String, label: String) -> void:
	for c in get_children():
		c.free()
	await get_tree().process_frame
	GameState.current_chapter_id = "common_ch1"
	GameState.current_line_idx = 19
	add_child(load(path).instantiate())
	await get_tree().create_timer(3.0).timeout   # settle (transition/fade)
	for i in 30:
		await get_tree().process_frame             # warm-up

	var draws := 0.0
	var prims := 0.0
	var proc := 0.0
	var t0 := Time.get_ticks_usec()
	for i in FRAMES:
		await get_tree().process_frame
		draws += float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		prims += float(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		proc += float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0
	var frame_ms := float(Time.get_ticks_usec() - t0) / float(FRAMES) / 1000.0
	print("PERF %-20s frame=%.2fms  process=%.3fms  draw_calls=%d  primitives=%d" % [
		label, frame_ms, proc / float(FRAMES), int(draws / float(FRAMES)), int(prims / float(FRAMES))])
