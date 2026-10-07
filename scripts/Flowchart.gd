extends Control
## Visual flowchart of the whole story: common route branching into
## Arthur / Dante / Leo routes via the "Free Time" hub, each ending in a
## good, true (★), or bittersweet ending.
## Visited nodes are lit up; unvisited ones are greyed out.

const NODE_SIZE := Vector2(108, 56)
const COL_SPACING := 118.0
const ROW_SPACING := 106.0
const ORIGIN_X := 10.0
const TOP_MARGIN := 22.0

var canvas: FlowCanvas
var node_routes: Dictionary = {}
var node_positions: Dictionary = {}
var origin: Vector2 = Vector2.ZERO


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
	Audio.play_bgm("warm")
	_build_ui()
	UIUtil.fade_in(self)


func _build_ui() -> void:
	add_child(UIUtil.cute_bg())

	# Back button, top-left.
	var top_row := HBoxContainer.new()
	top_row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_row.offset_left = 20
	top_row.offset_top = 16
	top_row.offset_right = -20
	add_child(top_row)

	var back_btn := UIUtil.back_button("Back", 128, 48)
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
	title_center.add_child(UIUtil.title_label("STORY FLOWCHART", 28, UIUtil.TEXT_DARK))
	add_child(title_center)

	# ---- Legend: dedicated full-width bar pinned below the graph ----
	var legend_bar := PanelContainer.new()
	legend_bar.anchor_left = 0.0
	legend_bar.anchor_right = 1.0
	legend_bar.anchor_top = 1.0
	legend_bar.anchor_bottom = 1.0
	legend_bar.offset_top = -54
	legend_bar.offset_bottom = 0
	legend_bar.add_theme_stylebox_override("panel", UIUtil.panel_style(Color(UIUtil.WINE, 0.95), 0, Color(0, 0, 0, 0), 0, false))
	add_child(legend_bar)

	var lmargin := UIUtil.margin(20, 8, 20, 8)
	legend_bar.add_child(lmargin)
	var legend := HBoxContainer.new()
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	legend.add_theme_constant_override("separation", 30)
	lmargin.add_child(legend)
	for route in ["common", "arthur", "dante", "leo"]:
		var rname: String = "Common" if route == "common" else Story.ROUTE_NAMES.get(route, route)
		legend.add_child(_legend_chip(UIUtil.route_color(route), rname))
	legend.add_child(_legend_chip(UIUtil.GOLD, "Unlocked ending", UIUtil.TEX_ICON_CHECK))

	# ---- Graph region between the title and the legend bar ----
	var region := Control.new()
	region.anchor_left = 0.0
	region.anchor_right = 1.0
	region.anchor_top = 0.0
	region.anchor_bottom = 1.0
	region.offset_left = 8
	region.offset_right = -8
	region.offset_top = 70
	region.offset_bottom = -58
	add_child(region)

	# Compute the graph bounds so the whole thing can be scaled to fit.
	var min_row := 999.0
	var max_row := -999.0
	var max_col := 0.0
	for node in Story.FLOW_NODES:
		min_row = min(min_row, float(node["row"]))
		max_row = max(max_row, float(node["row"]))
		max_col = max(max_col, float(node["col"]))
	origin = Vector2(ORIGIN_X, TOP_MARGIN - min_row * ROW_SPACING)
	var canvas_size := Vector2(
		ORIGIN_X + max_col * COL_SPACING + NODE_SIZE.x + 8,
		origin.y + max_row * ROW_SPACING + NODE_SIZE.y + 8
	)

	canvas = FlowCanvas.new()
	canvas.size = canvas_size
	region.add_child(canvas)

	# Compute positions first (canvas needs them for edges).
	for node in Story.FLOW_NODES:
		node_routes[node["id"]] = node["route"]
		var pos: Vector2 = origin + Vector2(node["col"] * COL_SPACING, node["row"] * ROW_SPACING)
		node_positions[node["id"]] = pos + NODE_SIZE / 2.0

	canvas.positions = node_positions
	canvas.routes = node_routes
	canvas.edges = Story.FLOW_EDGES

	# Nodes on top of the canvas.
	for node in Story.FLOW_NODES:
		var id: String = node["id"]
		var visited: bool = GameState.visited.has(id)
		var is_ending: bool = id.ends_with("_end_good") or id.ends_with("_end_bad") or id.ends_with("_end_true")
		var is_true: bool = id.ends_with("_end_true")
		var route: String = node["route"]
		var base_color: Color = UIUtil.route_color(route) if visited else Color("#d9d3dc")
		var unlocked: bool = is_ending and GameState.endings_unlocked.has(id)

		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", UIUtil.tex_panel(UIUtil.TEX_SMALL_TEXT, 12, -1, base_color))
		panel.position = origin + Vector2(node["col"] * COL_SPACING, node["row"] * ROW_SPACING)
		panel.custom_minimum_size = NODE_SIZE
		panel.size = NODE_SIZE
		UIUtil.hover_scale(panel, 1.06)

		# High-contrast labels: dark ink on light fills, white only on hot-pink "common".
		var label_col: Color = UIUtil.TEXT_DARK
		if visited and route == "common":
			label_col = UIUtil.TEXT_LIGHT
		var lbl := UIUtil.body_label(node["label"], 16, label_col)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var lmargin2 := UIUtil.margin(6, 3, 6, 3)
		lmargin2.add_child(lbl)
		panel.add_child(lmargin2)

		if unlocked:
			var chk := UIUtil.icon_rect(UIUtil.TEX_ICON_CHECK, 15, UIUtil.GOLD if is_true else UIUtil.SKY)
			lbl.add_child(chk)
			var place_chk := func(): chk.position = Vector2(lbl.size.x - 15.0, -3.0)
			place_chk.call()
			lbl.resized.connect(place_chk)

		canvas.add_child(panel)

	canvas.queue_redraw()

	# Fit the graph to the region (centred, scales up or down, never clipped).
	await get_tree().process_frame
	var avail := region.size
	if canvas_size.x > 0.0 and canvas_size.y > 0.0 and avail.x > 0.0 and avail.y > 0.0:
		var s: float = min(avail.x / canvas_size.x, avail.y / canvas_size.y)
		canvas.scale = Vector2(s, s)
		canvas.position = (avail - canvas_size * s) * 0.5

	UIUtil.focus_first(self)


## One legend entry: a small chip (colour swatch or real icon) + a white label.
func _legend_chip(col: Color, text: String, icon_path: String = "") -> Control:
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 8)
	if icon_path != "":
		var ic := UIUtil.icon_rect(icon_path, 16, col)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chip.add_child(ic)
	else:
		var dot := PanelContainer.new()
		dot.custom_minimum_size = Vector2(16, 16)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.add_theme_stylebox_override("panel", UIUtil.panel_style(col, 5, Color(UIUtil.WINE, 0.25), 1, false))
		chip.add_child(dot)
	var lbl := UIUtil.body_label(text, 18, UIUtil.TEXT_LIGHT)
	lbl.clip_text = false  # clip_text=true collapses min width to 1px
	chip.add_child(lbl)
	return chip
