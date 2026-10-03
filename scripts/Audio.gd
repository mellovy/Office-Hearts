extends Node

# ------------------------------------------------------------------
# Audio autoload – centralised music / SFX handling for Office Hearts.
# ------------------------------------------------------------------

# Bus names – created if missing.
const MUSIC_BUS := "Music"
const SFX_BUS  := "SFX"

# Persistent volume settings – defaults are full volume.
var _volumes : Dictionary = {
	"music": 1.0,
	"sfx":   1.0
}

# Audio dictionaries – mapping names to AudioStream resources.
var _sfx  : Dictionary = {}
var _bgm  : Dictionary = {}

# Background‑music player.
var _bgm_player : AudioStreamPlayer
var _bgm_tween  : Tween

# ------------------------------------------------------------------
# Life cycle.
# ------------------------------------------------------------------
func _ready() -> void:
	_ensure_buses()
	_load_assets()
	_load_settings()
	_create_bgm_player()

	print("Audio ready, buses: ", AudioServer.bus_count)
	play_bgm("upbeat")

# ------------------------------------------------------------------
# Bus utilities.
# ------------------------------------------------------------------
func _ensure_buses() -> void:
	var bus_idx := AudioServer.get_bus_index(MUSIC_BUS)
	if bus_idx == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, MUSIC_BUS)
		AudioServer.set_bus_volume_db(AudioServer.bus_count - 1, 0)
	bus_idx = AudioServer.get_bus_index(SFX_BUS)
	if bus_idx == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, SFX_BUS)
		AudioServer.set_bus_volume_db(AudioServer.bus_count - 1, 0)

# ------------------------------------------------------------------
# Asset loading.
# ------------------------------------------------------------------
func _load_assets() -> void:
	# SFX.
	_sfx["blip"]   = preload("res://assets/audio/sfx_blip.wav")
	_sfx["click"]  = preload("res://assets/audio/sfx_click.wav")
	_sfx["whoosh"] = preload("res://assets/audio/sfx_whoosh.wav")
	_sfx["choice"] = preload("res://assets/audio/sfx_choice.wav")
	_sfx["chime"]  = preload("res://assets/audio/sfx_chime.wav")
	_sfx["ending"] = preload("res://assets/audio/sfx_ending.wav")

	# BGM.
	_bgm["upbeat"] = preload("res://assets/audio/bgm_upbeat.wav")
	_bgm["tense"] = preload("res://assets/audio/bgm_tense.wav")
	_bgm["mystery"] = preload("res://assets/audio/bgm_mystery.wav")
	_bgm["warm"]   = preload("res://assets/audio/bgm_warm.wav")
	_bgm["sad"]     = preload("res://assets/audio/bgm_sad.wav")

# ------------------------------------------------------------------
# Settings persistence.
# ------------------------------------------------------------------
func _load_settings() -> void:
	var f = FileAccess.open("user://audio_settings.json", FileAccess.READ)
	if f:
		var content = f.get_as_text()
		var data = JSON.parse_string(content)
		if typeof(data) == TYPE_DICTIONARY:
			_volumes = data
	_apply_volumes()

func _save_settings() -> void:
	var f = FileAccess.open("user://audio_settings.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_volumes))

func _apply_volumes() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS), linear_to_db(_volumes["music"]))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS), linear_to_db(_volumes["sfx"]))

# ------------------------------------------------------------------
# Public API.
# ------------------------------------------------------------------
func play_sfx(sfx_name: String) -> void:
	if not _sfx.has(sfx_name):
		return
	var p = AudioStreamPlayer.new()
	p.stream = _sfx[sfx_name]
	p.bus = SFX_BUS
	p.autoplay = true
	p.finished.connect(p.queue_free)
	add_child(p)

func play_bgm(key: String) -> void:
	if not _bgm.has(key):
		return
	if _bgm_player.playing and _bgm_player.stream == _bgm[key]:
		return
	if _bgm_tween:
		_bgm_tween.kill()
	if _bgm_player.playing:
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(_bgm_player, "volume_db", -80.0, 1.0)
		_bgm_tween.tween_callback(_start_bgm.bind(key))
	else:
		_start_bgm(key)

func _start_bgm(key: String) -> void:
	_bgm_player.stop()
	_bgm_player.stream = _bgm[key]
	_bgm_player.volume_db = 0.0
	_bgm_player.play()

func set_volume(bus_name: String, val: float) -> void:
	val = clamp(val, 0.0, 1.0)
	var idx = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(val))
	if bus_name == MUSIC_BUS:
		_volumes["music"] = val
	elif bus_name == SFX_BUS:
		_volumes["sfx"] = val
	_save_settings()

func get_volume(bus_name: String) -> float:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx))

# ------------------------------------------------------------------
# BGM player creation.
# ------------------------------------------------------------------
func _create_bgm_player() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = MUSIC_BUS
	_bgm_player.finished.connect(func(): _bgm_player.play())
	add_child(_bgm_player)

# ------------------------------------------------------------------
# Volume sliders (used by UIUtil).
# ------------------------------------------------------------------
func _create_volume_slider(bus_name: String) -> HSlider:
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.custom_minimum_size = Vector2(180, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value = get_volume(bus_name)
	slider.value_changed.connect(func(v: float): set_volume(bus_name, v))
	return slider
