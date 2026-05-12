extends Node2D

@onready var question_label: Label = $Question
@onready var choices_container: HBoxContainer = $HBoxContainer
@onready var rich_text_label: RichTextLabel = $Panel/RichTextLabel

var choice_nodes: Array[TextureButton] = []
var choice_labels: Array[Label] = []
var current_index: int = 0
var is_answered: bool = false

@export var return_scene_path: String = "res://scenes/mainscenes/main2/scene_main_2.tscn"

var questions_data: Array = [
	{
		"question": "第1题：柱类榫卯的作用是固定柱脚与柱身，防位移、抗倾覆，下面哪类是柱形榫卯？",
		"choices": ["res://assets/images/第一关素材/柱类榫卯素材.png", "res://assets/images/第一关素材/枋类榫卯素材.png", "res://assets/images/第一关素材/梁类榫卯素材.png"],
		"choice_labels": ["柱类榫卯", "枋类榫卯", "梁类榫卯"],
		"wrong_hints": ["不对，这是枋类榫卯，横向拉结柱架。", "不对，这是梁类榫卯，梁柱核心连接。"],
		"correct_hint": "正确！柱类榫卯固定柱脚与柱身。",
		"correct_index": 0
	},
	{
		"question": "第2题：位于立柱和横梁交接处、层层叠加的构件是？",
		"choices": ["res://assets/images/第一关素材/斗拱素材.png", "res://assets/images/第一关素材/雀替素材.png", "res://assets/images/第一关素材/牛腿素材.png"],
		"choice_labels": ["斗拱", "雀替", "牛腿"],
		"wrong_hints": ["雀替是辅助支撑构件。", "牛腿是悬挑支撑构件。"],
		"correct_hint": "正确！斗拱层层叠加，是古建精髓。",
		"correct_index": 0
	},
	{
		"question": "第3题：古建修复的核心原则是什么？",
		"choices": ["res://assets/images/第一关素材/修旧如旧.png", "res://assets/images/第一关素材/推倒重建.png", "res://assets/images/第一关素材/现代改造.png"],
		"choice_labels": ["修旧如旧", "推倒重建", "现代改造"],
		"wrong_hints": ["推倒重建会丧失历史信息。", "现代改造破坏原真性。"],
		"correct_hint": "正确！修旧如旧。",
		"correct_index": 0
	}
]

func _ready():
	print("[Level1] start")
	rich_text_label.bbcode_enabled = true
	choice_nodes.clear()
	choice_labels.clear()
	for child in choices_container.get_children():
		if child is TextureButton:
			choice_nodes.append(child)
			child.custom_minimum_size = Vector2(140, 100)
			child.self_modulate = Color(0.2, 0.2, 0.25, 1)
			var idx = choice_nodes.size() - 1
			child.pressed.connect(_on_choice_pressed.bind(idx))
			var label = Label.new()
			label.name = "FBL"
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 18)
			label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			child.add_child(label)
			choice_labels.append(label)
	if questions_data.size() > 0:
		_load_q(0)
	print("[Level1] done, count=", questions_data.size())

func _load_q(index: int):
	if index >= questions_data.size():
		_show_complete()
		return
	current_index = index
	is_answered = false
	var data = questions_data[index]
	question_label.text = data["question"]
	rich_text_label.text = ""
	var labels = data["choice_labels"]
	for i in range(choice_nodes.size()):
		choice_nodes[i].visible = true
		choice_nodes[i].disabled = false
		choice_nodes[i].self_modulate = Color(0.2, 0.2, 0.25, 1)
		if i < choice_labels.size():
			choice_labels[i].text = labels[i] if i < labels.size() else "OPT" + str(i + 1)

func _on_choice_pressed(id: int):
	if is_answered:
		return
	var data = questions_data[current_index]
	if id == data["correct_index"]:
		is_answered = true
		choice_nodes[id].self_modulate = Color(0.2, 0.6, 0.2, 1)
		rich_text_label.text = "[color=#2ecc71]OK [/color]" + data["correct_hint"]
		for btn in choice_nodes:
			btn.disabled = true
		await get_tree().create_timer(1.5).timeout
		_load_q(current_index + 1)
	else:
		rich_text_label.text = "[color=#e74c3c]NG [/color]" + (data["wrong_hints"][id] if id < data["wrong_hints"].size() else "再试试")

func _show_complete():
	question_label.text = "恭喜通关！你已掌握古建榫卯基础知识。"
	rich_text_label.text = "[color=#f1c40f]正在返回院落…[/color]"
	for btn in choice_nodes:
		btn.visible = false
	GameManager.level1_complete = true
	KnowledgeManager.unlock_by_event("level1_complete")
	await get_tree().create_timer(2.0).timeout
	SceneManager.change_scene(return_scene_path, {"pattern": "fade", "speed": 2.0})
