extends MinigameBase
## Boardroom Rebuttal — the boardroom confrontation beat.
##
## Sterling fires a sequence of accusations. For each one you must slam down the
## right piece of evidence from your hand before the per-accusation timer runs
## out. Pick wrong, or stall, and you take a strike; too many strikes and the
## board sides with Sterling. Every round reveals the evidence that would have
## worked, so it is deduction, not luck.

const GAME_ID := "boardroom_rebuttal"

const CREAM := Color("#FDE8D0")
const HOT := Color("#E8447E")
const BLUSH := Color("#F4A0B8")
const WINE := Color("#7A2F52")
const LAVENDER := Color("#A99FE0")
const SKY := Color("#A8D8F0")
const INK := Color("#57465F")
const MUTED := Color("#7C6B86")
const GOOD := Color("#4FA36A")
const BAD := Color("#C24A5A")

const EVIDENCE := {
	"budget": {"name": "Budget Ledger", "detail": "Monthly department spend, line by line"},
	"server": {"name": "Server Access Log", "detail": "Timestamps for the shared drive"},
	"gala": {"name": "Gala Seating Chart", "detail": "Who sat where at the charity dinner"},
	"memo": {"name": "Leaked Memo Draft", "detail": "The staff memo that reached the press"},
	"coffee": {"name": "Coffee Order Slips", "detail": "Two regulars, one handwriting"},
	"handwriting": {"name": "Handwriting Sample", "detail": "Sterling's signature, side by side"},
	"commit": {"name": "Commit History", "detail": "Who pushed which file, and when"},
	"email": {"name": "Client Email Thread", "detail": "Every reply in the deal negotiation"},
}

const ACCUSATIONS := [
	{"text": "You have been skimming the department budget for months!", "correct": "budget", "counter": "The ledger shows every expense justified."},
	{"text": "You sabotaged my presentation minutes before the board meeting!", "correct": "server", "counter": "The access log proves I was never near the deck."},
	{"text": "You fabricated an alibi for the night of the gala!", "correct": "gala", "counter": "The seating chart places me across the room all evening."},
	{"text": "You leaked the merger memo straight to the press!", "correct": "memo", "counter": "My draft never left the building."},
	{"text": "You are hiding an office romance on company time!", "correct": "coffee", "counter": "Two coffee slips — and neither name is mine."},
	{"text": "That is my signature on the approval. You forged it!", "correct": "handwriting", "counter": "Compare it to your own hand, Sterling."},
	{"text": "You stole the credit for the entire project!", "correct": "commit", "counter": "The commit history names the real author."},
	{"text": "You promised the client terms we never agreed to!", "correct": "email", "counter": "The email thread speaks for itself."},
]

var _accusation: Label
var _status: Label
var _progress: Label
var _strike_label: Label
var _hand: HFlowContainer
var _tbar: Control

var _order: Array = []
var _round: int = 0
var _total: int = 5
var _score: int = 0
var _strikes: int = 0
var _max_strikes: int = 2
var _hand_size: int = 3

var _time_limit: float = 12.0
var _time_left: float = 12.0
var _awaiting: bool = false
var _ending: bool = false
var _btn_by_id: Dictionary = {}
var _hand_order: Array[String] = []


static func meta() -> Dictionary:
	return {
		"id": GAME_ID,
		"title": "Boardroom Rebuttal",
		"blurb": "Sterling is hurling accusations. Counter each one with the right evidence before your time runs out.",
		"instructions": "Read the accusation, then click the evidence card that rebuts it — or use the arrow keys and Enter / Space (number keys 1-4 also work). You have a short timer per accusation. Wrong picks and stalls cost a strike; too many strikes and you lose. The correct evidence is revealed after each round. Esc forfeits.",
	}


