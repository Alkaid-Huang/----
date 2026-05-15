extends Area2D

@export var level2_scene_path: String = "res://scenes/mainscenes/level2/level_2_beam_installation.tscn"

var is_selected: bool = false
var player_nearby: bool = false

func _ready():
	print("[Wood] 初始化: ", name, " level2_scene_path=", level2_scene_path)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if GameManager.wood_selected:
		print("[Wood] 已选过，隐藏")
		visible = false
		is_selected = true

func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		print("[Wood] 玩家进入范围")
		player_nearby = true

func _on_body_exited(body):
	if body.name == "Player" or body.is_in_group("player"):
		print("[Wood] 玩家离开范围")
		player_nearby = false

func _unhandled_input(event):
	if player_nearby and not is_selected:
		if event.is_action_pressed("interact"):
			print("[Wood] 检测到交互按键")
			await _select_wood()

func _select_wood():
	print("[Wood] 开始选取木料")
	if not GameManager.has_talked_to_npc:
		print("[Wood] 还没与NPC对话! 请先接任务")
		return
	is_selected = true
	GameManager.wood_selected = true
	print("[Wood] wood_selected = true")
	visible = false
	if has_method("set_collision_layer_value"):
		set_collision_layer_value(1, false)
	print("[Wood] 准备跳转: ", level2_scene_path)
	if ResourceLoader.exists(level2_scene_path):
		SceneManager.change_scene(level2_scene_path, {"pattern": "fade", "speed": 2.0})
	else:
		var scene_resource = ResourceLoader.load(level2_scene_path, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE)
		if scene_resource:
			print("[Wood] 直接加载成功, 切换场景")
			SceneManager.change_scene(level2_scene_path, {"pattern": "fade", "speed": 2.0})
		else:
			push_error("[Wood] 场景加载失败: " + level2_scene_path)
