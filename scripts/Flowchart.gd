extends Control
## Visual flowchart of the whole story: common route branching into
## Arthur / Dante / Leo routes, each ending in a good or bittersweet ending.
## Visited nodes are lit up; unvisited ones are greyed out.

const NODE_SIZE := Vector2(150, 64)
const COL_SPACING := 220.0
const ROW_SPACING := 130.0
const ORIGIN := Vector2(70, 70)

var canvas: FlowCanvas
var node_positions: Dictionary = {}


class FlowCanvas:
	extends Control
	var edges: Array = []
	var positions: Dictionary = {}

	func _draw() -> void:
		for edge in edges:
			var a: Vector2 = positions.get(edge[0], Vector2.ZERO)
			var b: Vector2 = positions.get(edge[1], Vector2.ZERO)
			if a == Vector2.ZERO or b == Vector2.ZERO:
				continue
			var lit: bool = GameState.visited.has(edge[0]) and GameState.visited.has(edge[1])
			var col: Color = Color(UIUtil.PINK_DEEP, 0.9) if lit else Color(UIUtil.PLUM_SOFT, 0.25)
			var w := 3.0 if lit else 2.0
			draw_line(a, b, col, w, true)


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	add_child(UIUtil.bg_gradient(UIUtil.CREAM_DEEP, UIUtil.CREAM))

	var top_row := HBoxContainer.new()
	top_row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_row.offset_left = 20
	top_row.offset_top = 16
	top_row.offset_right = -20
	top_row.add_theme_constant_override("separation", 16)
	add_child(top_row)

	var back_btn := UIUtil.button_style(UIUtil.PLUM_SOFT, UIUtil.PLUM_SOFT.lightened(0.1), UIUtil.PLUM_SOFT.darkened(0.1), 12)
	back_btn.text = "← Back"
	back_btn.custom_minimum_size = Vector2(110, 44)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	top_row.add_child(back_btn)

	var title := UIUtil.heading("Story Flowchart", 26, UIUtil.PINK_DEEP)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 76
	scroll.offset_left = 10
	scroll.offset_right = -10
	scroll.offset_bottom = -10
	add_child(scroll)

	canvas = FlowCanvas.new()
	canvas.custom_minimum_size = Vector2(1180, 620)
	scroll.add_child(canvas)

	# Compute positions first (canvas needs them for edges).
	for node in Story.FLOW_NODES:
		var pos: Vector2 = ORIGIN + Vector2(node["col"] * COL_SPACING, node["row"] * ROW_SPACING)
		node_positions[node["id"]] = pos + NODE_SIZE / 2.0

	canvas.positions = node_positions
	canvas.edges = Story.FLOW_EDGES

	# Route legend.
	var legend := HBoxContainer.new()
	legend.position = Vector2(20, 590)
	legend.add_theme_constant_override("separation", 24)
	for route in ["arthur", "dante", "leo"]:
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 6)
		var dot := ColorRect.new()
		dot.color = UIUtil.route_color(route)
		dot.custom_minimum_size = Vector2(14, 14)
		chip.add_child(dot)
		chip.add_child(UIUtil.body_label(Story.ROUTE_NAMES.get(route, route), 13, UIUtil.PLUM))
		legend.add_child(chip)
	canvas.add_child(legend)

	# Nodes on top of the canvas.
	for node in Story.FLOW_NODES:
		var id: String = node["id"]
		var visited: bool = GameState.visited.has(id)
		var is_ending: bool = id.ends_with("_end_good") or id.ends_with("_end_bad")
		var route: String = node["route"]
		var base_color: Color = UIUtil.route_color(route) if visited else Color(UIUtil.PLUM_SOFT, 0.35)

		var panel := PanelContainer.new()
		var radius := 32 if is_ending else 14
		var border_col := UIUtil.GOLD if (is_ending and GameState.endings_unlocked.has(id)) else Color(0, 0, 0, 0)
		var border_w := 3 if (is_ending and GameState.endings_unlocked.has(id)) else 0
		panel.add_theme_stylebox_override("panel", UIUtil.panel_style(base_color, radius, border_col, border_w))
		panel.position = ORIGIN + Vector2(node["col"] * COL_SPACING, node["row"] * ROW_SPACING)
		panel.custom_minimum_size = NODE_SIZE
		panel.size = NODE_SIZE

		var lbl := Label.new()
		lbl.text = node["label"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", UIUtil.CREAM if visited else Color(UIUtil.CREAM, 0.7))
		var lmargin := MarginContainer.new()
		lmargin.add_theme_constant_override("margin_left", 6)
		lmargin.add_theme_constant_override("margin_right", 6)
		lmargin.add_child(lbl)
		panel.add_child(lmargin)

		canvas.add_child(panel)

	canvas.queue_redraw()
