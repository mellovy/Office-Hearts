extends RefCounted
## Flowchart graph + route palette. Owned by the UI/art lane.
## Consumed by scripts/DialogueData.gd (autoload "Story").
## Node entries: {id, label, route, col, row}. Edges: [from_id, to_id].

const FLOW_NODES: Array = [
	# ---- common ----
	{"id": "common_ch1", "label": "Ch 1\nEmergency", "route": "common", "col": 0, "row": 1},
	{"id": "common_ch2", "label": "Ch 2\nThe Team", "route": "common", "col": 1, "row": 1},
	{"id": "hub", "label": "Free\nTime", "route": "common", "col": 2, "row": 1},

	# ---- arthur ----
	{"id": "arthur_ch2", "label": "Arthur\nCh 2", "route": "arthur", "col": 3, "row": 0},
	{"id": "arthur_ch3", "label": "Arthur\nCh 3", "route": "arthur", "col": 4, "row": 0},
	{"id": "arthur_ch4", "label": "Arthur\nCh 4", "route": "arthur", "col": 5, "row": 0},
	{"id": "arthur_ch5", "label": "Arthur\nCh 5", "route": "arthur", "col": 6, "row": 0},
	{"id": "arthur_ch6", "label": "Arthur\nCh 6", "route": "arthur", "col": 7, "row": 0},
	{"id": "arthur_end_good", "label": "Executive\nPartnership ♥", "route": "arthur", "col": 8, "row": 0},
	{"id": "arthur_end_true", "label": "★ Heart &\nEmpire", "route": "arthur", "col": 9, "row": 0},
	{"id": "arthur_end_bad", "label": "Silent\nDeparture", "route": "arthur", "col": 10, "row": 0},

	# ---- dante ----
	{"id": "dante_ch2", "label": "Dante\nCh 2", "route": "dante", "col": 3, "row": 1},
	{"id": "dante_ch3", "label": "Dante\nCh 3", "route": "dante", "col": 4, "row": 1},
	{"id": "dante_ch4", "label": "Dante\nCh 4", "route": "dante", "col": 5, "row": 1},
	{"id": "dante_ch5", "label": "Dante\nCh 5", "route": "dante", "col": 6, "row": 1},
	{"id": "dante_ch6", "label": "Dante\nCh 6", "route": "dante", "col": 7, "row": 1},
	{"id": "dante_end_good", "label": "Partners\nin Chaos ♥", "route": "dante", "col": 8, "row": 1},
	{"id": "dante_end_true", "label": "★ Every\nFriday", "route": "dante", "col": 9, "row": 1},
	{"id": "dante_end_bad", "label": "Red Tape\nSeparation", "route": "dante", "col": 10, "row": 1},

	# ---- leo ----
	{"id": "leo_ch2", "label": "Leo\nCh 2", "route": "leo", "col": 3, "row": 2},
	{"id": "leo_ch3", "label": "Leo\nCh 3", "route": "leo", "col": 4, "row": 2},
	{"id": "leo_ch4", "label": "Leo\nCh 4", "route": "leo", "col": 5, "row": 2},
	{"id": "leo_ch5", "label": "Leo\nCh 5", "route": "leo", "col": 6, "row": 2},
	{"id": "leo_ch6", "label": "Leo\nCh 6", "route": "leo", "col": 7, "row": 2},
	{"id": "leo_end_good", "label": "Designed\nTogether ♥", "route": "leo", "col": 8, "row": 2},
	{"id": "leo_end_true", "label": "★ Our Own\nStudio", "route": "leo", "col": 9, "row": 2},
	{"id": "leo_end_bad", "label": "Faded\nSketch", "route": "leo", "col": 10, "row": 2},
]

const FLOW_EDGES: Array = [
	# common
	["common_ch1", "common_ch2"], ["common_ch2", "hub"],
	["hub", "arthur_ch2"], ["hub", "dante_ch2"], ["hub", "leo_ch2"],
	# arthur
	["arthur_ch2", "arthur_ch3"], ["arthur_ch3", "arthur_ch4"],
	["arthur_ch4", "arthur_ch5"], ["arthur_ch5", "arthur_ch6"],
	["arthur_ch6", "arthur_end_good"], ["arthur_ch6", "arthur_end_true"], ["arthur_ch6", "arthur_end_bad"],
	# dante
	["dante_ch2", "dante_ch3"], ["dante_ch3", "dante_ch4"],
	["dante_ch4", "dante_ch5"], ["dante_ch5", "dante_ch6"],
	["dante_ch6", "dante_end_good"], ["dante_ch6", "dante_end_true"], ["dante_ch6", "dante_end_bad"],
	# leo
	["leo_ch2", "leo_ch3"], ["leo_ch3", "leo_ch4"],
	["leo_ch4", "leo_ch5"], ["leo_ch5", "leo_ch6"],
	["leo_ch6", "leo_end_good"], ["leo_ch6", "leo_end_true"], ["leo_ch6", "leo_end_bad"],
]

const ROUTE_COLORS: Dictionary = {
	"common": Color("#c9a5e0"),
	"arthur": Color("#7f9bd1"),
	"dante": Color("#f2b34a"),
	"leo": Color("#6bc4a6"),
	"true": Color("#ffd25a"),
}

const ROUTE_NAMES: Dictionary = {
	"arthur": "Arthur Pendelton",
	"dante": "Dante Vance",
	"leo": "Leo Thorne",
}

## All ending ids, in gallery order. Used by the endings gallery.
const ENDING_IDS: Array = [
	"arthur_end_true", "arthur_end_good", "arthur_end_bad",
	"dante_end_true", "dante_end_good", "dante_end_bad",
	"leo_end_true", "leo_end_good", "leo_end_bad",
]
