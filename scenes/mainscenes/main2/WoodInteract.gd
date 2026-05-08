extends Area2D

@export var level2_scene_path: String = "res://scenes/Level2.tscn"

var is_selected: bool = false
var player_nearby: bool = false

func _ready():
	print("🪵[Wood] 初始化：", name)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if GameManager.wood_selected:
		print("⚠️ [Wood] 已选过，隐藏")
		visible = false
		is_selected = true

func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		print("🟢 [Wood] 玩家进入范围")
		player_nearby = true

func _on_body_exited(body):
	if body.name == "Player" or body.is_in_group("player"):
		print("🔴 [Wood] 玩家离开范围")
		player_nearby = false

func _unhandled_input(event):
	if player_nearby and not is_selected:
		if event.is_action_pressed("interact") or event.is_action_pressed("show_dialogue"):
			print("⌨️ [Wood] 检测到交互按键")
			await _select_wood()

func _select_wood():
	print("🪵[Wood] ========== 开始选取 ==========")
	
	# 🔒 检查是否已与 NPC 对话
	if not GameManager.has_talked_to_npc:
		print("⚠️ [Wood] 还没与 NPC 对话！请先接任务")
		return
	
	# ✅ 更新状态
	is_selected = true
	GameManager.wood_selected = true
	print("✅ [Wood] GameManager.wood_selected = true")
	
	# 🎨 视觉反馈
	visible = false
	if has_method("set_collision_layer_value"):
		set_collision_layer_value(1, false)
	
	# 🚀 跳转关卡 2（✅ 关键修复：路径检查）
	print("🚀 [Wood] 准备跳转至 Level2")
	print("   场景路径：", level2_scene_path)
	
	# ✅ 修复1：file_exists 需要完整路径（带 res://）
	if FileAccess.file_exists(level2_scene_path):
		print("✅ [Wood] 场景文件验证通过")
		# ✅ 修复2：跳转前加个小延迟，让玩家看到反馈
		await get_tree().create_timer(0.5).timeout
		print("🔄 [Wood] 执行跳转...")
		get_tree().change_scene_to_file(level2_scene_path)
	else:
		# ❌ 调试：打印详细错误
		print("❌ [Wood] 场景文件不存在！")
		print("   检查路径：", level2_scene_path)
		print("   文件是否存在：", FileAccess.file_exists(level2_scene_path))
		
		# 🔍 尝试常见错误路径
		var alt_path = level2_scene_path.replace("res://scenes/Level2.tscn", "res://scenes/level2.tscn")
		if FileAccess.file_exists(alt_path):
			print("💡 [Wood] 提示：是不是大小写问题？试试：", alt_path)
		
		# 可选：显示错误提示给玩家
		# rich_text_label.text = "⚠️ 关卡文件缺失，请联系开发者"
