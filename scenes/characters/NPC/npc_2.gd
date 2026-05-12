extends CharacterBody2D

var balloon_scene = preload("res://dialogue/game_dialogue_balloon.tscn")
@onready var interactable_label_component: Control = $InteractableLabelComponent
@onready var interactable_component: InteractableComponent = $InteractableComponent

@export var dialogue_path: String = "res://dialogue/conversations/act2_meet_lin.dialogue"
@export var target_scene: String = "res://scenes/mainscenes/level2/level_2_beam_installation.tscn"

var dialogue: DialogueResource
var in_range: bool = false
var is_talking: bool = false

func _ready() -> void:
	print("[NPC2] 初始化: dialogue_path=", dialogue_path, " target_scene=", target_scene)
	dialogue = load(dialogue_path) as DialogueResource
	if dialogue:
		print("[NPC2] 对话资源加载成功: ", dialogue.resource_path)
	else:
		push_error("[NPC2] 对话资源加载失败: ", dialogue_path)
	interactable_component.interactable_activated.connect(on_interactable_activated)
	interactable_component.interactable_deactivated.connect(on_interactable_deactivated)
	interactable_label_component.hide()
	print("[NPC2] 初始化完成")

func on_interactable_activated() -> void:
	print("[NPC2] 玩家进入交互范围")
	interactable_label_component.show()
	in_range = true

func on_interactable_deactivated() -> void:
	print("[NPC2] 玩家离开交互范围")
	interactable_label_component.hide()
	in_range = false

func _unhandled_input(event: InputEvent) -> void:
	if in_range and not is_talking and event.is_action_pressed("interact"):
		is_talking = true
		await _talk_and_jump()
		is_talking = false

func _talk_and_jump():
	if not dialogue:
		push_error("[NPC2] 对话资源为空！")
		return
	print("[NPC2] 播放对话: ", dialogue.resource_path)
	var balloon = balloon_scene.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(dialogue, "start")
	GameManager.has_talked_to_npc = true
	print("[NPC2] 等待对话结束...")
	await DialogueManager.dialogue_ended
	print("[NPC2] 对话结束, 准备跳转: ", target_scene)
	if FileAccess.file_exists(target_scene):
		SceneManager.change_scene(target_scene, {"pattern": "fade", "speed": 2.0})
	else:
		push_error("[NPC2] 目标场景不存在: ", target_scene)
