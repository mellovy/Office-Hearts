extends MinigameBase
## After Hours Pursuit — the executive-hallway chase beat.
##
## A night guard patrols the corridors on a finite state machine. He sweeps a
## vision cone as he walks his route; step into the cone with clear line of
## sight and he switches to CHASE, then lunges to grab you if you let him get
## close. Every grab costs a strike and throws you back to the entrance. Reach
## the executive exit before the clock runs out and you slip out clean.
##
## The guard is a real FSM (IDLE / PATROL / CHASE / ATTACK / RETURN) with an
## explicit condition on every transition; his visuals are driven by an
## AnimationPlayer built in code (idle / move) and a dust burst fires on the
## lunge, plus a sparkle burst when you reach the exit.

const GAME_ID := "pursuit_chase"

const CREAM := Color("#FDE8D0")
const HOT := Color("#E8447E")
const BLUSH := Color("#F4A0B8")
const WINE := Color("#7A2F52")
const LAVENDER := Color("#A99FE0")
const SKY := Color("#A8D8F0")
const GOLD := Color("#F5E08A")
const INK := Color("#57465F")
const MUTED := Color("#7C6B86")

## Logical playfield; all gameplay runs here and is mapped to the arena rect,
## so behaviour is identical at any window size (and headless).
const FIELD := Vector2(1000.0, 420.0)

enum State { IDLE, PATROL, CHASE, ATTACK, RETURN }
const STATE_NAMES := ["IDLE", "PATROL", "CHASE", "ATTACK", "RETURN"]

const PATROL_RADIUS := 16.0
const PLAYER_RADIUS := 12.0
const ATTACK_WINDUP := 0.38
const ATTACK_RECOVER := 0.5
const GRAB_SLACK := 10.0

const START := Vector2(70.0, 360.0)
const EXIT := Rect2(916.0, 36.0, 72.0, 96.0)

# Desks / partition walls: block movement and line of sight.
const WALLS: Array = [
	Rect2(220.0, 60.0, 160.0, 40.0),
	Rect2(430.0, 160.0, 140.0, 40.0),
	Rect2(150.0, 250.0, 40.0, 110.0),
	Rect2(620.0, 60.0, 40.0, 120.0),
	Rect2(700.0, 300.0, 180.0, 40.0),
	Rect2(360.0, 320.0, 200.0, 40.0),
]

# Patrol route (ping-pong). Waypoint 0 is the guard's start post.
const WAYPOINTS: Array = [
	Vector2(300.0, 120.0),
	Vector2(760.0, 140.0),
	Vector2(820.0, 280.0),
	Vector2(430.0, 240.0),
	Vector2(250.0, 330.0),
]


## The guard's drawn body. Animated by AnimationPlayer (scale / position /
## modulate) as a child of the gameplay holder node.
class EnemySprite extends Node2D:
	var body: Color = Color("#7A2F52")
	var trim: Color = Color("#F4A0B8")
	var eye: Color = Color("#E8447E")
	var radius: float = 16.0
	var facing: float = 0.0
	var alarm: float = 0.0

	func _draw() -> void:
		draw_circle(Vector2(0.0, 5.0), radius * 0.95, Color(0.0, 0.0, 0.0, 0.16))
		draw_circle(Vector2.ZERO, radius, body)
		draw_circle(Vector2.ZERO, radius * 0.60, trim)
		draw_circle(Vector2.ZERO, radius * 0.30, body.darkened(0.35))
		var dir := Vector2(cos(facing), sin(facing))
		draw_line(Vector2.ZERO, dir * radius * 0.95, eye, 2.5, true)
		if alarm > 0.0:
			draw_arc(Vector2.ZERO, radius + 5.0, 0.0, TAU, 22, Color(eye, alarm), 2.0, true)


# ------------------------------------------------------------------ state
var _state: int = State.IDLE
var _state_time: float = 0.0
var _idle_dur: float = 0.55

