class_name WeedArea
extends Area2D

signal cleared

var is_cleared: bool = false
var player_nearby: bool = false

var _sprite: Sprite2D
var _audio: AudioStreamPlayer
var _shader_material: ShaderMaterial

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	for child in get_children():
		if child is Sprite2D:
			_sprite = child
			break

	if _sprite:
		var shader = load("res://shaders/weed_shake.gdshader")
		_shader_material = ShaderMaterial.new()
		_shader_material.shader = shader
		_shader_material.set_shader_parameter("shake_intensity", 0.0)
		_sprite.material = _shader_material

	_audio = AudioStreamPlayer.new()
	_audio.stream = load("res://assets/font/拔草.mp3")
	_audio.bus = "SFX"
	add_child(_audio)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false

func _unhandled_input(event):
	if event.is_action_pressed("interact") and player_nearby:
		if GameManager and not GameManager.has_ability:
			return
		_do_clear()

func _do_clear():
	if is_cleared:
		return
	is_cleared = true

	_audio.play()

	if _shader_material:
		var tween = create_tween()
		tween.tween_method(_set_shake, 0.0, 1.0, 0.25)
		tween.tween_method(_set_shake, 1.0, 0.0, 0.25)
		tween.tween_callback(_finish_clear)
	else:
		_finish_clear()

func _set_shake(val: float):
	_shader_material.set_shader_parameter("shake_intensity", val)

func _finish_clear():
	visible = false
	cleared.emit()
