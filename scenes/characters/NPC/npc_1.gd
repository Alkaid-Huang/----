extends CharacterBody2D

var balloon_scene = preload("res://dialogue/game_dialogue_balloon.tscn")
@onready var interactable_label_component: Control = $InteractableLabelComponent
@onready var interactable_component: InteractableComponent = $InteractableComponent

@export var level_scene_path: String = "res://scenes/mainscenes/level1/level_1.tscn"

var dialogue_get_ability: DialogueResource
var dialogue_remind: DialogueResource
var dialogue_enter_level: DialogueResource

var in_range: bool = false
var has_ability: bool = false
var is_talking: bool = false

func _ready() -> void:
	print("[NPC1] 初始化开始")
	dialogue_get_ability = load("res://dialogue/conversations/act1_meet_uncle.dialogue") as DialogueResource
	dialogue_remind = load("res://dialogue/conversations/remind.dialogue") as DialogueResource
	dialogue_enter_level = load("res://dialogue/conversations/act1_clear_done.dialogue") as DialogueResource
	print("[NPC1] 对话资源加载: get_ability=", dialogue_get_ability != null, " remind=", dialogue_remind != null, " enter_level=", dialogue_enter_level != null)
	print("[NPC1] level_scene_path=", level_scene_path)
	print("[NPC1] has_ability=", has_ability, " GameManager.grass_cut=", GameManager.grass_cut if GameManager else "null")
	interactable_component.interactable_activated.connect(on_interactable_activated)
	interactable_component.interactable_deactivated.connect(on_interactable_deactivated)
	interactable_label_component.hide()
	print("[NPC1] 初始化完成")

func on_interactable_activated() -> void:
	print("[NPC1] 玩家进入交互范围")
	interactable_label_component.show()
	in_range = true

func on_interactable_deactivated() -> void:
	print("[NPC1] 玩家离开交互范围")
	interactable_label_component.hide()
	in_range = false

func _unhandled_input(event: InputEvent) -> void:
	if in_range and not is_talking and event.is_action_pressed("interact"):
		is_talking = true
		await _handle_quest_flow()
		is_talking = false

func _handle_quest_flow():
	print("[NPC1] 处理任务流程: has_ability=", has_ability, " grass_cut=", GameManager.grass_cut if GameManager else "null")
	var current_dialogue: DialogueResource = null
	if not has_ability:
		print("[NPC1] -> 分支1: 获得能力对话")
		current_dialogue = dialogue_get_ability
	elif not GameManager.grass_cut:
		print("[NPC1] -> 分支2: 催促清草对话")
		current_dialogue = dialogue_remind
	else:
		print("[NPC1] -> 分支3: 杂草清完，进入关卡对话")
		current_dialogue = dialogue_enter_level
	if not current_dialogue:
		push_error("[NPC1] 对话资源为空！")
		return
	print("[NPC1] 播放对话: ", current_dialogue.resource_path)
	var balloon: BaseGameDialogueBalloon = balloon_scene.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(current_dialogue, "start")
	print("[NPC1] 等待对话结束...")
	await DialogueManager.dialogue_ended
	print("[NPC1] 对话结束")
	if current_dialogue == dialogue_get_ability:
		has_ability = true
		GameManager.has_ability = true
		print("[NPC1] 已获得除草能力, has_ability=true, GameManager.has_ability=true")
	elif current_dialogue == dialogue_enter_level:
		print("[NPC1] 准备跳转关卡: ", level_scene_path)
		KnowledgeManager.unlock_by_event("grass_cut")
		SceneManager.change_scene(level_scene_path, {"pattern": "fade", "speed": 2.0})

func refresh_state():
	print("[NPC1] 状态刷新, 杂草已清完, 下次对话将进入关卡分支")