var _player: Vector2 = START
var _enemy: Vector2 = WAYPOINTS[0]
var _facing: float = 0.0
var _wp_idx: int = 0
var _wp_dir: int = 1
var _return_point: Vector2 = WAYPOINTS[0]
var _last_seen: Vector2 = Vector2.ZERO
var _lost_timer: float = 0.0

# tuning (set from difficulty)
var _sight_range: float = 240.0
var _half_angle: float = deg_to_rad(48.0)
var _patrol_speed: float = 100.0
var _chase_speed: float = 180.0
var _player_speed: float = 215.0
var _attack_range: float = 46.0
var _lost_time: float = 1.4

var _strikes: int = 0
var _max_strikes: int = 3
var _time_left: float = 60.0
var _over: bool = false
var _win: bool = false
var _flash: float = 0.0
var _attack_t: float = 0.0
var _lunged: bool = false

# nodes
var _arena: Control
var _state_label: Label
var _time_label: Label
var _strike_label: Label
var _status: Label
var _enemy_holder: Node2D
var _enemy_visual: EnemySprite
var _anim: AnimationPlayer
var _dust: CPUParticles2D
var _sparkle: CPUParticles2D

# input
var _keys: Dictionary = {}
var _mouse_target: Vector2 = Vector2.ZERO
var _mouse_active: bool = false


static func meta() -> Dictionary:
	return {
		"id": GAME_ID,
		"title": "After Hours Pursuit",
		"blurb": "Slip past the night guard's patrol and reach the executive exit.",
		"instructions": "You are the heart token on the left; reach the EXIT in the top-right. Move with Arrow keys / WASD, or hold the mouse to steer toward the cursor. The guard shines a vision cone — if you are inside it with a clear line of sight he switches to CHASE and will grab you in close. Each grab costs a strike and sends you back to the entrance. The guard loses track after a moment out of view, then returns to his patrol route. Reach the exit before the timer ends. Esc forfeits.",
	}


func _build() -> void:
	var d: float = _difficulty()
	_sight_range = lerpf(230.0, 330.0, d)
	_half_angle = deg_to_rad(lerpf(40.0, 62.0, d))
	_patrol_speed = lerpf(90.0, 135.0, d)
	_chase_speed = lerpf(155.0, 230.0, d)
	_lost_time = lerpf(1.7, 1.0, d)
	_max_strikes = 2 + int(round(d))
	_time_left = lerpf(72.0, 56.0, d)
	_facing = (WAYPOINTS[1] - WAYPOINTS[0]).angle()

	set_process(true)

	var panel := Panel.new()
	panel.name = "Board"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIUtil.panel_style(CREAM, 10, WINE, 3, true))
	add_child(panel)

	var m := UIUtil.margin(18, 12, 18, 12)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	m.add_child(vb)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var title := _text(_title_text(), 22, WINE, false, UIUtil.font_bold(true))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_state_label = _text("STATE  IDLE", 16, LAVENDER, false, UIUtil.font_bold(false))
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_state_label.custom_minimum_size = Vector2(190.0, 0.0)
	head.add_child(_state_label)
	_time_label = _text("", 16, WINE, false, UIUtil.font_bold(false))
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_time_label.custom_minimum_size = Vector2(120.0, 0.0)
	head.add_child(_time_label)
	vb.add_child(head)

	vb.add_child(_text(_prompt_text(), 15, INK, true))

	_arena = Control.new()
	_arena.name = "Arena"
	_arena.mouse_filter = Control.MOUSE_FILTER_STOP
	_arena.custom_minimum_size = Vector2(0.0, 250.0)
	_arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_arena.draw.connect(_draw_arena.bind(_arena))
	_arena.gui_input.connect(_arena_input)
	vb.add_child(_arena)

	_enemy_holder = Node2D.new()
	_enemy_holder.name = "EnemyHolder"
	_arena.add_child(_enemy_holder)

	_enemy_visual = EnemySprite.new()
	_enemy_visual.name = "Enemy"
	_enemy_holder.add_child(_enemy_visual)

	_make_anims()
	_make_particles()

	var frow := HBoxContainer.new()
	frow.add_theme_constant_override("separation", 10)
	_strike_label = _text("", 16, HOT, false, UIUtil.font_bold(false))
	_strike_label.custom_minimum_size = Vector2(220.0, 0.0)
	frow.add_child(_strike_label)
	_status = _text("Reach the EXIT. Stay out of the cone.", 16, INK, false)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frow.add_child(_status)
	vb.add_child(frow)

	vb.add_child(_text("Arrows / WASD move · hold mouse to steer · Esc forfeits", 12, MUTED, false))

	_update_hud()
	_update_enemy_visual()


