extends CharacterBody2D
class_name Liang

@export var is_good_beam: bool = true

var speed = 400
static var game_active: bool = true

func _process(delta):
	if not game_active:
		return
		
	position.y += speed * delta
	
	if position.y > 1200:
		queue_free()

func get_beam_type() -> bool:
	return is_good_beam

static func set_game_active(active: bool) -> void:
	game_active = active
