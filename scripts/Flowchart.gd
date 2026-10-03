extends Control
## Visual flowchart of the whole story: common route branching into
## Arthur / Dante / Leo routes, each ending in a good or bittersweet ending.
## Visited nodes are lit up; unvisited ones are greyed out.

const NODE_SIZE := Vector2(150, 64)
const COL_SPACING := 220.0
const ROW_SPACING := 130.0
const ORIGIN := Vector2(70, 70)

var canvas: FlowCanvas
var node_routes: Dictionary = {}
var node_positions: Dictionary = {}


class FlowCanvas:
	extends Control
	var edges: Array = []
	var positions: Dictionary = {}
	var routes: Dictionary = {}

	func _draw() -> void:
		for edge in edges:
			var a: Vector2 = positions.get(edge[0], Vector2.ZERO)
			var b: Vector2 = positions.get(edge[1], Vector2.ZERO)
			if a == Vector2.ZERO or b == Vector2.ZERO:
				continue
			var lit: bool = GameState.visited.has(edge[0]) and GameState.visited.has(edge[1])
			var route: String = routes.get(edge[1], "common")
			var line_col: Color = UIUtil.route_color(route) if lit else Color(UIUtil.TEXT_MUTED, 0.4)
			var w := 4.0 if lit else 2.0
			draw_line(a, b, line_col, w, false)


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	add_child(UIUtil.cute_bg())

	# Back button, top-left.
	var top_row := HBoxContainer.new()
	top_row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_row.offset_left = 20
	top_row.offset_top = 16
	top_row.offset_right = -20
	add_child(top_row)

	var back_btn := UIUtil.pill_button("Back", 120, 46)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	top_row.add_child(back_btn)

	# Centered pixel title with hard drop-shadow.
	var title_center := CenterContainer.new()
	title_center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_center.offset_left = 20
	title_center.offset_top = 10
	title_center.offset_right = -20
	title_center.offset_bottom = 66
	title_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_center.add_child(UIUtil.title_label("STORY FLOWCHART", 24, UIUtil.TEXT_DARK))
	add_child(title_center)

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
		node_routes[node["id"]] = node["route"]
		var pos: Vector2 = ORIGIN + Vector2(node["col"] * COL_SPACING, node["row"] * ROW_SPACING)
		node_positions[node["id"]] = pos + NODE_SIZE / 2.0

	canvas.positions = node_positions
	canvas.routes = node_routes
	canvas.edges = Story.FLOW_EDGES

	# Route legend.
	var legend := HBoxContainer.new()
	legend.position = Vector2(20, 586)
	legend.add_theme_constant_override("separation", 24)
	for route in ["common", "arthur", "dante", "leo"]:
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 6)
		var dot := ColorRect.new()
		dot.color = UIUtil.route_color(route)
		dot.custom_minimum_size = Vector2(14, 14)
		chip.add_child(dot)
		var route_name: String = "Common" if route == "common" else Story.ROUTE_NAMES.get(route, route)
		var lbl := UIUtil.body_label(route_name, 18, UIUtil.TEXT_DARK)
		lbl.clip_text = false  # clip_text=true collapses min width to 1px
		chip.add_child(lbl)
		legend.add_child(chip)
	var gold_chip := HBoxContainer.new()
	gold_chip.add_theme_constant_override("separation", 6)
	var gold_dot := ColorRect.new()
	gold_dot.color = UIUtil.GOLD
	gold_dot.custom_minimum_size = Vector2(14, 14)
	gold_chip.add_child(gold_dot)
	var gold_lbl := UIUtil.body_label("Unlocked Ending", 18, UIUtil.TEXT_DARK)
	gold_lbl.clip_text = false  # clip_text=true collapses min width to 1px
	gold_chip.add_child(gold_lbl)
	legend.add_child(gold_chip)
	canvas.add_child(legend)

	# Nodes on top of the canvas.
	for node in Story.FLOW_NODES:
		var id: String = node["id"]
		var visited: bool = GameState.visited.has(id)
		var is_ending: bool = id.ends_with("_end_good") or id.ends_with("_end_bad")
		var route: String = node["route"]
		var base_color: Color = UIUtil.route_color(route) if visited else UIUtil.PANEL_CREAM
		var unlocked: bool = is_ending and GameState.endings_unlocked.has(id)
		var border_col: Color = UIUtil.GOLD if unlocked else UIUtil.BLACK
		var border_w := 4 if unlocked else 3

		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", UIUtil.panel_style(base_color, 0, border_col, border_w))
		panel.position = ORIGIN + Vector2(node["col"] * COL_SPACING, node["row"] * ROW_SPACING)
		panel.custom_minimum_size = NODE_SIZE
		panel.size = NODE_SIZE

		var lbl := UIUtil.body_label(node["label"], 18, UIUtil.TEXT_DARK if visited else UIUtil.TEXT_MUTED)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var lmargin := UIUtil.margin(8, 4, 8, 4)
		lmargin.add_child(lbl)
		panel.add_child(lmargin)

		canvas.add_child(panel)

	canvas.queue_redraw()
