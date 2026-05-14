extends Area2D

@export var target_scene: String = "res://scenes/mainscenes/main3/scene_main_3.tscn"

var player_nearby: bool = false

func _ready():
	print("[MenKou] 门口入口初始化, target=", target_scene)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_prompt()

func _process(delta):
	_update_prompt()

func _update_prompt():
	if GameManager.level2_complete:
		$PromptLabel.text = "按F进入"
		$PromptLabel.modulate = Color(1, 1, 0.3, 1)
	else:
		$PromptLabel.text = "请先完成任务"
		$PromptLabel.modulate = Color(1, 0.5, 0.5, 1)

func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		print("[MenKou] 玩家靠近门口")
		player_nearby = true

func _on_body_exited(body):
	if body.name == "Player" or body.is_in_group("player"):
		print("[MenKou] 玩家离开门口")
		player_nearby = false

func _unhandled_input(event):
	if player_nearby and event.is_action_pressed("interact"):
		if not GameManager.level2_complete:
			print("[MenKou] 关卡未完成，无法进入")
			return
		print("[MenKou] 按F进入场景3: ", target_scene)
		if FileAccess.file_exists(target_scene):
			SceneManager.change_scene(target_scene, {"pattern": "fade", "speed": 2.0})
		else:
			push_error("[MenKou] 目标场景不存在: " + target_scene)
