extends NodeState

@export var player: CharacterBody2D
@export var animated_sprite_2d: Control
@export var speed: int = 50

func _on_physics_process(_delta : float) -> void:
	var direction = GameInputEvents.movement_input()

	if animated_sprite_2d:
		if direction == Vector2.UP:
			animated_sprite_2d.color = Color(0.25, 0.55, 0.85, 1)
		elif direction == Vector2.RIGHT:
			animated_sprite_2d.color = Color(0.2, 0.45, 0.9, 1)
		elif direction == Vector2.DOWN:
			animated_sprite_2d.color = Color(0.3, 0.5, 0.8, 1)
		elif direction == Vector2.LEFT:
			animated_sprite_2d.color = Color(0.35, 0.6, 0.8, 1)

	player.velocity = direction * speed
	player.move_and_slide()

func _on_next_transitions() -> void:
	if !GameInputEvents.is_movement_input():
		transition.emit("Idle")