# =====================================================================
# animation (built entirely in code)
# =====================================================================

func _make_anims() -> void:
	_anim = AnimationPlayer.new()
	_anim.name = "EnemyAnim"
	_enemy_visual.add_child(_anim)
	_anim.root_node = NodePath("..")   # animate the EnemySprite (our parent)
	var lib := AnimationLibrary.new()
	lib.add_animation("idle", _make_idle())
	lib.add_animation("move", _make_move())
	_anim.add_animation_library("", lib)
	_anim.play("idle")


func _key_value(anim: Animation, prop: String, times: Array, values: Array) -> void:
	var t := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t, NodePath(".:" + prop))
	anim.track_set_interpolation_type(t, Animation.INTERPOLATION_LINEAR)
	for i in range(times.size()):
		anim.track_insert_key(t, float(times[i]), values[i])


func _make_idle() -> Animation:
	var a := Animation.new()
	a.length = 1.3
	a.loop_mode = Animation.LOOP_LINEAR
	_key_value(a, "scale", [0.0, 0.65, 1.3], [Vector2.ONE, Vector2(1.06, 0.95), Vector2.ONE])
	_key_value(a, "position", [0.0, 0.65, 1.3], [Vector2.ZERO, Vector2(0.0, -3.0), Vector2.ZERO])
	_key_value(a, "modulate", [0.0, 0.65, 1.3], [Color(0.93, 0.87, 0.94, 1.0), Color.WHITE, Color(0.93, 0.87, 0.94, 1.0)])
	return a


func _make_move() -> Animation:
	var a := Animation.new()
	a.length = 0.42
	a.loop_mode = Animation.LOOP_LINEAR
	_key_value(a, "scale", [0.0, 0.21, 0.42], [Vector2(1.10, 0.90), Vector2(0.92, 1.09), Vector2(1.10, 0.90)])
	_key_value(a, "position", [0.0, 0.21, 0.42], [Vector2(0.0, 2.0), Vector2(0.0, -4.0), Vector2(0.0, 2.0)])
	_key_value(a, "modulate", [0.0, 0.21, 0.42], [Color(1.0, 0.80, 0.88, 1.0), Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 0.80, 0.88, 1.0)])
	return a


func _apply_anim() -> void:
	if _anim == null:
		return
	# idle while patrolling/waiting, move while chasing / lunging / returning.
	var want := "move" if (_state == State.CHASE or _state == State.ATTACK or _state == State.RETURN) else "idle"
	if _anim.current_animation != want:
		_anim.play(want)


# =====================================================================
# particles (built entirely in code)
# =====================================================================

func _make_particles() -> void:
	_dust = CPUParticles2D.new()
	_dust.name = "DustBurst"
	_dust.emitting = false
	_dust.one_shot = true
	_dust.explosiveness = 1.0
	_dust.amount = 20
	_dust.lifetime = 0.55
	_dust.direction = Vector2(-1.0, 0.0)
	_dust.spread = 55.0
	_dust.initial_velocity_min = 60.0
	_dust.initial_velocity_max = 150.0
	_dust.gravity = Vector2(0.0, 220.0)
	_dust.scale_amount_min = 2.5
	_dust.scale_amount_max = 5.5
	_dust.color = BLUSH
	_dust.z_index = 5
	_enemy_holder.add_child(_dust)

	_sparkle = CPUParticles2D.new()
	_sparkle.name = "SparkleBurst"
	_sparkle.emitting = false
	_sparkle.one_shot = true
	_sparkle.explosiveness = 1.0
	_sparkle.amount = 28
	_sparkle.lifetime = 0.9
	_sparkle.direction = Vector2(0.0, -1.0)
	_sparkle.spread = 180.0
	_sparkle.initial_velocity_min = 40.0
	_sparkle.initial_velocity_max = 140.0
	_sparkle.gravity = Vector2(0.0, -30.0)
	_sparkle.scale_amount_min = 3.0
	_sparkle.scale_amount_max = 7.0
	_sparkle.color = GOLD
	_sparkle.z_index = 6
	_arena.add_child(_sparkle)


