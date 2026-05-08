extends CharacterBody2D

# 🎈 对话气球预加载
var balloon_scene = preload("res://dialogue/game_dialogue_balloon.tscn")

# 📦 组件引用
@onready var interactable_label_component: Control = $InteractableLabelComponent
@onready var interactable_component: InteractableComponent = $InteractableComponent

# 💬 对话资源导出
@export var dialogue_first_talk: DialogueResource       # 1. 第一次：提示选木头
@export var dialogue_wood_selected: DialogueResource    # 2. 木头已选：等待通关
@export var dialogue_enter_level2_1: DialogueResource   # 3. 已通关：进入关卡 2.1

# 🚪 场景路径
@export var level2_1_scene_path: String = "res://scenes/mainscenes/level2/level_2_beam_installation.tscn"

# 📊 状态变量
var in_range: bool = false
var is_talking: bool = false

func _ready() -> void:
	print("\n========================================")
	print(" [NPC2] ========== 初始化开始 ==========")
	print("========================================")
	
	# 🔍 检查对话资源
	_check_dialogue_resources()
	
	# 📊 检查全局状态
	_check_global_state()
	
	# 🔗 连接交互组件
	_connect_components()
	
	print("✅ [NPC2] ========== 初始化完成 ==========")
	print("========================================\n")

func _check_dialogue_resources():
	print("\n📋 [NPC2] 对话资源检查：")
	_print_resource("1. dialogue_first_talk", dialogue_first_talk)
	_print_resource("2. dialogue_wood_selected", dialogue_wood_selected)
	_print_resource("3. dialogue_enter_level2_1", dialogue_enter_level2_1)

func _print_resource(name: String, resource: DialogueResource):
	print("  ", name, ":")
	if resource:
		print("     ✅ 已设置")
		print("     路径：", resource.resource_path)
	else:
		print("     ❌ 未设置！")

func _check_global_state():
	print("\n📊 [NPC2] 全局状态检查：")
	if GameManager:
		print("  ✅ GameManager 已连接")
		print("  - has_talked_to_npc: ", GameManager.has_talked_to_npc)
		print("  - wood_selected: ", GameManager.wood_selected)
		print("  - level2_complete: ", GameManager.level2_complete)
	else:
		print("  ❌ GameManager 未找到！")

func _connect_components():
	print("\n🔗 [NPC2] 连接交互组件...")
	if interactable_component:
		print("  ✅ InteractableComponent 已找到")
		interactable_component.interactable_activated.connect(on_interactable_activated)
		interactable_component.interactable_deactivated.connect(on_interactable_deactivated)
		print("  ✅ 信号已连接")
	else:
		print("  ❌ InteractableComponent 未找到！")
	
	if interactable_label_component:
		interactable_label_component.hide()

func on_interactable_activated() -> void:
	print("🟢 [NPC2] 玩家进入交互范围")
	interactable_label_component.show()
	in_range = true

func on_interactable_deactivated() -> void:
	print("🔴 [NPC2] 玩家离开交互范围")
	interactable_label_component.hide()
	in_range = false

func _unhandled_input(event: InputEvent) -> void:
	if in_range and not is_talking:
		if event.is_action_pressed("interact") or event.is_action_pressed("show_dialogue"):
			print("\n⌨️ [NPC2] ========== 检测到交互按键 ==========")
			is_talking = true
			await _handle_quest_flow()
			is_talking = false
			print("⌨️ [NPC2] ========== 交互处理结束 ==========\n")