func _build() -> void:
	var d: float = _difficulty()
	_total = int(round(lerpf(3.0, 7.0, d)))
	_max_strikes = int(round(lerpf(3.0, 1.0, d)))
	_hand_size = int(round(lerpf(3.0, 5.0, d)))
	_time_limit = lerpf(14.0, 6.0, d)
	_time_left = _time_limit

	_order = ACCUSATIONS.duplicate()
	_shuffle(_order)
	if _order.size() > _total:
		_order = _order.slice(0, _total)

	var panel := Panel.new()
	panel.name = "Board"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", UIUtil.panel_style(CREAM, 10, WINE, 3, true))
	add_child(panel)

	var m := UIUtil.margin(20, 14, 20, 14)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	m.add_child(vb)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var title := _text(_title_text(), 22, WINE, false, UIUtil.font_bold(true))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_progress = _text("", 16, WINE, false, UIUtil.font_bold(false))
	head.add_child(_progress)
	_strike_label = _text("", 16, HOT, false, UIUtil.font_bold(false))
	_strike_label.custom_minimum_size = Vector2(140, 0)
	_strike_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(_strike_label)
	vb.add_child(head)

	var prompt := _prompt_text()
	if prompt != "":
		vb.add_child(_text(prompt, 13, MUTED, false))

	# accusation card
	var acc_panel := Panel.new()
	acc_panel.custom_minimum_size = Vector2(0, 92)
	acc_panel.add_theme_stylebox_override("panel", UIUtil.panel_style(WINE, 8, HOT, 2, true))
	vb.add_child(acc_panel)
	var acc_margin := UIUtil.margin(16, 10, 16, 10)
	acc_panel.add_child(acc_margin)
	_accusation = _text("", 18, CREAM, true, UIUtil.font_bold(true))
	_accusation.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	acc_margin.add_child(_accusation)

	# timer bar
	_tbar = Control.new()
	_tbar.custom_minimum_size = Vector2(0, 12)
	_tbar.draw.connect(_draw_tbar.bind(_tbar))
	vb.add_child(_tbar)

	vb.add_child(_text("Your evidence:", 15, MUTED, false))

	_hand = HFlowContainer.new()
	_hand.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hand.add_theme_constant_override("h_separation", 10)
	_hand.add_theme_constant_override("v_separation", 10)
	_hand.alignment = FlowContainer.ALIGNMENT_CENTER
	vb.add_child(_hand)

	_status = _text("Sterling is waiting.", 16, INK, true)
	vb.add_child(_status)

	vb.add_child(_text("Arrow keys / number keys select · Enter or Space confirms · click works too · Esc forfeits", 12, MUTED, false))

	_update_hud()
	_start_round()
	set_process(true)


# =====================================================================
# rounds
# =====================================================================

func _start_round() -> void:
	if _ending:
		return
	for ch in _hand.get_children():
		ch.queue_free()
	_btn_by_id.clear()
	_hand_order.clear()

	if _round >= _order.size():
		_win()
		return

	var acc: Dictionary = _order[_round]
	_accusation.text = "Sterling: \u201C%s\u201D" % str(acc["text"])
	_awaiting = true
	_time_left = _time_limit
	_status.text = "Choose your rebuttal."

	var correct := str(acc["correct"])
	var hand := _make_hand(correct)
	var first: Button = null
	for i in range(hand.size()):
		var id := str(hand[i])
		var info: Dictionary = EVIDENCE[id]
		var b := UIUtil.pill_button("%s\n%s" % [str(info["name"]), str(info["detail"])], 208, 86)
		b.clip_text = false
		b.add_theme_font_size_override("font_size", 14)
		b.pressed.connect(_pick.bind(id))
		_hand.add_child(b)
		_btn_by_id[id] = b
		_hand_order.append(id)
		if first == null:
			first = b
	if first != null:
		first.grab_focus.call_deferred()

	_update_hud()
	_update_tbar()


func _make_hand(correct: String) -> Array:
	var decoys: Array = []
	for id in EVIDENCE.keys():
		if str(id) != correct:
			decoys.append(id)
	_shuffle(decoys)
	var hand: Array = [correct]
	for i in range(mini(_hand_size - 1, decoys.size())):
		hand.append(decoys[i])
	_shuffle(hand)
	return hand