# =====================================================================
# FSM
# =====================================================================

func _tick(delta: float) -> void:
	_state_time += delta
	var to_player: Vector2 = _player - _enemy
	var dist: float = to_player.length()
	var sees: bool = _can_see_player()

	match _state:
		State.IDLE:
			# Condition: dwell timer elapsed -> resume the route.
			_facing = wrapf(_facing + delta * 1.5, -PI, PI)
			if _state_time >= _idle_dur:
				_set_state(State.PATROL)

		State.PATROL:
			# Condition: player genuinely in view -> give chase.
			if sees:
				_last_seen = _player
				_set_state(State.CHASE)
			elif _at_waypoint():
				# Condition: reached the current waypoint -> pause and scan.
				_advance_waypoint()
				_set_state(State.IDLE)
			else:
				_move_towards(WAYPOINTS[_wp_idx], _patrol_speed * delta)
				_face_towards(WAYPOINTS[_wp_idx], delta)

		State.CHASE:
			# Condition: within grab range -> attack.
			if dist <= _attack_range:
				_last_seen = _player
				_set_state(State.ATTACK)
			elif sees:
				# Condition: still visible -> keep tracking.
				_last_seen = _player
				_lost_timer = 0.0
				_move_towards(_player, _chase_speed * delta)
				_face_towards(_last_seen, delta)
			else:
				# Condition: out of view, timer running.
				_lost_timer += delta
				_face_towards(_last_seen, delta)
				if _lost_timer >= _lost_time:
					_return_point = WAYPOINTS[_wp_idx]
					_set_state(State.RETURN)
				else:
					_move_towards(_last_seen, _chase_speed * delta)

		State.ATTACK:
			_face_towards(_player, delta * 2.0)
			_attack_t += delta
			if not _lunged and _attack_t >= ATTACK_WINDUP:
				_lunged = true
				_dust.restart()
				Audio.play_sfx("whoosh")
				# Condition: player still inside grab range at the lunge -> caught.
				if _player.distance_to(_enemy) <= _attack_range + GRAB_SLACK:
					_caught()
					return
			if _attack_t >= ATTACK_WINDUP + ATTACK_RECOVER:
				_lunged = false
				_attack_t = 0.0
				if sees:
					_set_state(State.CHASE)
				else:
					_return_point = WAYPOINTS[_wp_idx]
					_set_state(State.RETURN)

		State.RETURN:
			# Condition: player reappears -> chase again.
			if sees:
				_last_seen = _player
				_set_state(State.CHASE)
			elif _enemy.distance_to(_return_point) <= 14.0:
				# Condition: back at the route -> resume patrol.
				_set_state(State.IDLE)
			else:
				_move_towards(_return_point, _patrol_speed * delta)
				_face_towards(_return_point, delta)


func _set_state(s: int) -> void:
	if _state == s:
		return
	_state = s
	_state_time = 0.0
	if s == State.CHASE or s == State.ATTACK:
		_lost_timer = 0.0
	if s == State.ATTACK:
		_attack_t = 0.0
		_lunged = false
	_apply_anim()
	if s == State.CHASE:
		Audio.play_sfx("blip")
	_redraw()


func _advance_waypoint() -> void:
	_wp_idx += _wp_dir
	if _wp_idx >= WAYPOINTS.size():
		_wp_idx = WAYPOINTS.size() - 2
		_wp_dir = -1
	elif _wp_idx < 0:
		_wp_idx = 1
		_wp_dir = 1


