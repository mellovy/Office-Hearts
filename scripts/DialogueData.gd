extends Node
## Story content aggregator. Autoloaded as "Story".
##
## Route content lives one file per route so writers can work in parallel:
##   scripts/story/story_common.gd, story_arthur.gd, story_dante.gd, story_leo.gd
## Flow graph + palette: scripts/story/story_graph.gd
## Format reference: scripts/story/STORY_SCHEMA.md

const GRAPH := preload("res://scripts/story/story_graph.gd")

const _MODULES := [
	preload("res://scripts/story/story_common.gd"),
	preload("res://scripts/story/story_arthur.gd"),
	preload("res://scripts/story/story_dante.gd"),
	preload("res://scripts/story/story_leo.gd"),
]

const FLOW_NODES: Array = GRAPH.FLOW_NODES
const FLOW_EDGES: Array = GRAPH.FLOW_EDGES
const ROUTE_COLORS: Dictionary = GRAPH.ROUTE_COLORS
const ROUTE_NAMES: Dictionary = GRAPH.ROUTE_NAMES
const ENDING_IDS: Array = GRAPH.ENDING_IDS

var _chapters: Dictionary = {}


func _all_chapters() -> Dictionary:
	if _chapters.is_empty():
		for mod in _MODULES:
			_chapters.merge(mod.CHAPTERS)
	return _chapters


func get_chapter(id: String) -> Dictionary:
	return _all_chapters().get(id, {})
