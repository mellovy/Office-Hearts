extends Node
## Global game state: affection, relationship ranks, story flags, and progress.
## Autoloaded as "GameState". Supports 6 manual save slots.

signal points_changed(character: String, new_value: int)

const SLOT_COUNT := 6
const SAVE_PATH_FMT := "user://office_hearts_slot%d.json"

const CHARACTERS: Array = ["arthur", "dante", "leo"]

# Affection is capped so hub grinding can't trivially max everyone.
const MAX_AFFECTION := 30

# Relationship ranks, indexed by RANK_MIN thresholds.
const RANKS: Array = ["Stranger", "Colleague", "Friend", "Crush", "Partner"]
const RANK_MIN: Array = [0, 5, 10, 16, 24]

var points: Dictionary = {
	"arthur": 0,
	"dante": 0,
	"leo": 0,
}

var current_chapter_id: String = "common_ch1"
var current_line_idx: int = 0  # position within the current chapter (for exact save/resume)
var current_slot: int = 1

# Every chapter id the player has ever seen (for the flowchart map).
var visited: Dictionary = {}

# Every ending id the player has unlocked (for the flowchart + gallery).
var endings_unlocked: Dictionary = {}

# The ending most recently reached (for the end screen).
var last_ending_id: String = ""

# Arbitrary story flags set by choices (route_evidence, hub_*_done, ...).
var flags: Dictionary = {}

var found_flashdrive: bool = false
var suspect_identified: bool = false

var has_save: bool = false


func _ready() -> void:
	_refresh_has_save()


func reset_new_game() -> void:
	points = {"arthur": 0, "dante": 0, "leo": 0}
	current_chapter_id = "common_ch1"
	current_line_idx = 0
	visited = {}
	endings_unlocked = {}
	last_ending_id = ""
	flags = {}
	found_flashdrive = false
	suspect_identified = false


# ------------------------------------------------------------- affection

func add_affection(character: String, amount: int) -> void:
	if character == "":
		return
	var new_value: int = int(points.get(character, 0)) + amount
	new_value = clamp(new_value, 0, MAX_AFFECTION)
	points[character] = new_value
	points_changed.emit(character, new_value)


## Back-compat alias used by older call sites.
func add_points(character: String, amount: int) -> void:
	add_affection(character, amount)


func affection(character: String) -> int:
	return int(points.get(character, 0))


func rank_index(character: String) -> int:
	var aff := affection(character)
	var idx := 0
	for i in range(RANK_MIN.size()):
		if aff >= int(RANK_MIN[i]):
			idx = i
	return idx


func rank_name(character: String) -> String:
	return String(RANKS[rank_index(character)])


# ------------------------------------------------------------- flags

func set_flag(name: String) -> void:
	if name == "":
		return
	flags[name] = true


func has_flag(name: String) -> bool:
	return flags.get(name, false) == true


# ------------------------------------------------------------- progress

func mark_visited(chapter_id: String) -> void:
	visited[chapter_id] = true


func mark_ending(ending_id: String) -> void:
	endings_unlocked[ending_id] = true
	last_ending_id = ending_id


func get_leading_character() -> String:
	var best := "arthur"
	for c in CHARACTERS:
		if affection(String(c)) > affection(best):
			best = String(c)
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
		"current_line_idx": current_line_idx,
		"visited": visited,
		"endings_unlocked": endings_unlocked,
		"last_ending_id": last_ending_id,
		"flags": flags,
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
	var loaded_points: Dictionary = parsed.get("points", points)
	for key in loaded_points.keys():
		loaded_points[key] = int(loaded_points[key])  # JSON parses numbers as float
	points = loaded_points
	current_chapter_id = parsed.get("current_chapter_id", "common_ch1")
	current_line_idx = int(parsed.get("current_line_idx", 0))
	visited = parsed.get("visited", {})
	endings_unlocked = parsed.get("endings_unlocked", {})
	last_ending_id = String(parsed.get("last_ending_id", ""))
	flags = parsed.get("flags", {})
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