func _at_waypoint() -> bool:
	var wp: Vector2 = WAYPOINTS[_wp_idx]
	return _enemy.distance_to(wp) <= 12.0


# =====================================================================
# detection
# =====================================================================

func _can_see_player() -> bool:
	var to_p: Vector2 = _player - _enemy
	var d: float = to_p.length()
	if d > _sight_range:
		return false
	if d < 0.001:
		return true
	var dir: Vector2 = to_p / d
	var face := Vector2(cos(_facing), sin(_facing))
	if face.dot(dir) < cos(_half_angle):
		return false
	return _has_line_of_sight(_enemy, _player)


func _has_line_of_sight(a: Vector2, b: Vector2) -> bool:
	var seg: Vector2 = b - a
	var d: float = seg.length()
	if d < 0.001:
		return true
	var steps: int = int(d / 12.0) + 1
	for i in range(1, steps):
		var p: Vector2 = a + seg * (float(i) / float(steps))
		for w in WALLS:
			var wr: Rect2 = w
			if wr.has_point(p):
				return false
	return true


# =====================================================================
# movement + collision
# =====================================================================

func _move_towards(target: Vector2, step: float) -> void:
	var to: Vector2 = target - _enemy
	var d: float = to.length()
	if d <= 0.001:
		return
	_enemy = _slide(_enemy, (to / d) * minf(step, d), PATROL_RADIUS)


func _face_towards(p: Vector2, delta: float) -> void:
	var to: Vector2 = p - _enemy
	if to.length() < 0.001:
		return
	_facing = lerp_angle(_facing, to.angle(), clampf(delta * 10.0, 0.0, 1.0))


func _slide(pos: Vector2, delta_vec: Vector2, radius: float) -> Vector2:
	var p: Vector2 = pos + delta_vec
	p.x = clampf(p.x, radius, FIELD.x - radius)
	p.y = clampf(p.y, radius, FIELD.y - radius)
	for w in WALLS:
		var wr: Rect2 = w
		if wr.grow(radius).has_point(p):
			p = _push_out(p, wr, radius)
	return p


func _push_out(p: Vector2, r: Rect2, radius: float) -> Vector2:
	var left: float = absf(p.x - (r.position.x - radius))
	var right: float = absf((r.position.x + r.size.x + radius) - p.x)
	var top: float = absf(p.y - (r.position.y - radius))
	var bottom: float = absf((r.position.y + r.size.y + radius) - p.y)
	var best: float = minf(minf(left, right), minf(top, bottom))
	if best == left:
		p.x = r.position.x - radius
	elif best == right:
		p.x = r.position.x + r.size.x + radius
	elif best == top:
		p.y = r.position.y - radius
	else:
		p.y = r.position.y + r.size.y + radius
	return p


func _update_player(delta: float) -> void:
	var dir := Vector2.ZERO
	if bool(_keys.get(KEY_LEFT, false)) or bool(_keys.get(KEY_A, false)):
		dir.x -= 1.0
	if bool(_keys.get(KEY_RIGHT, false)) or bool(_keys.get(KEY_D, false)):
		dir.x += 1.0
	if bool(_keys.get(KEY_UP, false)) or bool(_keys.get(KEY_W, false)):
		dir.y -= 1.0
	if bool(_keys.get(KEY_DOWN, false)) or bool(_keys.get(KEY_S, false)):
		dir.y += 1.0
	if _mouse_active:
		var to: Vector2 = _mouse_target - _player
		if to.length() > 4.0:
			dir += to.normalized()
	if dir.length() > 0.001:
		_player = _slide(_player, dir.normalized() * _player_speed * delta, PLAYER_RADIUS)

	if EXIT.has_point(_player):
		_sparkle.position = _map(_player, _arena.size)
		_sparkle.restart()
		_sparkle.emitting = true
		_status.text = "Exit reached — you slip out before he turns."
		_finish_run(true, {"strikes": _strikes, "time_left": _time_left})


