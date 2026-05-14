extends Node2D

@onready var question_label: Label = $Question
@onready var choices_container: HBoxContainer = $HBoxContainer
@onready var dialog_overlay: Control = $DialogCanvas/DialogOverlay
@onready var dialog_npc_name: Label = $DialogCanvas/DialogOverlay/DialogBox/NPCName
@onready var dialog_text: RichTextLabel = $DialogCanvas/DialogOverlay/DialogBox/DialogText
@onready var dialog_continue_hint: Label = $DialogCanvas/DialogOverlay/DialogBox/ContinueHint

var choice_nodes: Array[TextureButton] = []
var choice_labels: Array[Label] = []
var current_index: int = 0
var is_answered: bool = false
var is_dialog_showing: bool = false

@export var return_scene_path: String = "res://scenes/mainscenes/main2/scene_main_2.tscn"

var questions_data: Array = [
	{
		"question": "第1题：柱类榫卯的作用是固定柱脚与柱身，防位移、抗倾覆，下面哪类是柱形榫卯？",
		"choices": ["res://assets/images/第一关素材/柱类榫卯素材.png", "res://assets/images/第一关素材/枋类榫卯素材.png", "res://assets/images/第一关素材/梁类榫卯素材.png"],
		"choice_labels": ["柱类榫卯", "枋类榫卯", "梁类榫卯"],
		"wrong_hints": [
			{"npc_text": "嗯…这其实是枋类榫卯。", "knowledge": "枋类榫卯主要用于横向拉结柱架，起到稳定柱网结构的作用，常见于额枋、穿插枋等位置。它和柱类榫卯用途不同，别搞混了。"},
			{"npc_text": "再仔细看看，这是梁类榫卯。", "knowledge": "梁类榫卯是梁柱核心连接的构件，位于梁与柱的交汇处，承载屋面重量并传递到立柱。比如月梁、直梁都用到这类榫卯。"}
		],
		"correct_hint": "没错！柱类榫卯就是固定柱脚与柱身的，防位移、抗倾覆，是古建木构的基础。",
		"correct_index": 0
	},
	{
		"question": "第2题：位于立柱和横梁交接处、层层叠加的构件是？",
		"choices": ["res://assets/images/第一关素材/雀替素材.png", "res://assets/images/第一关素材/斗拱素材.png", "res://assets/images/第一关素材/牛腿素材.png"],
		"choice_labels": ["雀替", "斗拱", "牛腿"],
		"wrong_hints": [
			{"npc_text": "雀替是放在梁柱交角处的，不是层层叠加的构件。", "knowledge": "雀替位于梁与柱的交角处，起到辅助支撑和装饰的作用。它通常是一块三角形的木雕构件，虽然也是榫卯结构的一部分，但不是层层叠加的。"},
			{"npc_text": "牛腿是从柱身伸出的悬臂构件，也不是层层叠加的。", "knowledge": "牛腿是从柱身向外伸出的悬挑支撑构件，常用于挑檐、阳台等悬挑结构的支撑。它形态像一个牛腿，但它不是由多层叠加而成的。"}
		],
		"correct_hint": "对了！斗拱由斗形木块和弓形肘木相互穿插、层层叠加而成，位于立柱和横梁交接处，是古建的精髓所在。",
		"correct_index": 1
	},
	{
		"question": "第3题：古建修复的核心原则是什么？",
		"choices": ["res://assets/images/第一关素材/推倒重建.png", "res://assets/images/第一关素材/现代改造.png", "res://assets/images/第一关素材/修旧如旧.png"],
		"choice_labels": ["推倒重建", "现代改造", "修旧如旧"],
		"wrong_hints": [
			{"npc_text": "推倒重建会让历史信息彻底消失，这不是修复之道。", "knowledge": "古建筑承载着数百年的历史信息，推倒重建意味着所有历史痕迹被抹去。古建修复的核心理念是尽可能保存原物，而不是毁旧立新。"},
			{"npc_text": "现代改造会破坏古建的原真性，不可取。", "knowledge": "现代材料和工艺虽然方便，但用在古建上会破坏其历史原真性。比如用水泥代替传统灰浆看似坚固，实则对古建造成不可逆的损伤。"}
		],
		"correct_hint": "说得好！'修旧如旧'是古建修复的核心理念——尊重历史原貌，使用传统工艺，让古建重现昔日风采。",
		"correct_index": 2
	}
]

func _ready():
	print("[Level1] start")
	dialog_overlay.hide()
	dialog_overlay.gui_input.connect(_on_dialog_overlay_gui_input)
	dialog_text.bbcode_enabled = true
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
			label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
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
	var labels = data["choice_labels"]
	for i in range(choice_nodes.size()):
		choice_nodes[i].visible = true
		choice_nodes[i].disabled = false
		choice_nodes[i].self_modulate = Color(0.2, 0.2, 0.25, 1)
		if i < choice_labels.size():
			choice_labels[i].text = labels[i] if i < labels.size() else "OPT" + str(i + 1)

func _on_choice_pressed(id: int):
	if is_answered or is_dialog_showing:
		return
	var data = questions_data[current_index]
	var correct_idx: int = data["correct_index"]
	if id == correct_idx:
		is_answered = true
		choice_nodes[id].self_modulate = Color(0.2, 0.6, 0.2, 1)
		_show_dialog("陈伯", "[color=#2ecc71]✓ 正确[/color]\n\n" + data["correct_hint"])
		for btn in choice_nodes:
			btn.disabled = true
		await _wait_for_dialog_dismiss()
		_load_q(current_index + 1)
	else:
		choice_nodes[id].self_modulate = Color(0.7, 0.2, 0.2, 1)
		choice_nodes[id].disabled = true
		var wrong_idx = id if id < correct_idx else id - 1
		var hint = data["wrong_hints"][wrong_idx] if wrong_idx < data["wrong_hints"].size() else {"npc_text": "再试试看。", "knowledge": "仔细看看选项，回忆一下之前学过的知识。"}
		_show_dialog("陈伯", "[color=#e74c3c]✗ 不对哦[/color]\n\n" + hint["npc_text"] + "\n\n[font_size=16][color=#5c4a3a]" + hint["knowledge"] + "[/color][/font_size]")
		is_dialog_showing = true
		for btn in choice_nodes:
			if not btn.disabled:
				btn.disabled = true
		await _wait_for_dialog_dismiss()
		is_dialog_showing = false
		for btn in choice_nodes:
			if btn.self_modulate != Color(0.7, 0.2, 0.2, 1):
				btn.disabled = false

func _show_dialog(npc_name: String, text: String):
	dialog_npc_name.text = npc_name
	dialog_text.text = text
	dialog_continue_hint.show()
	dialog_overlay.show()

func _wait_for_dialog_dismiss():
	await dialog_overlay.gui_input

func _on_dialog_overlay_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		dialog_overlay.hide()

func _show_complete():
	question_label.text = "恭喜通关！你已掌握古建榫卯基础知识。"
	_show_dialog("陈伯", "[color=#f1c40f]恭喜你通过了全部考验！[/color]\n\n你已掌握了古建榫卯的基础知识，真是后生可畏啊。现在返回院落吧。")
	dialog_continue_hint.hide()
	for btn in choice_nodes:
		btn.visible = false
	GameManager.level1_complete = true
	KnowledgeManager.unlock_by_event("level1_complete")
	await get_tree().create_timer(2.5).timeout
	dialog_overlay.hide()
	SceneManager.change_scene(return_scene_path, {"pattern": "fade", "speed": 2.0})
