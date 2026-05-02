extends Node2D

# 获取 UI 节点引用
@onready var question_label: Label = $Question
@onready var choices_container: HBoxContainer = $HBoxContainer
@onready var rich_text_label: RichTextLabel = $Panel/RichTextLabel

# 存储四个选择节点的数组
var choice_nodes: Array[TextureButton] = []

# 当前题目索引
var current_index: int = 0
# 是否已作答（防止重复点击导致逻辑错乱）
var is_answered: bool = false

# ====================== 数据源（纯文本提示） ======================
# 每个元素：问题文字、4个选项图片路径、4个错误提示文字、1个正确提示文字、正确答案索引(0~3)
var questions_data: Array = [
	# 第1题
	{
		"question": "第一题：哪个颜色是红色？",
		"choices": ["res://assets/red.png", "res://assets/blue.png", "res://assets/yellow.png", "res://assets/green.png"],
		"wrong_hints": ["再想想哦，这个是蓝色。", "不对，这个是黄色。", "不对，这个是绿色。"],
		"correct_hint": "太棒了！红色就是红色！",
		"correct_index": 0
	},
	# 第2题
	{
		"question": "第二题：哪个是水果？",
		"choices": ["res://assets/car.png", "res://assets/apple.png", "res://assets/tree.png", "res://assets/house.png"],
		"wrong_hints": ["这是汽车，不是水果。", "这个是苹果，它是对的！等等，你选错了？", "这是树木，不是水果。", "这是房子，不是水果。"],
		"correct_hint": "正确！苹果就是水果！",
		"correct_index": 1
	},
	# 第3题
	{
		"question": "第三题：哪个是动物？",
		"choices": ["res://assets/cat.png", "res://assets/book.png", "res://assets/chair.png", "res://assets/pencil.png"],
		"wrong_hints": ["这是猫，它是动物！(咦，你选错了？)", "这是书，不是动物。", "这是椅子，不是动物。", "这是铅笔，不是动物。"],
		"correct_hint": "对啦！猫咪是可爱的动物！",
		"correct_index": 0
	}
]
# ==================================================

func _ready():
	# 1. 自动获取 HBoxContainer 下的 4 个子节点，并连接点击信号
	for child in choices_container.get_children():
		if child is TextureButton:
			choice_nodes.append(child)
			# 注意：这里绑定 index，也就是 0, 1, 2, 3
			child.pressed.connect(_on_choice_pressed.bind(choice_nodes.size() - 1))
			
	# 2. (可选) 开启BBCode以便支持颜色等，但纯文本不需要也可以
	rich_text_label.bbcode_enabled = false  # 设为 false 直接用纯文本
	
	# 3. 加载第一题
	if questions_data.size() > 0:
		load_question(0)
	else:
		rich_text_label.text = "暂无题库数据！"

# 加载题目的核心函数
func load_question(index: int):
	if index >= questions_data.size():
		rich_text_label.text = "🎉 恭喜你，通关完成！"
		
		await get_tree().create_timer(2.0).timeout
	# 3. 跳转到主菜单场景 (注意修改为你自己的场景文件路径)
		get_tree().change_scene_to_file("res://scenes/test/test_scene_main.tscn")
		return
	
	is_answered = false
	var data = questions_data[index]
	
	# 1. 设置问题文字
	question_label.text = data["question"]
	
	# 2. 加载 4 个选项的图片
	var choice_paths: Array = data["choices"]
	for i in range(choice_nodes.size()):
		var texture = load(choice_paths[i]) as Texture2D
		if texture:
			choice_nodes[i].texture_normal = texture
		else:
			push_error("无法加载图片: " + choice_paths[i])
			
	# 3. 清空之前的提示
	rich_text_label.text = ""

# 点击选项时的回调
func _on_choice_pressed(id: int):
	if is_answered:
		return # 如果已经选对了并等待下一题，禁止再次点击
	
	var data = questions_data[current_index]
	
	# 判断正误
	if id == data["correct_index"]:
		# ========== ✅ 选择正确 ==========
		is_answered = true
		
		# 显示正确的文本提示
		rich_text_label.text = data["correct_hint"]
		
		# 等待 1.5 秒，自动进入下一题
		await get_tree().create_timer(1.5).timeout
		current_index += 1
		load_question(current_index) # 加载下一题
		
	else:
		# ========== ❌ 选择错误 ==========
		# 获取该错误选项对应的提示文本
		var wrong_text: String = data["wrong_hints"][id]
		rich_text_label.text = wrong_text
		
		# (可选) 如果你希望选错后不能再点，取消下面这行的注释
		# is_answered = true
