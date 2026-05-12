extends Node

var grass_cut: bool = false
var has_ability: bool = false
var has_talked_to_npc: bool = false
var wood_selected: bool = false
var level1_complete: bool = false
var level2_complete: bool = false
var level3_complete: bool = false

const SCENES := {
	"main_1": "res://scenes/mainscenes/main1/scene_main_1.tscn",
	"main_2": "res://scenes/mainscenes/main2/scene_main_2.tscn",
	"main_3": "res://scenes/mainscenes/main3/scene_main_3.tscn",
	"level1": "res://scenes/mainscenes/level1/level_1.tscn",
	"level2_beam": "res://scenes/mainscenes/level2/level_2_beam_installation.tscn",
	"level3_window": "res://scenes/mainscenes/level3/window_flower_level.tscn",
	"end": "res://scenes/mainscenes/GameEnd.tscn"
}
