extends NodeState

@export var player: CharacterBody2D
@export var animated_sprite_2d: Control

var _last_direction: Vector2 = Vector2.DOWN

func _on_physics_process(_delta : float) -> void:
	var dir = GameInputEvents.movement_input()
	if dir != Vector2.ZERO:
		_last_direction = dir

	if animated_sprite_2d:
		match _last_direction:
			Vector2.UP: animated_sprite_2d.color = Color(0.25, 0.55, 0.85, 1)
			Vector2.LEFT: animated_sprite_2d.color = Color(0.35, 0.6, 0.8, 1)
			Vector2.RIGHT: animated_sprite_2d.color = Color(0.2, 0.45, 0.9, 1)
			_: animated_sprite_2d.color = Color(0.3, 0.5, 0.8, 1)

func _on_next_transitions() -> void:
	if GameInputEvents.is_movement_input():
		transition.emit("Walk")
