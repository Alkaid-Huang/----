class_name WeedArea
extends Area2D

signal cleared

var is_cleared: bool = false
var player_nearby: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

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
	visible = false
	cleared.emit()
