extends NodeState

@export var player: CharacterBody2D
@export var animated_sprite_2d: AnimatedSprite2D
@export var speed: int = 100


func _on_physics_process(_delta: float) -> void:
	var direction = GameInputEvents.movement_input()

	if animated_sprite_2d and direction != Vector2.ZERO:
		match direction:
			Vector2.UP:
				animated_sprite_2d.play("walk_up")
			Vector2.DOWN:
				animated_sprite_2d.play("walk_down")
			Vector2.LEFT:
				animated_sprite_2d.play("walk_left")
			Vector2.RIGHT:
				animated_sprite_2d.play("walk_right")
		print("[Walk] dir=", direction, " anim=", animated_sprite_2d.animation)
	elif animated_sprite_2d:
		print("[Walk] idle, anim=", animated_sprite_2d.animation)

	player.velocity = direction * speed
	player.move_and_slide()


func _on_next_transitions() -> void:
	if not GameInputEvents.is_movement_input():
		transition.emit("Idle")