func _caught() -> void:
	_strikes += 1
	_flash = 1.0
	_mouse_active = false
	Audio.play_sfx("whoosh")
	if _strikes >= _max_strikes:
		_status.text = "Grabbed again — security walks you out."
		_finish_run(false, {"strikes": _strikes})
		return
	_player = START
	_status.text = "Caught! Thrown back to the entrance."
	_return_point = WAYPOINTS[_wp_idx]
	_set_state(State.RETURN)


# =====================================================================
# run control
# =====================================================================

func _process(delta: float) -> void:
	if _over:
		_decay_flash(delta)
		_redraw()
		return

	_time_left -= delta
	_update_player(delta)
	if _over:
		return
	if _time_left <= 0.0:
		_status.text = "Dawn — the doors lock and the moment is gone."
		_finish_run(false, {"reason": "timeout", "strikes": _strikes})
		return

	_tick(delta)
	if _over:
		return
	_update_enemy_visual()
	_update_hud()
	_decay_flash(delta)
	_redraw()


func _decay_flash(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta / 0.5)


func _finish_run(success: bool, result: Dictionary) -> void:
	if _over:
		return
	_over = true
	_win = success
	Audio.play_sfx("chime" if success else "whoosh")
	_update_hud()
	_redraw()
	if is_inside_tree():
		await get_tree().create_timer(0.9).timeout
	_finish(success, result)


func _update_enemy_visual() -> void:
	if _enemy_holder == null or _arena == null or _enemy_visual == null:
		return
	_enemy_holder.position = _map(_enemy, _arena.size)
	_enemy_visual.facing = _facing
	_enemy_visual.alarm = 1.0 if (_state == State.CHASE or _state == State.ATTACK) else 0.0
	_enemy_visual.queue_redraw()


func _update_hud() -> void:
	if _time_label != null:
		_time_label.text = "TIME %0.1f" % maxf(0.0, _time_left)
	if _strike_label != null:
		var pips := ""
		for i in range(_max_strikes):
			pips += "[x]" if i < _strikes else "[ ]"
		_strike_label.text = "CAUGHT %s" % pips
	if _state_label != null:
		_state_label.text = "STATE  %s" % STATE_NAMES[_state]
		var col := HOT if (_state == State.CHASE or _state == State.ATTACK) else LAVENDER
		_state_label.add_theme_color_override("font_color", col)


func _redraw() -> void:
	if _arena != null:
		_arena.queue_redraw()


# =====================================================================
# input
# =====================================================================

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		super._unhandled_input(event)
		return
	if _over:
		return
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.echo:
			return
		_keys[k.keycode] = k.pressed
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_mouse_active = false


func _arena_input(event: InputEvent) -> void:
	if _over:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_mouse_active = mb.pressed
			if mb.pressed:
				_mouse_target = _screen_to_field(mb.position)
			_arena.accept_event()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _mouse_active:
			_mouse_target = _screen_to_field(mm.position)


# =====================================================================
# geometry + drawing
# =====================================================================

func _field_scale(csz: Vector2) -> float:
	return minf(csz.x / FIELD.x, csz.y / FIELD.y)


func _field_origin(csz: Vector2) -> Vector2:
	var s: float = _field_scale(csz)
	return Vector2((csz.x - FIELD.x * s) * 0.5, (csz.y - FIELD.y * s) * 0.5)


func _map(p: Vector2, csz: Vector2) -> Vector2:
	return _field_origin(csz) + p * _field_scale(csz)


func _screen_to_field(pt: Vector2) -> Vector2:
	var csz: Vector2 = _arena.size
	var s: float = _field_scale(csz)
	if s <= 0.0:
		return pt
	return (pt - _field_origin(csz)) / s


