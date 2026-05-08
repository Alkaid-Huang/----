extends Area2D

var current_beam: CharacterBody2D = null

func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D):
	if area.get_parent() is CharacterBody2D and area.get_parent().has_method("get_beam_type"):
		current_beam = area.get_parent()

func _on_area_exited(area: Area2D):
	if area.get_parent() == current_beam:
		current_beam = null

func try_confirm() -> String:
	if current_beam == null:
		return "empty"
	
	if current_beam.get_beam_type():
		return "success"
	else:
		return "fail"
