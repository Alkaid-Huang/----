extends Area2D

@export var target_scene: String = "res://scenes/mainscenes/main3/scene_main_3.tscn"

func _ready():
	print("[MenKou] 门口入口初始化, target=", target_scene)
	$PromptLabel.visible = false

func _process(delta):
	_update_prompt()

func _update_prompt():
	if GameManager.level2_complete:
		$PromptLabel.text = "按F进入"
		$PromptLabel.modulate = Color(1, 1, 0.3, 1)
		$PromptLabel.visible = true
	else:
		$PromptLabel.visible = false

func _unhandled_input(event):
	if event.is_action_pressed("interact"):
		if not GameManager.level2_complete:
			return
		print("[MenKou] 按F进入场景3: ", target_scene)
		if ResourceLoader.exists(target_scene):
			SceneManager.change_scene(target_scene, {"pattern": "fade", "speed": 2.0})
		else:
			var scene_resource = ResourceLoader.load(target_scene, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE)
			if scene_resource:
				print("[MenKou] 直接加载成功, 切换场景")
				SceneManager.change_scene(target_scene, {"pattern": "fade", "speed": 2.0})
			else:
				push_error("[MenKou] 场景加载失败: " + target_scene)
