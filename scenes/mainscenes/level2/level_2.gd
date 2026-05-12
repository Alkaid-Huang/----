extends Node2D

@onready var question_label: Label = $Question
@onready var choices_container: HBoxContainer = $HBoxContainer
@onready var rich_text_label: RichTextLabel = $Panel/RichTextLabel

var choice_nodes: Array[TextureButton] = []
var current_index: int = 0
var is_answered: bool = false

@export var return_scene_path: String = "res://scenes/mainscenes/main2/scene_main_2.tscn"

var questions_data: Array[Dictionary] = [
	{
		"question": "第一张图片的榫卯是由那些选项组合而成",
		"choices": ["res://assets/images/第二关场景素材/正确房梁图片.png", "res://assets/images/第二关场景素材/破损房梁_01.png", "res://assets/images/第二关场景素材/破损房梁_02.png"],
		"choice_labels": ["正确房梁", "破损房梁1", "破损房梁2"],
		"wrong_hints": ["再想想哦，这个是蓝色。", "不对，这个是黄色。"],
		"correct_hint": "太棒了！红色就是红色！",
		"correct_index": 0
	}
]

func _ready():
	print("[Level2_Quiz] 场景加载开始")
	if not KnowledgeManager:
		push_error("[Level2_Quiz] KnowledgeManager 未注册")
		rich_text_label.text = "系统错误：知识管理器未加载"
		return
	print("[Level2_Quiz] KnowledgeManager 已就绪")
	choice_nodes.clear()
	for child in choices_container.get_children():
		if child is TextureButton:
			choice_nodes.append(child)
			var idx = choice_nodes.size() - 1
			child.pressed.connect(_on_choice_pressed.bind(idx))
	rich_text_label.bbcode_enabled = true
	if questions_data.size() > 0:
		load_question(0)
	else:
		rich_text_label.text = "暂无题库数据"
	print("[Level2_Quiz] 初始化完成")

func load_question(index: int):
	if index >= questions_data.size():
		await _on_level_complete()
		return
	is_answered = false
	var data = questions_data[index]
	question_label.text = data["question"]
	var choice_paths: Array = data["choices"]
	var labels: Array = data.get("choice_labels", [])
	for i in range(choice_nodes.size()):
		var texture = load(choice_paths[i]) as Texture2D
		if texture:
			choice_nodes[i].texture_normal = texture
			choice_nodes[i].visible = true
			for child in choice_nodes[i].get_children():
				if child is Label: child.queue_free()
			choice_nodes[i].self_modulate = Color(1, 1, 1, 1)
		else:
			choice_nodes[i].texture_normal = null
			choice_nodes[i].visible = true
			choice_nodes[i].self_modulate = Color(0.2, 0.2, 0.25, 1)
			choice_nodes[i].custom_minimum_size = Vector2(120, 120)
			for child in choice_nodes[i].get_children():
				if child is Label: child.queue_free()
			var label = Label.new()
			if i < labels.size():
				label.text = labels[i]
			else:
				label.text = "选项" + str(i+1)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 18)
			label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			choice_nodes[i].add_child(label)
	rich_text_label.text = ""
	print("[Level2_Quiz] 加载第 ", index + 1, " 题")

func _on_level_complete() -> void:
	print("[Level2_Quiz] 通关")
	question_label.text = "恭喜通关！"
	for btn in choice_nodes:
		btn.visible = false
	if GameManager:
		GameManager.level2_complete = true
	if KnowledgeManager:
		KnowledgeManager.unlock_by_event("level2_complete")
	print("[Level2_Quiz] 播放通关对话...")
	await _show_completion_dialogue()
	_return_to_main_scene()

func _show_completion_dialogue() -> void:
	var dialogue_res = load("res://dialogue/conversations/act3_beam_success.dialogue") as DialogueResource
	if not dialogue_res:
		print("[Level2_Quiz] 对话文件不存在，跳过")
		return
	DialogueManager.show_dialogue_balloon(dialogue_res, "start")
	var finished = false
	var on_ended = func():
		finished = true
	DialogueManager.dialogue_ended.connect(on_ended, CONNECT_ONE_SHOT)
	while not finished:
		await get_tree().process_frame

func _return_to_main_scene() -> void:
	print("[Level2_Quiz] 返回主场景: ", return_scene_path)
	if FileAccess.file_exists(return_scene_path):
		SceneManager.change_scene(return_scene_path, {"pattern": "fade", "speed": 2.0})
	else:
		push_error("[Level2_Quiz] 场景文件不存在: ", return_scene_path)
		rich_text_label.text = "返回路径错误，请联系开发者"

func _on_choice_pressed(id: int):
	if is_answered:
		return
	var data = questions_data[current_index]
	if id == data["correct_index"]:
		is_answered = true
		rich_text_label.text = "[color=#2ecc71]✓ [/color]" + data["correct_hint"]
		print("[Level2_Quiz] 答对! 第 ", current_index + 1, " 题")
		await get_tree().create_timer(1.5).timeout
		current_index += 1
		load_question(current_index)
	else:
		var wrong_text: String = "再试试其他选项吧！"
		if id < data["wrong_hints"].size():
			wrong_text = data["wrong_hints"][id]
		rich_text_label.text = "[color=#e74c3c]✗ [/color]" + wrong_text
		print("[Level2_Quiz] 答错! 第 ", current_index + 1, " 题, 选项 ", id)
