extends Node
## Global game state: affection points, story flags, and progress tracking.
## Autoloaded as "GameState". Supports 6 manual save slots.

signal points_changed(character: String, new_value: int)

const SLOT_COUNT := 6
const SAVE_PATH_FMT := "user://office_hearts_slot%d.json"

var points: Dictionary = {
	"arthur": 0,
	"dante": 0,
	"leo": 0,
}

var current_chapter_id: String = "common_ch1"
var current_slot: int = 1

# Every chapter id the player has ever seen (for the flowchart map).
var visited: Dictionary = {}

# Every ending id the player has unlocked (for the flowchart + gallery).
var endings_unlocked: Dictionary = {}

var found_flashdrive: bool = false
var suspect_identified: bool = false

var has_save: bool = false


func _ready() -> void:
	_refresh_has_save()


func reset_new_game() -> void:
	points = {"arthur": 0, "dante": 0, "leo": 0}
	current_chapter_id = "common_ch1"
	visited = {}
	endings_unlocked = {}
	found_flashdrive = false
	suspect_identified = false


func add_points(character: String, amount: int) -> void:
	if character == "":
		return
	points[character] = points.get(character, 0) + amount
	points_changed.emit(character, points[character])


func mark_visited(chapter_id: String) -> void:
	visited[chapter_id] = true


func mark_ending(ending_id: String) -> void:
	endings_unlocked[ending_id] = true


func get_leading_character() -> String:
	var best := "arthur"
	for c in points.keys():
		if points[c] > points.get(best, 0):
			best = c
	return best


# ------------------------------------------------------------- slot saves

func slot_path(slot: int) -> String:
	return SAVE_PATH_FMT % slot


func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


## Light metadata for a slot picker card, without touching current state.
func slot_summary(slot: int) -> Dictionary:
	if not slot_exists(slot):
		return {"exists": false, "title": "", "when": ""}
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	if not f:
		return {"exists": false, "title": "", "when": ""}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"exists": false, "title": "", "when": ""}
	var chap_id: String = parsed.get("current_chapter_id", "")
	var title := "The End" if chap_id == "game_end" else String(Story.get_chapter(chap_id).get("title", chap_id))
	return {"exists": true, "title": title, "when": String(parsed.get("saved_at", ""))}


func all_slot_summaries() -> Array:
	var out := []
	for i in range(1, SLOT_COUNT + 1):
		out.append(slot_summary(i))
	return out


func save_to_slot(slot: int) -> void:
	current_slot = slot
	var data := {
		"points": points,
		"current_chapter_id": current_chapter_id,
		"visited": visited,
		"endings_unlocked": endings_unlocked,
		"found_flashdrive": found_flashdrive,
		"suspect_identified": suspect_identified,
		"saved_at": Time.get_datetime_string_from_system(false, true),
	}
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()
	_refresh_has_save()


func load_from_slot(slot: int) -> bool:
	if not slot_exists(slot):
		return false
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	if not f:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	points = parsed.get("points", points)
	current_chapter_id = parsed.get("current_chapter_id", "common_ch1")
	visited = parsed.get("visited", {})
	endings_unlocked = parsed.get("endings_unlocked", {})
	found_flashdrive = parsed.get("found_flashdrive", false)
	suspect_identified = parsed.get("suspect_identified", false)
	current_slot = slot
	return true


func delete_slot(slot: int) -> void:
	if slot_exists(slot):
		DirAccess.remove_absolute(slot_path(slot))
	_refresh_has_save()


func _refresh_has_save() -> void:
	has_save = false
	for i in range(1, SLOT_COUNT + 1):
		if slot_exists(i):
			has_save = true
			return


# --------------------------------------------------- back-compat shims
# Quick autosave/continue on the current slot (used mid-chapter, on the
# "return to menu" action, and on the ending screen).

func save_game() -> void:
	save_to_slot(current_slot)


func load_game() -> bool:
	return load_from_slot(current_slot)
