extends MinigameBase
## Echoes Dante's stolen sticky-note PIN: Mastermind-style 4-digit deduction.
## Player guesses four different digits; each guess reports exact / close matches.

const GAME_ID := "password_deduction"

const CREAM := Color("#FDE8D0")
const BLUSH := Color("#F4A0B8")
const PINK_DEEP := Color("#E8447E")
const WINE := Color("#7A2F52")
const INK := Color("#57465F")
const MUTED := Color("#7C6B86")
const BAD := Color("#D1435F")

var _secret: Array[int] = []
var _entry: Array[int] = []
var _guesses: int = 0
var _max_guesses: int = 8
var _over: bool = false
var _win: bool = false

var _slot_labels: Array[Label] = []
var _history_box: VBoxContainer
var _scroll: ScrollContainer
var _feedback: Label
var _guess_label: Label
var _pad_buttons: Array[Button] = []
var _banner: Control
var _banner_title: Label
var _banner_sub: Label


static func meta() -> Dictionary:
	return {
		"id": GAME_ID,
		"title": "Password Deduction",
		"blurb": "Crack Dante's four-digit PIN from the clues.",
		"instructions": "Guess the secret four-digit code. Type digits with the number keys or tap the keypad (each digit is used once per guess), then press Enter / tap the arrow to submit. After each guess you see how many digits are in the correct place and how many are correct but in the wrong place. Crack it before your guesses run out. Esc gives up.",
	}


func _build() -> void:
	set_process(false)
	_max_guesses = int(roundf(lerpf(10.0, 6.0, _difficulty())))
	_make_secret()
	_build_ui()
	_refresh_slots()
	_update_guess_label()


func _make_secret() -> void:
	_secret.clear()
	var pool: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
	for i in range(pool.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var t: int = pool[i]
		pool[i] = pool[j]
		pool[j] = t
	for i in range(4):
		_secret.append(pool[i])


# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	var margin := UIUtil.margin(20, 12, 20, 12)
	margin.name = "Board"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 4)
	margin.add_child(main)

	var title := Label.new()
	title.text = "PASSWORD DEDUCTION"
	title.add_theme_font_override("font", UIUtil.font_bold(true))
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", WINE)
	main.add_child(title)

	var prompt := Label.new()
	prompt.text = "Four different digits, 0-9. Exact = right digit, right spot. Close = right digit, wrong spot."
	prompt.add_theme_font_override("font", UIUtil.font_semi())
	prompt.add_theme_font_size_override("font_size", 14)
	prompt.add_theme_color_override("font_color", INK)
	main.add_child(prompt)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 16)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(cols)

	# ---- left: entry + keypad
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	left.custom_minimum_size = Vector2(290.0, 0.0)
	cols.add_child(left)

	var slots_row := HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 6)
	left.add_child(slots_row)
	for i in range(4):
		var slot := _make_slot()
		slots_row.add_child(slot["panel"])
		_slot_labels.append(slot["label"])

	var pad := GridContainer.new()
	pad.columns = 4
	pad.add_theme_constant_override("h_separation", 6)
	pad.add_theme_constant_override("v_separation", 6)
	left.add_child(pad)
	var keys: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "OK"]
	for k in keys:
		var b: Button = UIUtil.pill_button(k, 64.0, 42.0)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 20)
		if k == "C":
			b.pressed.connect(_clear_entry)
		elif k == "OK":
			b.pressed.connect(_submit)
		else:
			b.pressed.connect(_push_digit.bind(int(k)))
		_pad_buttons.append(b)
		pad.add_child(b)

	var submit: Button = UIUtil.pill_button("Submit Guess", 270.0, 42.0)
	submit.focus_mode = Control.FOCUS_NONE
	submit.pressed.connect(_submit)
	_pad_buttons.append(submit)
	left.add_child(submit)

	# ---- right: history
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)

	_guess_label = Label.new()
	_guess_label.add_theme_font_override("font", UIUtil.font_semi())
	_guess_label.add_theme_font_size_override("font_size", 16)
	_guess_label.add_theme_color_override("font_color", PINK_DEEP)
	right.add_child(_guess_label)

	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(300.0, 190.0)
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(_scroll)

	_history_box = VBoxContainer.new()
	_history_box.add_theme_constant_override("separation", 4)
	_history_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_history_box)

	# ---- feedback
	_feedback = Label.new()
	_feedback.add_theme_font_override("font", UIUtil.font_semi())
	_feedback.add_theme_font_size_override("font_size", 15)
	_feedback.add_theme_color_override("font_color", INK)
	main.add_child(_feedback)

	var controls := Label.new()
	controls.text = "Number keys · Backspace · Enter — or tap the keypad. Esc gives up."
	controls.add_theme_font_override("font", UIUtil.font_semi())
	controls.add_theme_font_size_override("font_size", 13)
	controls.add_theme_color_override("font_color", MUTED)
	main.add_child(controls)

	_build_banner()
	_set_feedback("Type or tap four digits, then submit.", false)


func _make_slot() -> Dictionary:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(62.0, 56.0)
	p.add_theme_stylebox_override("panel", UIUtil.panel_style(Color("#FFF5EC"), 8, BLUSH, 2, false))
	var l := Label.new()
	l.text = "-"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UIUtil.font_bold())
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", WINE)
	p.add_child(l)
	return {"panel": p, "label": l}


