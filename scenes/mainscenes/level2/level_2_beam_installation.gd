extends Node2D

# 🎨 场景资源导出
@export var good_beam_scene: PackedScene 
@export var bad_beam_scene: PackedScene

# 🔗 节点引用
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var target_zone: Area2D = $TargetZone
@onready var ui_layer: CanvasLayer = $UI
@onready var btn_confirm: Button = $UI/Button_Confirm
@onready var label_status: Label = $UI/Label_Status
@onready var label_result: Label = $UI/Label_Result

# 🔍 Liang 节点引用（如果存在）
@onready var liang_node: Node = get_node_or_null("Liang")

# 📊 游戏状态
var is_game_over: bool = false
var is_dialogue_playing: bool = false  # ✅ 新增：对话播放中标志
var spawn_timer: Timer = null

func _ready():
	print("\n🏗️ [Level2] ========== 场景加载开始 ==========")
	_check_required_nodes()
	btn_confirm.pressed.connect(_on_confirm_pressed)
	start_game()
	print("🏗️ [Level2] ========== 初始化完成 ==========\n")

func _check_required_nodes():
	print("🔍 [Level2] 节点检查：")
	_ensure_node(liang_node, "Liang", true)  # 可选节点
	_ensure_node(spawn_point, "SpawnPoint", false)
	_ensure_node(target_zone, "TargetZone", false)
	_ensure_node(ui_layer, "UI", false)

func _ensure_node(node: Node, name: String, optional: bool):
	if node:
		print("  ✅ ", name, " 已找到")
		# 检查方法（如果是 Liang）
		if name == "Liang" and node.has_method("set_game_active"):
			print("     ✅ 有 set_game_active 方法")
	elif optional:
		print("  ⚠️ ", name, " 未找到（可选）")
	else:
		print("  ❌ ", name, " 未找到！请检查场景树")

# 🎮 开始游戏
func start_game():
	print("🎮 [Level2] 开始游戏...")
	is_game_over = false
	is_dialogue_playing = false  # ✅ 重置对话标志
	_set_liang_active(true)
	_reset_ui()
	_cleanup_beams()
	_spawn_loop()
	print("✅ [Level2] 游戏已开始")

func _reset_ui():
	label_status.text = "瞄准好房梁！"
	label_result.text = ""
	btn_confirm.text = "确认"
	_set_button_enabled(true)  # ✅ 启用按钮

func _set_liang_active(active: bool):
	if liang_node and liang_node.has_method("set_game_active"):
		liang_node.set_game_active(active)
		print("  🔧 Liang.set_game_active(", active, ")")

func _cleanup_beams():
	var count = 0
	for child in get_children():
		if child is CharacterBody2D and child.has_method("get_beam_type"):
			child.queue_free()
			count += 1
	if count > 0:
		print("  🧹 清理了 ", count, " 个房梁")

func _spawn_loop():
	if spawn_timer:
		spawn_timer.stop()
		spawn_timer.queue_free()
	
	spawn_timer = Timer.new()
	spawn_timer.name = "SpawnTimer"
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timeout)
	spawn_timer.start(randf_range(1.0, 3.0))

func _on_spawn_timeout():
	if not is_game_over and not is_dialogue_playing:
		_spawn_beam()

func _spawn_beam():
	var is_good = randi() % 2 == 0
	var beam_type = "好房梁" if is_good else "坏房梁"
	var scene_to_spawn = good_beam_scene if is_good else bad_beam_scene
	
	if scene_to_spawn == null:
		push_error("❌ 场景资源未赋值！")
		return
	
	var beam_instance = scene_to_spawn.instantiate()
	beam_instance.position = Vector2(spawn_point.position.x, -100)
	add_child(beam_instance)
	print("🪵 生成 ", beam_type, " @ ", beam_instance.position)

# 🔘 按钮点击处理（✅ 修复：对话期间禁用）
func _on_confirm_pressed():
	# ✅ 对话播放中时禁用按钮响应
	if is_dialogue_playing:
		print("⚠️ 对话播放中，忽略按钮点击")
		return
	
	if is_game_over:
		print("🔄 游戏已结束，重新开始")
		restart_game()
		return
	
	print("🎯 检查目标区域...")
	var result = target_zone.try_confirm()
	print("📊 确认结果：", result)
	
	if result == "empty":
		label_status.text = "请瞄准房梁！"
		return
	
	if result == "success":
		print("✅ 好房梁！处理成功...")
		_set_button_enabled(false)  # ✅ 禁用按钮防止打断
		await handle_success()
		_set_button_enabled(true)   # ✅ 恢复按钮
	elif result == "fail":
		print("❌ 坏房梁！处理失败...")
		_set_button_enabled(false)
		await handle_failure()
		_set_button_enabled(true)

# ✅ 按钮启用/禁用辅助函数
func _set_button_enabled(enabled: bool):
	btn_confirm.disabled = not enabled
	if enabled:
		print("🔘 按钮已启用")
	else:
		print("🔒 按钮已禁用（对话/跳转中）")

