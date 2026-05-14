extends Node2D

var _sprite_bounds: Rect2

var balloon_scene = preload("res://dialogue/game_dialogue_balloon.tscn")
var dialogue_act4: DialogueResource
var dialogue_act5: DialogueResource

var npc1_node: CharacterBody2D = null
var player_node: CharacterBody2D = null
var is_talking: bool = false
var in_range: bool = false

const LEVEL3_PATH = "res://scenes/mainscenes/level3/window_flower_level.tscn"

func _ready():
	print("[Main3] 主场景3加载完成, level3_complete=", GameManager.level3_complete)
	_setup_camera_limits()
	_setup_npc_dialogue()
	_disable_npc1_script()

func _disable_npc1_script():
	if not npc1_node:
		return
	npc1_node.set_process(false)
	npc1_node.set_physics_process(false)
	npc1_node.set_process_input(false)
	npc1_node.set_process_unhandled_input(false)
	if npc1_node.has_node("InteractableComponent"):
		var ic = npc1_node.get_node("InteractableComponent")
		ic.set_process(false)
		ic.set_physics_process(false)
		ic.visible = false
		print("[Main3] 已禁用NPC1的InteractableComponent")
	if npc1_node.has_node("InteractableLabelComponent"):
		npc1_node.get_node("InteractableLabelComponent").hide()
		print("[Main3] 已隐藏NPC1的InteractableLabelComponent")
	print("[Main3] 已禁用NPC1自带的npc_1.gd脚本处理")

func _setup_camera_limits():
	var camera = get_node_or_null("Sprite2D/Player/Camera2D")
	var bg = get_node_or_null("Sprite2D")
	if not bg or not bg is Sprite2D:
		return
	var tex = bg.texture
	if not tex:
		return
	var tex_size = tex.get_size()
	var half_w = tex_size.x * bg.scale.x / 2.0
	var half_h = tex_size.y * bg.scale.y / 2.0
	var cx = bg.position.x
	var cy = bg.position.y
	_sprite_bounds = Rect2(cx - half_w, cy - half_h, half_w * 2, half_h * 2)
	if camera and camera is Camera2D:
		camera.limit_left = int(cx - half_w)
		camera.limit_top = int(cy - half_h)
		camera.limit_right = int(cx + half_w)
		camera.limit_bottom = int(cy + half_h)
		print("[Main3] 相机限制: left=", camera.limit_left, " top=", camera.limit_top, " right=", camera.limit_right, " bottom=", camera.limit_bottom)
	print("[Main3] 精灵边界: ", _sprite_bounds)

func _setup_npc_dialogue():
	npc1_node = get_node_or_null("Sprite2D/NPC1")
	player_node = get_node_or_null("Sprite2D/Player")

	if GameManager.level3_complete:
		dialogue_act4 = null
		dialogue_act5 = load("res://dialogue/conversations/act5_back_home.dialogue") as DialogueResource
		print("[Main3] 窗花已完成, 加载通关后对话 dialogue_act5=", dialogue_act5 != null)
	else:
		dialogue_act4 = load("res://dialogue/conversations/act4_window_done.dialogue") as DialogueResource
		dialogue_act5 = null
		print("[Main3] 加载进入关卡前对话 dialogue_act4=", dialogue_act4 != null)

	print("[Main3] NPC1=", npc1_node != null, " Player=", player_node != null)

func _process(_delta):
	var player = get_node_or_null("Sprite2D/Player")
	if not player or not player is CharacterBody2D:
		return
	var gp = player.global_position
	var margin = 20.0
	if gp.x < _sprite_bounds.position.x + margin:
		gp.x = _sprite_bounds.position.x + margin
	if gp.y < _sprite_bounds.position.y + margin:
		gp.y = _sprite_bounds.position.y + margin
	if gp.x > _sprite_bounds.end.x - margin:
		gp.x = _sprite_bounds.end.x - margin
	if gp.y > _sprite_bounds.end.y - margin:
		gp.y = _sprite_bounds.end.y - margin
	player.global_position = gp
	
	_check_player_nearby_npc(gp)

func _check_player_nearby_npc(player_pos: Vector2):
	if not npc1_node or is_talking:
		return
	var npc_pos = npc1_node.global_position
	var distance = player_pos.distance_to(npc_pos)
	in_range = distance < 100.0

func _unhandled_input(event: InputEvent) -> void:
	if in_range and not is_talking and event.is_action_pressed("interact"):
		is_talking = true
		await _start_npc_dialogue()
		is_talking = false

func _start_npc_dialogue():
	print("[Main3] 开始NPC对话")

	var dialogue_res: DialogueResource
	if GameManager.level3_complete and dialogue_act5:
		dialogue_res = dialogue_act5
		print("[Main3] 使用通关后对话")
	elif dialogue_act4:
		dialogue_res = dialogue_act4
		print("[Main3] 使用进入关卡前对话")
	else:
		push_error("[Main3] 对话资源加载失败！")
		return

	var balloon: BaseGameDialogueBalloon = balloon_scene.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(dialogue_res, "start")
	print("[Main3] 等待对话结束...")
	await DialogueManager.dialogue_ended

	if GameManager.level3_complete:
		print("[Main3] 通关后对话结束, 显示修缮完成图片")
		_show_completion_image()
	else:
		print("[Main3] 对话结束，准备跳转到Level3")
		_goto_level3()

func _goto_level3():
	print("[Main3] 跳转到关卡3: ", LEVEL3_PATH)
	if FileAccess.file_exists(LEVEL3_PATH):
		SceneManager.change_scene(LEVEL3_PATH, {"pattern": "fade", "speed": 2.0})
	else:
		push_error("[Main3] Level3场景文件不存在: ", LEVEL3_PATH)

func _show_completion_image():
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "CompletionImageLayer"
	canvas_layer.layer = 100
	add_child(canvas_layer)

	var bg = TextureRect.new()
	bg.name = "CompletionImage"
	bg.texture = load("res://assets/古宅修缮完成.jpg")
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas_layer.add_child(bg)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	var fade = ColorRect.new()
	fade.name = "ImageFade"
	fade.color = Color(0, 0, 0, 1)
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas_layer.add_child(fade)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)

	var tween_in = create_tween()
	tween_in.tween_property(fade, "color", Color(0, 0, 0, 0), 2.0)

	await get_tree().create_timer(4.0).timeout

	var tween = create_tween()
	tween.tween_property(fade, "color", Color(0, 0, 0, 1), 2.0)
	tween.tween_callback(_goto_end)

func _goto_end():
	print("[Main3] 跳转到结局场景")
	SceneManager.change_scene("res://scenes/mainscenes/end/GameEnd.tscn", {"pattern": "fade", "speed": 2.0})
