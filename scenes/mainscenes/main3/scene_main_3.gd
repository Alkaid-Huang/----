extends Node2D

var _sprite_bounds: Rect2

func _ready():
	print("[Main3] 主场景3加载完成 - 房屋完整，NPC2可对话进入第三关")
	_setup_camera_limits()

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
