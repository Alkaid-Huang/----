extends Area2D
class_name NPCQuestTrigger

@export var dialogue_get_ability: DialogueResource  # 获得能力对话
@export var dialogue_remind: DialogueResource       # 催促清草对话
@export var dialogue_enter_level: DialogueResource  # 跳转关卡对话
@export var level_scene_path: String = "res://scenes/Level2.tscn"

var has_ability: bool = false
var is_player_nearby: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		is_player_nearby = true

func _on_body_exited(body):
	if body.name == "Player" or body.is_in_group("player"):
		is_player_nearby = false

func _unhandled_input(event):
	if is_player_nearby and event.is_action_pressed("interact"):
		await _handle_talk()

func _handle_talk():
	var current_dialogue: DialogueResource = null
	
	# 🔀 状态驱动对话分支
	if not has_ability:
		current_dialogue = dialogue_get_ability
	elif not GameManager.grass_cut:
		current_dialogue = dialogue_remind
	else:
		current_dialogue = dialogue_enter_level
	
	if current_dialogue:
		DialogueManager.show_dialogue_balloon(current_dialogue)
		await DialogueManager.dialogue_ended
		
		#  对话结束后的逻辑
		if current_dialogue == dialogue_get_ability:
			has_ability = true
			print("✨ 已获得清理杂草能力")
		elif current_dialogue == dialogue_enter_level:
			print("🚀 清理完成，准备进入第二关...")
			# 可选：解锁对应知识卡片
			# KnowledgeManager.unlock_by_event("level1_complete")
			get_tree().change_scene_to_file(level_scene_path)

func refresh_state():
	print("🔄 触发器状态已刷新，下次对话将进入新分支")
