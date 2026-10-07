extends Node

# ------------------------------------------------------------------
# Audio autoload – centralised music / SFX handling for Office Hearts.
# Scenes request their own BGM; this autoload does not autoplay.
# ------------------------------------------------------------------

# Bus names – created if missing.
const MUSIC_BUS := "Music"
const SFX_BUS  := "SFX"
# Dedicated duck bus: BGM players route here so ducking never touches the
# user's Music-bus volume (the Settings slider keeps its full meaning).
const DUCK_BUS := "BGM"

# Canonical mood keys used by chapter data (`bgm_key`).
const MOODS: Array = ["upbeat", "tense", "mystery", "warm", "sad"]

const SILENT_DB := -80.0      # effectively muted
const CROSSFADE_TIME := 0.7   # seconds for one track to hand over to the next
const DUCK_DB := -12.0        # ~25% linear
const DUCK_FADE := 0.25

# Persistent volume settings – defaults are full volume.
var _volumes : Dictionary = {
	"music": 1.0,
	"sfx":   1.0
}

# Audio dictionaries – mapping names to AudioStream resources.
var _sfx  : Dictionary = {}
var _bgm  : Dictionary = {}

# Background‑music players. Two players let tracks crossfade; `_bgm_active` is
# whichever is currently audible.
var _bgm_player   : AudioStreamPlayer
var _bgm_player_b : AudioStreamPlayer
var _bgm_active   : AudioStreamPlayer
var _bgm_key      : String = ""
var _bgm_tween    : Tween

# Ducking.
var _duck_tween   : Tween
var _duck_current : float = 0.0

# ------------------------------------------------------------------
# Life cycle.
# ------------------------------------------------------------------
func _ready() -> void:
	_ensure_buses()
	_load_assets()
	_load_settings()
	_create_bgm_player()

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
	# Duck bus feeds into Music so the user's slider still scales BGM.
	bus_idx = AudioServer.get_bus_index(DUCK_BUS)
	if bus_idx == -1:
		AudioServer.add_bus()
		bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_idx, DUCK_BUS)
		AudioServer.set_bus_send(bus_idx, MUSIC_BUS)
		AudioServer.set_bus_volume_db(bus_idx, 0)

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

## Play a mood track, crossfading from whatever is currently playing.
## Empty/unknown keys are ignored (never crash); re-requesting the key that is
## already playing does nothing.
func play_bgm(key: String) -> void:
	if key == "" or not _bgm.has(key):
		return
	if _bgm_player == null or _bgm_player_b == null:
		return
	if key == _bgm_key and _bgm_active != null and _bgm_active.playing:
		return

	# The inactive player takes the incoming track; the active one fades out.
	var incoming: AudioStreamPlayer = _bgm_player_b if _bgm_active == _bgm_player else _bgm_player
	var outgoing: AudioStreamPlayer = _bgm_active
	_kill_bgm_tween()

	_bgm_key = key
	_bgm_active = incoming
	incoming.stop()
	incoming.stream = _bgm[key]
	incoming.play()

	if outgoing == null or not outgoing.playing or outgoing == incoming:
		# Nothing to crossfade from — start at full volume like before.
		incoming.volume_db = 0.0
		return

	incoming.volume_db = SILENT_DB
	_bgm_tween = create_tween()
	_bgm_tween.set_parallel(true)
	_bgm_tween.tween_property(outgoing, "volume_db", SILENT_DB, CROSSFADE_TIME)
	_bgm_tween.tween_property(incoming, "volume_db", 0.0, CROSSFADE_TIME)
	_bgm_tween.set_parallel(false)
	_bgm_tween.tween_callback(func() -> void:
		if is_instance_valid(outgoing) and outgoing != incoming:
			outgoing.stop())

## Fade the current track(s) out and stop.
func stop_bgm(fade: float = 0.6) -> void:
	var playing: Array = []
	for p in [_bgm_player, _bgm_player_b]:
		if p != null and p.playing:
			playing.append(p)
	if playing.is_empty():
		return
	_kill_bgm_tween()
	_bgm_key = ""
	_bgm_tween = create_tween()
	_bgm_tween.set_parallel(true)
	for p in playing:
		_bgm_tween.tween_property(p, "volume_db", SILENT_DB, fade)
	_bgm_tween.set_parallel(false)
	_bgm_tween.tween_callback(func() -> void:
		for p in playing:
			if is_instance_valid(p):
				p.stop())

func _kill_bgm_tween() -> void:
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()

## Legacy helper kept for compatibility: hard-start a track on the active player.
func _start_bgm(key: String) -> void:
	if _bgm_player == null or not _bgm.has(key):
		return
	_kill_bgm_tween()
	for p in [_bgm_player, _bgm_player_b]:
		if p != null:
			p.stop()
	_bgm_active = _bgm_player
	_bgm_player.stream = _bgm[key]
	_bgm_player.volume_db = 0.0
	_bgm_player.play()
	_bgm_key = key

# ------------------------------------------------------------------
# Ducking (minigame / dialogue overlays). Does not touch the user's
# Music-bus volume — only the dedicated DUCK_BUS.
# ------------------------------------------------------------------

## Lower the BGM ~12 dB while a minigame is up.
func duck_bgm() -> void:
	_set_duck_target(DUCK_DB)

## Smoothly restore the BGM.
func unduck_bgm() -> void:
	_set_duck_target(0.0)

## amount 0..1 (1 = fully ducked).
func set_duck(amount: float) -> void:
	_set_duck_target(lerpf(0.0, DUCK_DB, clampf(amount, 0.0, 1.0)))

func is_bgm_ducked() -> bool:
	return _duck_current < -0.01

func get_duck_db() -> float:
	return _duck_current

func _set_duck_target(db: float) -> void:
	if _duck_tween and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_method(_apply_duck_db, _duck_current, db, DUCK_FADE).set_trans(Tween.TRANS_SINE)

func _apply_duck_db(db: float) -> void:
	_duck_current = db
	var idx := AudioServer.get_bus_index(DUCK_BUS)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, db)

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
	var bus_name := DUCK_BUS if AudioServer.get_bus_index(DUCK_BUS) != -1 else MUSIC_BUS
	_bgm_player = _make_bgm_player(bus_name)
	_bgm_player_b = _make_bgm_player(bus_name)
	_bgm_active = _bgm_player

func _make_bgm_player(bus_name: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus_name
	p.finished.connect(func() -> void:
		if is_instance_valid(p):
			p.play())
	add_child(p)
	return p

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
