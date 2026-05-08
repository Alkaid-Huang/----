extends Node2D

# 🎨 UI 节点引用
@onready var question_label: Label = $Question
@onready var choices_container: HBoxContainer = $HBoxContainer
@onready var rich_text_label: RichTextLabel = $Panel/RichTextLabel

# 📦 选项按钮数组
var choice_nodes: Array[TextureButton] = []

# 📊 游戏状态
var current_index: int = 0
var is_answered: bool = false

# 🎯 返回的主场景路径
@export var return_scene_path: String = "res://scenes/mainscenes/main2/scene_main_2.tscn"

# 📚 题库数据
var questions_data: Array[Dictionary] = [
	{
		"question": "第一张图片的榫卯是由那些选项组合而成",
		"choices": ["res://assets/images/第二关场景素材/正确房梁图片.png", "res://assets/images/第二关场景素材/破损房梁_01.png", "res://assets/images/第二关场景素材/破损房梁_02.png"],
		"wrong_hints": ["再想想哦，这个是蓝色。", "不对，这个是黄色。"],
		"correct_hint": "太棒了！红色就是红色！",
		"correct_index": 0
	}
]
# 🎮 初始化
func _ready():
	print("\n🎮 [Level2] ========== 场景加载开始 ==========")
	
	# 🔍 检查全局管理器
	if not KnowledgeManager:
		push_error("❌ KnowledgeManager 未注册！请检查 项目设置 → Autoload")
		rich_text_label.text = "❌ 系统错误：知识管理器未加载"
		return
	else:
		print("✅ KnowledgeManager 已就绪")
	
	# 🔘 获取选项按钮并连接信号
	choice_nodes.clear()
	for child in choices_container.get_children():
		if child is TextureButton:
			choice_nodes.append(child)
			var idx = choice_nodes.size() - 1
			child.pressed.connect(_on_choice_pressed.bind(idx))
	
	# ✨ 开启富文本支持
	rich_text_label.bbcode_enabled = true
	
	# 📝 加载第一题
	if questions_data.size() > 0:
		load_question(0)
	else:
		rich_text_label.text = "⚠️ 暂无题库数据！"
	
	print("✅ [Level2] 初始化完成")
	print("========================================\n")

# 📝 加载题目
func load_question(index: int):
	# 🏆 通关逻辑
	if index >= questions_data.size():
		await _on_level_complete()
		return
	
	is_answered = false
	var data = questions_data[index]
	
	# 1️⃣ 设置问题文字
	question_label.text = data["question"]
	
	# 2️⃣ 加载选项图片
	var choice_paths: Array = data["choices"]
	for i in range(choice_nodes.size()):
		var texture = load(choice_paths[i]) as Texture2D
		if texture:
			choice_nodes[i].texture_normal = texture
			choice_nodes[i].visible = true
		else:
			push_error("❌ 无法加载图片: " + choice_paths[i])
			choice_nodes[i].visible = false
	
	# 3️⃣ 清空提示
	rich_text_label.text = ""
	print("📝 加载第 ", index + 1, " 题：", data["question"])

# ✅ 关卡完成流程（核心修复！）
func _on_level_complete() -> void:
	print("\n🏆 [Level2] ========== 玩家通关 ==========")
	
	# 1️⃣ 显示通关提示
	question_label.text = "🎉 恭喜通关！"
	
	# 2️⃣ 隐藏选项按钮
	for btn in choice_nodes:
		btn.visible = false
	
	# 3️⃣ 🔓 关键修复：设置 GameManager 状态
	if GameManager:
		GameManager.level2_complete = true
		print("✅ [Level2] GameManager.level2_complete = true")
	else:
		print("❌ [Level2] GameManager 未找到！")
	
	# 4️⃣ 解锁知识卡片（修复：用 level2_complete）
	if KnowledgeManager:
		KnowledgeManager.unlock_by_event("level2_complete")
		print("🔓 [Level2] 已解锁知识卡片事件：level2_complete")
	
	# 5️⃣ 💬 播放通关对话（可选）
	print("💬 [Level2] 开始播放通关对话...")
	await _show_completion_dialogue()
	print("✅ [Level2] 对话结束")
	
	# 6️⃣  返回主场景
	_return_to_main_scene()
	
	print("🏆 [Level2] ========== 通关结束 ==========\n")

# 💬 播放通关对话
func _show_completion_dialogue() -> void:
	var dialogue_path = "res://dialogues/level2_complete.dialogue"
	var dialogue = load(dialogue_path) as DialogueResource
	
	if not dialogue:
		print("⚠️ [Level2] 对话文件不存在：", dialogue_path)
		print("   跳过对话，直接返回")
		return
	
	DialogueManager.show_dialogue_balloon(dialogue, "start")
	print("   - 对话气泡已显示")
	
	await _wait_for_dialogue_end()

# 🔁 通用等待函数
func _wait_for_dialogue_end() -> void:
	var finished = false
	
	var on_ended = func():
		finished = true
		print("   - 收到 dialogue_ended 信号")
	
	DialogueManager.dialogue_ended.connect(on_ended, CONNECT_ONE_SHOT)
	
	while not finished:
		await get_tree().process_frame

# 🚀 返回主场景
func _return_to_main_scene() -> void:
	print("🚀 [Level2] 准备返回主场景：", return_scene_path)
	
	var file_path = return_scene_path.replace("res://", "")
	if FileAccess.file_exists(file_path):
		await get_tree().create_timer(0.5).timeout
		print("✅ [Level2] 执行场景跳转")
		get_tree().change_scene_to_file(return_scene_path)
	else:
		push_error("❌ [Level2] 场景文件不存在：", return_scene_path)
		rich_text_label.text = "⚠️ 返回路径错误，请联系开发者"

# 🔘 点击选项回调
func _on_choice_pressed(id: int):
	if is_answered:
		return
	
	var data = questions_data[current_index]
	
	# ✅ 选择正确
	if id == data["correct_index"]:
		is_answered = true
		rich_text_label.text = "[color=#2ecc71]✓ [/color]" + data["correct_hint"]
		print("✅ 答对！第 ", current_index + 1, " 题")
		
		await get_tree().create_timer(1.5).timeout
		current_index += 1
		load_question(current_index)
	
	# ❌ 选择错误
	else:
		var wrong_text: String = "再试试其他选项吧！"
		if id < data["wrong_hints"].size():
			wrong_text = data["wrong_hints"][id]
		
		rich_text_label.text = "[color=#e74c3c]✗ [/color]" + wrong_text
		print("❌ 答错！第 ", current_index + 1, " 题，选项 ", id)