# 🧠 核心任务流程
func _handle_quest_flow():
	print("\n🔄 [NPC2] ========== 开始处理任务流程 ==========")
	
	# 📊 打印当前状态
	_print_current_state()
	
	var current_dialogue: DialogueResource = null
	var branch_name: String = ""
	
	# 🔀 状态判断（优先级从高到低）
	
	# ✅ 分支1：关卡2已完成 → 进入关卡2.1
	if GameManager and GameManager.level2_complete:
		branch_name = "分支1：关卡2已完成，进入关卡2.1"
		print("  → ", branch_name)
		current_dialogue = dialogue_enter_level2_1
		
	# ✅ 分支2：木头已选但关卡未完成 → 提醒等待
	elif GameManager and GameManager.wood_selected and not GameManager.level2_complete:
		branch_name = "分支2：木头已选，等待关卡2完成"
		print("  → ", branch_name)
		current_dialogue = dialogue_wood_selected if dialogue_wood_selected else dialogue_first_talk
		
	# ✅ 分支3：还没对话过 → 第一次对话
	elif GameManager and not GameManager.has_talked_to_npc:
		branch_name = "分支3：第一次对话，提示选木头"
		print("  → ", branch_name)
		current_dialogue = dialogue_first_talk
		
	# ✅ 分支4：已对话但木头没选 → 提醒选木头
	else:
		branch_name = "分支4：已对话，提醒选木头"
		print("  → ", branch_name)
		current_dialogue = dialogue_first_talk
	
	# 💬 播放对话
	_play_dialogue(current_dialogue, branch_name)
	
	print("🔄 [NPC2] ========== 任务流程结束 ==========\n")

func _print_current_state():
	print("📊 [NPC2] 当前状态：")
	if GameManager:
		print("  - GameManager.has_talked_to_npc: ", GameManager.has_talked_to_npc)
		print("  - GameManager.wood_selected: ", GameManager.wood_selected)
		print("  - GameManager.level2_complete: ", GameManager.level2_complete)
	else:
		print("  - GameManager: null")

func _play_dialogue(dialogue: DialogueResource, branch_name: String):
	print("\n💬 [NPC2] 准备播放对话...")
	print("  分支：", branch_name)
	
	if not dialogue:
		print("⚠️ [NPC2] 当前对话资源为空！")
		return
	
	print("  对话路径：", dialogue.resource_path)
	
	if not balloon_scene:
		print("❌ [NPC2] balloon_scene 未加载！")
		return
	
	var balloon = balloon_scene.instantiate()
	get_tree().current_scene.add_child(balloon)
	print("  ✅ 气球已实例化并添加到场景")
	
	balloon.start(dialogue, "start")
	print("  ✅ 对话已启动")
	
	# ⏳ 等待对话结束
	print("\n⏳ [NPC2] 等待对话结束...")
	
	if balloon.has_signal("dialogue_ended"):
		print("  - 使用气球信号：balloon.dialogue_ended")
		await balloon.dialogue_ended
	elif DialogueManager and DialogueManager.has_signal("dialogue_ended"):
		print("  - 使用全局信号：DialogueManager.dialogue_ended")
		await DialogueManager.dialogue_ended
	else:
		print("  ⚠️ 未找到对话结束信号，使用超时保护")
		await _wait_with_timeout(10.0)
	
	print("✅ [NPC2] 对话结束")
	
	# 🔚 对话后处理
	_handle_post_dialogue(dialogue)

func _handle_post_dialogue(dialogue: DialogueResource):
	print("\n🔚 [NPC2] ========== 对话后处理 ==========")
	
	# 标记已对话（只在第一次对话时）
	if dialogue == dialogue_first_talk and GameManager and not GameManager.has_talked_to_npc:
		GameManager.has_talked_to_npc = true
		print("✨ [NPC2] 标记：GameManager.has_talked_to_npc = true")
	
	# 跳转逻辑（只有分支1需要跳转）
	if dialogue == dialogue_enter_level2_1:
		print("🚀 [NPC2] 准备跳转至关卡2.1")
		print("  场景路径：", level2_1_scene_path)
		
		if FileAccess.file_exists(level2_1_scene_path):
			print("  ✅ 场景文件存在")
			await get_tree().create_timer(0.5).timeout
			print("  🔄 [NPC2] 执行场景跳转...")
			get_tree().change_scene_to_file(level2_1_scene_path)
		else:
			print("  ❌ 场景文件不存在！")
			print("     路径：", level2_1_scene_path)
	else:
		print("ℹ️ [NPC2] 无跳转动作（当前分支：", 
			"进入2.1" if dialogue == dialogue_enter_level2_1 else 
			"等待通关" if dialogue == dialogue_wood_selected else 
			"提示选木头", ")")
	
	print("🔚 [NPC2] ========== 对话后处理结束 ==========\n")

func _wait_with_timeout(seconds: float) -> void:
	print("  ⏱️ 开始超时等待：", seconds, "秒")
	var start = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < seconds * 1000:
		await get_tree().process_frame
	print("  ⚠️ 超时等待结束")