func _draw_arena(c: Control) -> void:
	var csz: Vector2 = c.size
	if csz.x < 10.0 or csz.y < 10.0:
		return
	var s: float = _field_scale(csz)
	var origin: Vector2 = _field_origin(csz)

	# floor
	var field_rect := Rect2(origin, FIELD * s)
	c.draw_rect(field_rect, Color("#F7E7D4"), true)
	c.draw_rect(field_rect, Color(WINE, 0.25), false, 2.0)

	# faint tile grid
	var step: float = 100.0 * s
	var gx: float = origin.x + step
	while gx < field_rect.end.x - 0.5:
		c.draw_line(Vector2(gx, origin.y), Vector2(gx, field_rect.end.y), Color(WINE, 0.06), 1.0)
		gx += step
	var gy: float = origin.y + step
	while gy < field_rect.end.y - 0.5:
		c.draw_line(Vector2(origin.x, gy), Vector2(field_rect.end.x, gy), Color(WINE, 0.06), 1.0)
		gy += step

	# patrol route
	for i in range(WAYPOINTS.size() - 1):
		var a: Vector2 = WAYPOINTS[i]
		var b: Vector2 = WAYPOINTS[i + 1]
		c.draw_line(origin + a * s, origin + b * s, Color(LAVENDER, 0.35), 2.0, true)
	for wp in WAYPOINTS:
		var wpt: Vector2 = wp
		c.draw_circle(origin + wpt * s, 4.0, Color(LAVENDER, 0.7))

	# walls / desks
	for w in WALLS:
		var wr: Rect2 = w
		var r := Rect2(origin + wr.position * s, wr.size * s)
		c.draw_rect(r, Color("#C9A9BC"), true)
		c.draw_rect(r, WINE, false, 2.0)

	# exit
	var er := Rect2(origin + EXIT.position * s, EXIT.size * s)
	c.draw_rect(er, Color(SKY, 0.85), true)
	c.draw_rect(er, WINE, false, 2.0)
	_draw_fit_text(c, "EXIT", er, 14, WINE)

	# start marker
	var sr := Rect2(origin + START * s, Vector2(PLAYER_RADIUS, PLAYER_RADIUS) * 2.0 * s).grow(6.0)
	c.draw_rect(sr, Color(BLUSH, 0.5), false, 2.0)

	# vision cone (colour reads out the FSM state)
	_draw_cone(c, origin, s)

	# player
	var pc: Vector2 = origin + _player * s
	var pr: float = PLAYER_RADIUS * s
	c.draw_circle(pc, pr, WINE)
	c.draw_circle(pc, pr * 0.82, _accent())
	UIUtil._heart(c, pc, pr * 0.6, Color.WHITE)
	if _flash > 0.0:
		c.draw_arc(pc, pr * 2.2, 0.0, TAU, 24, Color(HOT, clampf(_flash, 0.0, 1.0)), 3.0, true)


func _draw_cone(c: Control, origin: Vector2, s: float) -> void:
	var centre: Vector2 = origin + _enemy * s
	var radius: float = _sight_range * s
	var hot := _state == State.CHASE or _state == State.ATTACK
	var col: Color = HOT if hot else LAVENDER
	var pts := PackedVector2Array()
	pts.append(centre)
	var steps: int = 22
	for i in range(steps + 1):
		var a: float = _facing - _half_angle + (2.0 * _half_angle) * float(i) / float(steps)
		pts.append(centre + Vector2(cos(a), sin(a)) * radius)
	c.draw_colored_polygon(pts, Color(col, 0.18))
	var out: PackedVector2Array = pts.duplicate()
	out.append(pts[0])
	c.draw_polyline(out, Color(col, 0.5), 1.5, true)


func _draw_fit_text(c: Control, txt: String, rect: Rect2, fsize: int, col: Color) -> void:
	var f: Font = UIUtil.font_bold(false)
	var ts: Vector2 = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	c.draw_string(f, rect.position + Vector2((rect.size.x - ts.x) * 0.5, rect.size.y * 0.5 + ts.y * 0.35), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)


# =====================================================================
# misc
# =====================================================================

func _text(txt: String, size: int, col: Color, wrap: bool = false, font: Font = null) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if font != null:
		l.add_theme_font_override("font", font)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		l.clip_text = true
	return l


func _title_text() -> String:
	var t := str(cfg.get("title", ""))
	return t if t != "" else "After Hours Pursuit"


func _prompt_text() -> String:
	var p := str(cfg.get("prompt", ""))
	return p if p != "" else "Reach the executive exit without crossing the guard's sight."
