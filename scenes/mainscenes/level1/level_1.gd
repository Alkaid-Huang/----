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

# 🎯 返回的主场景路径（按需修改）
@export var return_scene_path: String = "res://scenes/test/test_scene_main.tscn"

# 📚 题库数据
var questions_data: Array = [
	{
		"question": "柱类榫卯的作用是固定柱脚与柱身，防位移、抗倾覆，是竖向构件的基础，下面哪类榫卯是柱形榫卯？",
		"choices": ["res://assets/images/第一关素材/柱类榫卯素材.png", "res://assets/images/第一关素材/枋类榫卯素材.png", "res://assets/images/第一关素材/梁类榫卯素材.png"],
		"wrong_hints": ["不对，这个是枋类榫卯，作用是横向拉结柱架，增强整体稳定性，多采用直榫或半透榫。", "不对哟~这个是梁类榫卯，作用是梁柱核心连接，刚柔并济，传递荷载同时兼具抗震性"],
		"correct_hint": "正确，这个就是柱类榫卯",
		"correct_index": 0
	}
]

# 🎮 初始化
func _ready():
	print("🎮 [Level1] 场景加载开始...")
	
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
			# 绑定点击信号，传入索引（用闭包避免循环变量问题）
			var idx = choice_nodes.size() - 1
			child.pressed.connect(_on_choice_pressed.bind(idx))
	
	# ✨ 开启富文本支持（支持 [color] 等标签）
	rich_text_label.bbcode_enabled = true
	
	# 📝 加载第一题
	if questions_data.size() > 0:
		load_question(0)
	else:
		rich_text_label.text = "⚠️ 暂无题库数据！"
	
	print("✅ [Level1] 初始化完成")

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

# ✅ 关卡完成流程（核心！）
func _on_level_complete() -> void:
	print("🏆 [Level1] 玩家通关！")
	
	# 1️⃣ 显示通关提示
	question_label.text = "🎉 恭喜通关！"
	
	# 2️⃣ 隐藏选项按钮
	for btn in choice_nodes:
		btn.visible = false
	
	# 3️⃣ 🔓 解锁知识卡片（用事件名，方便管理）
	KnowledgeManager.unlock_by_event("level1_complete")
	print("🔓 已解锁知识卡片事件：level1_complete")
	
	# 4️⃣ 💬 播放通关对话（关键：用 await 等待结束）
	print("💬 开始播放通关对话...")
	await _show_completion_dialogue()
	print("✅ 对话结束")
	
	# 5️⃣ 🚀 返回主场景
	_return_to_main_scene()

# 💬 播放通关对话（带等待）
func _show_completion_dialogue() -> void:
	# 加载对话资源
	var dialogue_path = "res://dialogues/level1_complete.dialogue"
	var dialogue = load(dialogue_path) as DialogueResource
	
	if not dialogue:
		push_error("❌ 无法加载对话文件：", dialogue_path)
		return
	
	# 显示对话气泡（根据你的 DialogueManager 插件调整）
	DialogueManager.show_dialogue_balloon(dialogue, "start")
	print("   - 对话气泡已显示")
	
	# ✅ 等待对话结束（通用兼容写法）
	await _wait_for_dialogue_end()

# 🔁 通用等待函数（兼容不同插件版本）
func _wait_for_dialogue_end() -> void:
	var finished = false
	
	# 创建一次性回调
	var on_ended = func():
		finished = true
		print("   - 收到 dialogue_ended 信号")
	
	# 连接信号（确保只触发一次）
	DialogueManager.dialogue_ended.connect(on_ended, CONNECT_ONE_SHOT)
	
	# 等待信号触发（每帧检查）
	while not finished:
		await get_tree().process_frame

# 🚀 返回主场景
func _return_to_main_scene() -> void:
	print("🚀 准备返回主场景：", return_scene_path)
	
	# 验证场景文件存在
	var file_path = return_scene_path.replace("res://", "")
	if FileAccess.file_exists(file_path):
		# 小延迟让玩家看到反馈
		await get_tree().create_timer(0.5).timeout
		print("✅ 执行场景跳转")
		get_tree().change_scene_to_file(return_scene_path)
	else:
		push_error("❌ 场景文件不存在：", return_scene_path)
		rich_text_label.text = "⚠️ 返回路径错误，请联系开发者"

# 🔘 点击选项回调
func _on_choice_pressed(id: int):
	if is_answered:
		return  # 防止重复点击
	
	var data = questions_data[current_index]
	
	# ✅ 选择正确
	if id == data["correct_index"]:
		is_answered = true
		rich_text_label.text = "[color=#2ecc71]✓ [/color]" + data["correct_hint"]
		print("✅ 答对！第 ", current_index + 1, " 题")
		
		# 等待 1.5 秒进入下一题
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
		
		# 可选：选错后禁止再点（取消注释启用）
		# is_answered = true
