extends CharacterBody2D

var balloon_scene = preload("res://dialogue/game_dialogue_balloon.tscn")
@onready var interactable_label_component: Control = $InteractableLabelComponent
@onready var interactable_component: InteractableComponent = $InteractableComponent

@export var dialogue_get_ability: DialogueResource
@export var dialogue_remind: DialogueResource
@export var dialogue_enter_level: DialogueResource
@export var level_scene_path: String = "res://scenes/mainscenes/level1/level_1.tscn"

var in_range: bool
var has_ability: bool = false
var is_talking: bool = false

func _ready() -> void:
	print(" [NPC] 初始化开始...")
	print("  - dialogue_get_ability: ", dialogue_get_ability)
	print("  - dialogue_remind: ", dialogue_remind)
	print("  - dialogue_enter_level: ", dialogue_enter_level)
	print("  - level_scene_path: ", level_scene_path)
	print("  - has_ability 初始值: ", has_ability)
	print("  - GameManager.grass_cut 初始值: ", GameManager.grass_cut if GameManager else "null")
	
	interactable_component.interactable_activated.connect(on_interactable_activated)
	interactable_component.interactable_deactivated.connect(on_interactable_deactivated)
	interactable_label_component.hide()
	
	print("✅ [NPC] 初始化完成")

func on_interactable_activated() -> void:
	print("🟢 [NPC] 玩家进入交互范围")
	interactable_label_component.show()
	in_range = true

func on_interactable_deactivated() -> void:
	print("🔴 [NPC] 玩家离开交互范围")
	interactable_label_component.hide()
	in_range = false

# 在 NPC 脚本的 _unhandled_input 函数里：
func _unhandled_input(event: InputEvent) -> void:
	# ✅ 统一使用 "interact" 按键
	if in_range and not is_talking and event.is_action_pressed("interact"):
		is_talking = true
		await _handle_quest_flow()
		is_talking = false

func _handle_quest_flow():
	print("🔄 [NPC] 开始处理任务流程...")
	print("  - has_ability: ", has_ability)
	print("  - GameManager.grass_cut: ", GameManager.grass_cut if GameManager else "null")
	
	var current_dialogue: DialogueResource = null
	
	if not has_ability:
		print("  → 分支1：获得能力对话")
		current_dialogue = dialogue_get_ability
	elif not GameManager.grass_cut:
		print("  → 分支2：催促清草对话")
		current_dialogue = dialogue_remind
	else:
		print("  → 分支3：进入关卡对话")
		current_dialogue = dialogue_enter_level
	
	if current_dialogue:
		print("📜 [NPC] 播放对话：", current_dialogue.resource_path if current_dialogue else "null")
		var balloon: BaseGameDialogueBalloon = balloon_scene.instantiate()
		get_tree().current_scene.add_child(balloon)
		balloon.start(current_dialogue, "start")
		
		print("⏳ [NPC] 等待对话结束...")
		await DialogueManager.dialogue_ended
		print("✅ [NPC] 对话结束")
		
		if current_dialogue == dialogue_get_ability:
			has_ability = true
			GameManager.has_ability = true  # ✅ 关键：同步到全局！
			print("✨ [NPC] 已获得除草能力，GameManager.has_ability = true")
			print("✨ [NPC] 已获得除草能力，has_ability = true")
		elif current_dialogue == dialogue_enter_level:
			print("🚀 [NPC] 准备跳转关卡：", level_scene_path)
			# KnowledgeManager.unlock_by_event("level1_complete")
			get_tree().change_scene_to_file(level_scene_path)
	else:
		print("⚠️ [NPC] 当前对话资源为空！")
