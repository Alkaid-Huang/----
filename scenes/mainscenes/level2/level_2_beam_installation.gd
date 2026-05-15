extends Node2D

@export var good_beam_scene: PackedScene
@export var bad_beam_scene: PackedScene
@export var return_scene_path: String = "res://scenes/mainscenes/main2/scene_main_2.tscn"

var current_beam: CharacterBody2D = null
var is_game_active: bool = true
var beam_confirmed: bool = false

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var target_zone: Area2D = $TargetZone
@onready var label_status: Label = $UI/Label_Status
@onready var button_confirm: Button = $UI/Button_Confirm
@onready var label_result: Label = $UI/Label_Result

func _ready():
	print("[Level2] _ready 开始")
	button_confirm.pressed.connect(_on_button_pressed)
	label_status.text = "点击落梁"
	label_result.text = ""
	button_confirm.text = "落梁"
	button_confirm.disabled = false
	is_game_active = true
	print("[Level2] _ready 完成，等待玩家点击落梁")

func spawn_beam():
	print("[Level2] spawn_beam 开始")
	if current_beam != null:
		current_beam.queue_free()
		current_beam = null
	
	var random_beam = randi() % 2
	var beam_scene: PackedScene
	
	if random_beam == 0:
		beam_scene = good_beam_scene
		print("[Level2] 生成好木梁")
	else:
		beam_scene = bad_beam_scene
		print("[Level2] 生成坏木梁")
	
	if beam_scene:
		current_beam = beam_scene.instantiate()
		current_beam.position = spawn_point.position
		current_beam.beam_fell_off.connect(_on_beam_fell_off)
		add_child(current_beam)
		label_status.text = "等待下落"
		label_result.text = ""
		button_confirm.text = "确认"
		button_confirm.disabled = false
		is_game_active = true
		beam_confirmed = false
		print("[Level2] 木梁已生成，位置:", current_beam.position)

func _on_button_pressed():
	print("[Level2] _on_button_pressed, current_beam:", current_beam != null)
	if current_beam == null:
		spawn_beam()
		return
	
	if not is_game_active or beam_confirmed:
		print("[Level2] 游戏未激活或已确认，返回")
		return
	
	var result = target_zone.try_confirm()
	print("[Level2] 确认结果:", result)
	
	match result:
		"empty":
			label_result.text = "目标区域为空！"
			label_result.modulate = Color(1, 0.5, 0)
		"success":
			label_result.text = "识别成功！好木梁"
			label_result.modulate = Color(0.2, 0.8, 0.2)
			_handle_success()
		"fail":
			label_result.text = "识别失败！坏木梁"
			label_result.modulate = Color(0.8, 0.2, 0.2)
			_handle_fail()

func _handle_success():
	print("[Level2] _handle_success - 成功处理")
	GameManager.level2_complete = true
	KnowledgeManager.unlock_by_event("level2_complete")
	if current_beam != null:
		var beam_position = current_beam.position
		print("[Level2] 成功时木梁位置（保持不变）:", beam_position)
		current_beam.set_game_active(false)
		beam_confirmed = true
		button_confirm.disabled = true
		label_status.text = "安装完成"
		print("[Level2] 木梁位置已锁定在:", current_beam.position)
		await get_tree().create_timer(1.5).timeout
		_return_to_main_scene()

func _handle_fail():
	print("[Level2] _handle_fail - 失败处理，允许重试")
	if current_beam != null:
		current_beam.set_game_active(false)
		beam_confirmed = true
		button_confirm.disabled = true
		label_status.text = "识别失败"
		await get_tree().create_timer(1.5).timeout
		beam_confirmed = false
		is_game_active = true
		spawn_beam()

func _on_beam_fell_off():
	print("[Level2] 木梁掉落屏幕外，重新生成")
	current_beam = null
	if not beam_confirmed:
		spawn_beam()

func _return_to_main_scene():
	print("[Level2] 返回主场景: ", return_scene_path)
	if ResourceLoader.exists(return_scene_path):
		SceneManager.change_scene(return_scene_path, {"pattern": "fade", "speed": 2.0})
	else:
		var scene_resource = ResourceLoader.load(return_scene_path, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE)
		if scene_resource:
			print("[Level2] 直接加载成功, 返回主场景")
			SceneManager.change_scene(return_scene_path, {"pattern": "fade", "speed": 2.0})
		else:
			push_error("[Level2] 返回场景加载失败: ", return_scene_path)
