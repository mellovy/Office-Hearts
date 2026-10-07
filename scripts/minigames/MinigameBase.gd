class_name MinigameBase
extends Control
## Base class for every Office Hearts minigame.
##
## CONTRACT (frozen - do not change without updating MinigameRegistry and Game.gd):
##   - Subclass in its own file, set `const ID`, implement `static func meta()` and `func _build()`.
##   - `setup(cfg)` is called once by Game.gd before the node is shown.
##   - Emit `finished(success, result)` EXACTLY ONCE. Call `_finish(...)` to do so safely.
##   - Keyboard-usable: Esc always forfeits via `_finish(false, {"forfeit": true})`.
##   - Build UI in code; never create .tscn files.

signal finished(success: bool, result: Dictionary)

const ID := ""

var cfg: Dictionary = {}
var rng := RandomNumberGenerator.new()
var _done := false


static func meta() -> Dictionary:
	## Override. {id, title, blurb, instructions}
	return {"id": ID, "title": "", "blurb": "", "instructions": ""}


func setup(c: Dictionary) -> void:
	## cfg keys: title, prompt, difficulty (0..1), seed (int), accent (Color)
	cfg = c
	var seed_val: int = int(cfg.get("seed", 0))
	if seed_val == 0:
		seed_val = int(Time.get_unix_time_from_system())
	rng.seed = seed_val
	custom_minimum_size = Vector2(720.0, 420.0)
	_build()


func _build() -> void:
	## Override: construct the minigame UI.
	pass


func _difficulty() -> float:
	return clampf(float(cfg.get("difficulty", 0.5)), 0.0, 1.0)


func _accent() -> Color:
	var c = cfg.get("accent", null)
	if c is Color:
		return c
	return Color("#E8447E")


func _finish(success: bool, result: Dictionary = {}) -> void:
	if _done:
		return
	_done = true
	finished.emit(success, result)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_finish(false, {"forfeit": true})
		get_viewport().set_input_as_handled()
