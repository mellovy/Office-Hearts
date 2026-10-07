class_name MinigameRegistry
extends RefCounted
## Maps minigame ids to their scripts and instantiates them.
## Resolution is lazy + existence-checked so a missing minigame degrades to
## "no minigame" instead of crashing the game.

const PATHS := {
	"evidence_hunt": "res://scripts/minigames/EvidenceHunt.gd",
	"latte_timing": "res://scripts/minigames/LatteTiming.gd",
	"password_deduction": "res://scripts/minigames/PasswordDeduction.gd",
	"watermark_forensics": "res://scripts/minigames/WatermarkForensics.gd",
	"surveillance_dodge": "res://scripts/minigames/SurveillanceDodge.gd",
	"boardroom_rebuttal": "res://scripts/minigames/BoardroomRebuttal.gd",
	"pursuit_chase": "res://scripts/minigames/PursuitChase.gd",
}


static func ids() -> PackedStringArray:
	return PackedStringArray(PATHS.keys())


static func has(id: String) -> bool:
	return PATHS.has(id) and ResourceLoader.exists(PATHS[id])


static func meta(id: String) -> Dictionary:
	if not has(id):
		return {}
	var inst := create(id)
	if inst == null:
		return {}
	var m := inst.meta()
	inst.free()
	return m


static func create(id: String) -> MinigameBase:
	if not has(id):
		return null
	var scr: GDScript = load(PATHS[id])
	var inst: MinigameBase = scr.new()
	return inst