func _build_banner() -> void:
	_banner = Control.new()
	_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	_banner.mouse_filter = Control.MOUSE_FILTER_STOP
	_banner.visible = false
	add_child(_banner)

	var dim := ColorRect.new()
	dim.color = Color(WINE, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_banner.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_banner.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIUtil.panel_style(CREAM, 16, PINK_DEEP, 3, true))
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	_banner_title = Label.new()
	_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_title.add_theme_font_override("font", UIUtil.font_bold(true))
	_banner_title.add_theme_font_size_override("font_size", 32)
	_banner_title.add_theme_color_override("font_color", WINE)
	vb.add_child(_banner_title)

	_banner_sub = Label.new()
	_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_sub.add_theme_font_override("font", UIUtil.font_semi())
	_banner_sub.add_theme_font_size_override("font_size", 18)
	_banner_sub.add_theme_color_override("font_color", INK)
	vb.add_child(_banner_sub)


# ---------------------------------------------------------------- logic

func _push_digit(d: int) -> void:
	if _over or _entry.size() >= 4:
		return
	if _entry.has(d):
		_set_feedback("Each digit can only be used once per guess.", true)
		Audio.play_sfx("blip")
		return
	_entry.append(d)
	Audio.play_sfx("blip")
	_refresh_slots()


func _pop_digit() -> void:
	if _over or _entry.is_empty():
		return
	_entry.pop_back()
	Audio.play_sfx("click")
	_refresh_slots()


func _clear_entry() -> void:
	if _over:
		return
	_entry.clear()
	Audio.play_sfx("click")
	_refresh_slots()


func _submit() -> void:
	if _over:
		return
	if _entry.size() < 4:
		_set_feedback("Enter all four digits first.", true)
		Audio.play_sfx("whoosh")
		return
	_guesses += 1
	var bulls: int = 0
	var cows: int = 0
	for i in range(4):
		if _entry[i] == _secret[i]:
			bulls += 1
		elif _secret.has(_entry[i]):
			cows += 1
	_add_history(_entry.duplicate(), bulls, cows)
	if bulls == 4:
		_set_feedback("Cracked it!", false)
		_end(true, {"guesses": _guesses})
		return
	var left: int = _max_guesses - _guesses
	if left <= 0:
		_set_feedback("Out of guesses.", true)
		_end(false, {"guesses": _guesses, "code": _secret.duplicate()})
		return
	Audio.play_sfx("click")
	_set_feedback("Exact %d · close %d · %d guesses left." % [bulls, cows, left], false)
	_entry.clear()
	_refresh_slots()
	_update_guess_label()


func _refresh_slots() -> void:
	for i in range(4):
		_slot_labels[i].text = str(_entry[i]) if i < _entry.size() else "-"


func _update_guess_label() -> void:
	_guess_label.text = "GUESSES  %d / %d" % [_guesses, _max_guesses]


func _set_feedback(text: String, bad: bool) -> void:
	if _feedback == null:
		return
	_feedback.text = text
	_feedback.add_theme_color_override("font_color", BAD if bad else INK)


func _add_history(guess: Array, bulls: int, cows: int) -> void:
	var row := Label.new()
	var gs := ""
	for d in guess:
		gs += str(d)
	row.text = "%d.  %s      exact %d   ·   close %d" % [_guesses, gs, bulls, cows]
	row.add_theme_font_override("font", UIUtil.font_semi())
	row.add_theme_font_size_override("font_size", 17)
	row.add_theme_color_override("font_color", PINK_DEEP if bulls == 4 else INK)
	_history_box.add_child(row)
	_scroll.scroll_vertical = 1_000_000


func _end(success: bool, result: Dictionary) -> void:
	if _over:
		return
	_over = true
	_win = success
	for b in _pad_buttons:
		b.disabled = true
	Audio.play_sfx("chime" if success else "whoosh")
	_banner.visible = true
	if success:
		_banner_title.text = "PIN CRACKED"
		_banner_sub.text = "Solved in %d guess%s." % [_guesses, "" if _guesses == 1 else "es"]
	else:
		_banner_title.text = "LOCKED OUT"
		var code := ""
		for d in _secret:
			code += str(d)
		_banner_sub.text = "The code was %s." % code
	if is_inside_tree():
		await get_tree().create_timer(1.0).timeout
	_finish(success, result)


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		super._unhandled_input(event)
		return
	if _over:
		return
	if event is InputEventKey:
		var k := event as InputEventKey
		if not (k.pressed and not k.echo):
			return
		var handled: bool = true
		if k.keycode >= KEY_0 and k.keycode <= KEY_9:
			_push_digit(k.keycode - KEY_0)
		elif k.keycode >= KEY_KP_0 and k.keycode <= KEY_KP_9:
			_push_digit(k.keycode - KEY_KP_0)
		elif k.keycode == KEY_BACKSPACE:
			_pop_digit()
		elif k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER or k.keycode == KEY_SPACE:
			_submit()
		elif k.keycode == KEY_C:
			_clear_entry()
		else:
			handled = false
		if handled:
			get_viewport().set_input_as_handled()