# 🏆 成功处理（核心修复版）
func handle_success() -> void:
	print("\n🏆 [Level2] ========== 房梁安装成功 ==========")
	
	# 🎨 更新UI
	label_result.text = "上梁成功！"
	label_result.modulate = Color.GREEN
	label_status.text = "准备下一关..."
	
	# 🛑 停止游戏逻辑
	is_game_over = true
	is_dialogue_playing = true  # ✅ 标记对话播放中
	_set_liang_active(false)
	
	# 💬 播放对话 + 等待结束
	await _play_dialogue_and_wait()
	
	# 🚀 跳转到下一关（✅ 确保在对话结束后执行）
	_jump_to_next_scene()
	
	is_dialogue_playing = false  # ✅ 重置标志
	print("🏆 [Level2] ========== 成功处理结束 ==========\n")

# 💬 播放对话并安全等待
func _play_dialogue_and_wait() -> void:
	print("💬 [Level2] 准备播放对话...")
	
	var dialogue_path = "res://dialogue/conversations/remind.dialogue"
	var dialogue = load(dialogue_path) as DialogueResource
	
	if not dialogue:
		print("⚠️ 对话文件加载失败：", dialogue_path)
		return
	
	print("✅ 对话资源已加载：", dialogue.resource_path)
	
	# ✅ 显示对话气球
	DialogueManager.show_dialogue_balloon(dialogue, "start")
	print("⏳ 等待对话结束...")
	
	# ✅ 安全等待（带超时保护）
	await _wait_for_dialogue_safe(15.0)
	print("✅ 对话已结束")

# 🔁 安全等待对话结束（带超时 + 防卡死）
func _wait_for_dialogue_safe(timeout_seconds: float) -> void:
	var finished = false
	var start_time = Time.get_ticks_msec()
	
	var on_ended = func():
		finished = true
		print("  ✅ 收到 dialogue_ended 信号")
	
	# 连接一次性信号
	DialogueManager.dialogue_ended.connect(on_ended, CONNECT_ONE_SHOT)
	
	# 每帧检查
	while not finished:
		await get_tree().process_frame
		
		# 超时检查
		if Time.get_ticks_msec() - start_time > timeout_seconds * 1000:
			print("⚠️ 对话等待超时（", timeout_seconds, "秒），强制继续")
			# 清理信号
			if DialogueManager.dialogue_ended.is_connected(on_ended):
				DialogueManager.dialogue_ended.disconnect(on_ended)
			return
	
	# 清理信号（如果还没触发）
	if DialogueManager.dialogue_ended.is_connected(on_ended):
		DialogueManager.dialogue_ended.disconnect(on_ended)

# 🚀 跳转到下一关
func _jump_to_next_scene():
	print("\n🚀 [Level2] ========== 准备跳转 ==========")
	
	var next_scene = "res://scenes/mainscenes/main3/scene_main_3.tscn"
	print("📁 目标路径：", next_scene)
	
	# 🔍 调试1：检查文件是否存在
	var exists = FileAccess.file_exists(next_scene)
	print("📄 文件存在：", exists)
	
	if not exists:
		# 尝试不带前缀
		var alt_path = next_scene.replace("res://", "")
		var exists_alt = FileAccess.file_exists(alt_path)
		print("📄 备用路径存在（", alt_path, "）：", exists_alt)
	
	# 🔍 调试2：列出目标文件夹内容
	_list_directory("res://scenes/mainscenes/main3/")
	
	# 🔍 调试3：打印当前场景信息
	print("🎮 当前场景：", get_tree().current_scene.name)
	print("🎮 当前场景路径：", get_tree().current_scene.filename)
	
	# ✅ 执行跳转
	if exists:
		await get_tree().create_timer(0.8).timeout
		print("🔄 执行 change_scene_to_file...")
		get_tree().change_scene_to_file(next_scene)
	else:
		push_error("❌ 目标场景不存在！")
		_set_button_enabled(true)
	
	print("🚀 [Level2] ========== 跳转结束 ==========\n")

# 🔍 辅助：列出文件夹内容
func _list_directory(dir_path: String):
	print("📂 文件夹内容：", dir_path)
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				print("   - 📄 ", file_name)
			else:
				print("   - 📁 ", file_name)
			file_name = dir.get_next()
	else:
		print("❌ 无法打开文件夹")

# ❌ 失败处理
func handle_failure() -> void:
	print("\n💥 [Level2] ========== 房梁安装失败 ==========")
	
	label_result.text = "这是朽木！房屋倒塌！"
	label_result.modulate = Color.RED
	label_status.text = "游戏结束"
	
	is_game_over = true
	_set_liang_active(false)
	btn_confirm.text = "再来一局"
	
	if spawn_timer:
		spawn_timer.stop()
	
	print("💥 [Level2] ========== 失败处理结束 ==========\n")

# 🔄 重新开始
func restart_game():
	print("🔄 [Level2] 重新开始游戏...")
	_set_button_enabled(false)  # 防止重复点击
	await get_tree().create_timer(0.3).timeout
	start_game()
	_set_button_enabled(true)