func _pick(id: String) -> void:
	if not _awaiting or _ending:
		return
	_awaiting = false
	var acc: Dictionary = _order[_round]
	var correct := str(acc["correct"])
	_set_locked(true)
	if id == correct:
		_score += 1
		_highlight(correct, GOOD)
		_status.text = "Objection sustained — %s" % str(acc["counter"])
		Audio.play_sfx("chime")
		_update_hud()
		_advance_later()
	else:
		_strikes += 1
		_highlight(id, BAD)
		_highlight(correct, GOOD)
		_status.text = "Overruled — the right evidence was %s." % _ev_name(correct)
		Audio.play_sfx("whoosh")
		_update_hud()
		_after_miss()


func _timeout() -> void:
	if not _awaiting or _ending:
		return
	_awaiting = false
	var acc: Dictionary = _order[_round]
	var correct := str(acc["correct"])
	_strikes += 1
	_set_locked(true)
	_highlight(correct, GOOD)
	_status.text = "Too slow — the right evidence was %s." % _ev_name(correct)
	Audio.play_sfx("whoosh")
	_update_hud()
	_after_miss()


func _after_miss() -> void:
	if _strikes > _max_strikes:
		_status.text = "Too many strikes — the board sides with Sterling."
		var tmr := get_tree().create_timer(1.05)
		tmr.timeout.connect(func(): _finish(false, {"score": _score, "strikes": _strikes}))
		_ending = true
		return
	_advance_later()


func _advance_later() -> void:
	var tmr := get_tree().create_timer(1.05)
	tmr.timeout.connect(_advance)


func _advance() -> void:
	if _ending:
		return
	_round += 1
	_start_round()


func _win() -> void:
	_status.text = "Case dismissed. The board is yours."
	Audio.play_sfx("ending")
	_ending = true
	var tmr := get_tree().create_timer(1.0)
	tmr.timeout.connect(func(): _finish(true, {"score": _score}))


# =====================================================================
# helpers
# =====================================================================

func _set_locked(locked: bool) -> void:
	for b in _btn_by_id.values():
		var btn := b as Button
		if btn != null:
			btn.disabled = locked
			btn.focus_mode = Control.FOCUS_NONE if locked else Control.FOCUS_ALL


func _highlight(id: String, col: Color) -> void:
	if not _btn_by_id.has(id):
		return
	var b := _btn_by_id[id] as Button
	if b == null:
		return
	b.modulate = col
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color.WHITE)


func _ev_name(id: String) -> String:
	if not EVIDENCE.has(id):
		return id
	var info: Dictionary = EVIDENCE[id]
	return str(info["name"])


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func _update_hud() -> void:
	_progress.text = "Accusation %d/%d" % [mini(_round + 1, _order.size()), _order.size()]
	var pips := ""
	for i in range(_max_strikes + 1):
		pips += "[x]" if i < _strikes else "[ ]"
	_strike_label.text = "Strikes %s" % pips


func _update_tbar() -> void:
	if _tbar != null:
		_tbar.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if _ending or not _awaiting:
		return
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			var idx := -1
			match k.keycode:
				KEY_1: idx = 0
				KEY_2: idx = 1
				KEY_3: idx = 2
				KEY_4: idx = 3
				KEY_5: idx = 4
				_: idx = -1
			if idx >= 0 and idx < _hand_order.size():
				_pick(_hand_order[idx])
				get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _ending or not _awaiting:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_time_left = 0.0
		_update_tbar()
		_timeout()
		return
	_update_tbar()


func _draw_tbar(c: Control) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(WINE, 0.18), true)
	var ratio := clampf(_time_left / maxf(_time_limit, 0.001), 0.0, 1.0)
	var col := HOT.lerp(SKY, ratio)
	c.draw_rect(Rect2(Vector2.ZERO, Vector2(c.size.x * ratio, c.size.y)), col, true)
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(WINE, 0.5), false, 1.0)


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
	return t if t != "" else "Boardroom Rebuttal"


func _prompt_text() -> String:
	var p := str(cfg.get("prompt", ""))
	return p if p != "" else "Counter every accusation with the right evidence."
