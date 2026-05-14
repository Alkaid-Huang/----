extends Node2D

@export var good_beam_scene: PackedScene
@export var bad_beam_scene: PackedScene

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var target_zone: Area2D = $TargetZone
@onready var ui_layer: CanvasLayer = $UI
@onready var btn_confirm: Button = $UI/Button_Confirm
@onready var label_status: Label = $UI/Label_Status
@onready var label_result: Label = $UI/Label_Result

var is_game_over: bool = false
var is_dialogue_playing: bool = false
var spawn_timer: Timer = null

func _ready():
	print("[Level2] 场景加载开始")
	_check_required_nodes()
	btn_confirm.pressed.connect(_on_confirm_pressed)
	start_game()
	print("[Level2] 初始化完成")

func _check_required_nodes():
	print("[Level2] 节点检查:")
	_ensure_node(spawn_point, "SpawnPoint")
	_ensure_node(target_zone, "TargetZone")
	_ensure_node(ui_layer, "UI")

func _ensure_node(node: Node, name: String):
	if node:
		print("[Level2]   ", name, " 已找到")
	else:
		print("[Level2]   ", name, " 未找到! 请检查场景树")

func start_game():
	print("[Level2] 开始游戏")
	is_game_over = false
	is_dialogue_playing = false
	_reset_ui()
	_cleanup_beams()
	_spawn_loop()

func _reset_ui():
	label_status.text = "瞄准好房梁！"
	label_result.text = ""
	btn_confirm.text = "确认"
	_set_button_enabled(true)

func _cleanup_beams():
	var count = 0
	for child in get_children():
		if child is CharacterBody2D and child.has_method("get_beam_type"):
			child.queue_free()
			count += 1
	if count > 0:
		print("[Level2] 清理了 ", count, " 个房梁")

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
		push_error("[Level2] 场景资源未赋值!")
		return
	var beam_instance = scene_to_spawn.instantiate()
	beam_instance.position = Vector2(spawn_point.position.x, -100)
	add_child(beam_instance)
	print("[Level2] 生成 ", beam_type, " @ ", beam_instance.position)

func _on_confirm_pressed():
	if is_dialogue_playing:
		print("[Level2] 对话播放中，忽略按钮点击")
		return
	if is_game_over:
		print("[Level2] 游戏已结束，重新开始")
		restart_game()
		return
	print("[Level2] 检查目标区域...")
	var result = target_zone.try_confirm()
	print("[Level2] 确认结果: ", result)
	if result == "empty":
		label_status.text = "请瞄准房梁！"
		return
	if result == "success":
		print("[Level2] 好房梁! 处理成功...")
		_set_button_enabled(false)
		await handle_success()
		_set_button_enabled(true)
	elif result == "fail":
		print("[Level2] 坏房梁! 处理失败...")
		_set_button_enabled(false)
		await handle_failure()
		_set_button_enabled(true)

func _set_button_enabled(enabled: bool):
	btn_confirm.disabled = not enabled
	print("[Level2] 按钮", "已启用" if enabled else "已禁用")

func handle_success() -> void:
	print("[Level2] 房梁安装成功!")
	label_result.text = "上梁成功！"
	label_result.modulate = Color.GREEN
	label_status.text = "准备下一关..."
	is_game_over = true
	is_dialogue_playing = true
	GameManager.level2_complete = true
	print("[Level2] level2_complete = true")
	KnowledgeManager.unlock_by_event("level2_complete")
	print("[Level2] 已解锁知识卡片: level2_complete")
	await _play_dialogue_and_wait()
	_jump_to_next_scene()
	is_dialogue_playing = false

func _play_dialogue_and_wait() -> void:
	print("[Level2] 播放通关对话...")
	var dialogue_res = load("res://dialogue/conversations/act3_beam_success.dialogue") as DialogueResource
	if not dialogue_res:
		print("[Level2] 对话文件加载失败，跳过")
		return
	print("[Level2] 对话资源已加载: ", dialogue_res.resource_path)
	DialogueManager.show_dialogue_balloon(dialogue_res, "start")
	await _wait_for_dialogue_safe(15.0)
	print("[Level2] 对话已结束")

func _wait_for_dialogue_safe(timeout_seconds: float) -> void:
	var finished = false
	var start_time = Time.get_ticks_msec()
	var on_ended = func(_resource):
		finished = true
	DialogueManager.dialogue_ended.connect(on_ended, CONNECT_ONE_SHOT)
	while not finished:
		await get_tree().process_frame
		if Time.get_ticks_msec() - start_time > timeout_seconds * 1000:
			print("[Level2] 对话等待超时(", timeout_seconds, "秒)，强制继续")
			if DialogueManager.dialogue_ended.is_connected(on_ended):
				DialogueManager.dialogue_ended.disconnect(on_ended)
			return
	if DialogueManager.dialogue_ended.is_connected(on_ended):
		DialogueManager.dialogue_ended.disconnect(on_ended)

func _jump_to_next_scene():
	var next_scene = "res://scenes/mainscenes/main2/scene_main_2.tscn"
	print("[Level2] 跳转到: ", next_scene)
	var exists = FileAccess.file_exists(next_scene)
	if exists:
		SceneManager.change_scene(next_scene, {"pattern": "fade", "speed": 2.0})
	else:
		push_error("[Level2] 目标场景不存在: ", next_scene)
		_set_button_enabled(true)

func handle_failure() -> void:
	print("[Level2] 房梁安装失败!")
	label_result.text = "这是朽木！房屋倒塌！"
	label_result.modulate = Color.RED
	label_status.text = "游戏结束"
	is_game_over = true
	btn_confirm.text = "再来一局"
	if spawn_timer:
		spawn_timer.stop()

func restart_game():
	print("[Level2] 重新开始游戏...")
	_set_button_enabled(false)
	await get_tree().create_timer(0.3).timeout
	start_game()
	_set_button_enabled(true)
