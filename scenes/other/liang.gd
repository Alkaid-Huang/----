extends CharacterBody2D
class_name Liang

signal beam_fell_off

@export var is_good_beam: bool = true

var speed: float = 400
var game_active: bool = true

func _process(delta):
	if not game_active:
		return
	position.y += speed * delta
	if position.y > 1200:
		beam_fell_off.emit()
		queue_free()

func get_beam_type() -> bool:
	return is_good_beam

func set_game_active(active: bool) -> void:
	game_active = active
	if not active:
		speed = 0
		set_process(false)
	print("[Liang] set_game_active(", active, ") is_good=", is_good_beam)
