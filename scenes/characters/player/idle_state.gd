extends NodeState

@export var player: CharacterBody2D
@export var animated_sprite_2d: AnimatedSprite2D

var _last_direction: Vector2 = Vector2.DOWN


func _on_enter() -> void:
	print("[Idle] enter, animated_sprite_2d=", animated_sprite_2d, " last_dir=", _last_direction)
	_play_idle()


func _on_physics_process(_delta: float) -> void:
	var dir = GameInputEvents.movement_input()
	if dir != Vector2.ZERO:
		_last_direction = dir


func _play_idle() -> void:
	if not animated_sprite_2d:
		return
	match _last_direction:
		Vector2.UP:
			animated_sprite_2d.play("idle_up")
		Vector2.DOWN:
			animated_sprite_2d.play("idle_down")
		Vector2.LEFT:
			animated_sprite_2d.play("idle_left")
		Vector2.RIGHT:
			animated_sprite_2d.play("idle_right")
		_:
			animated_sprite_2d.play("idle_down")


func _on_next_transitions() -> void:
	if GameInputEvents.is_movement_input():
		transition.emit("Walk")
