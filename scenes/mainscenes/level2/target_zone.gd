extends Area2D

var current_beam: CharacterBody2D = null

func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_create_arrow()

func _create_arrow():
	var panel = PanelContainer.new()
	panel.name = "HintPanel"
	add_child(panel)
	panel.position = Vector2(-200.0, -55.0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.92, 0.82, 1)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.3, 0.15, 1)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	var hint = Label.new()
	hint.name = "HintLabel"
	hint.text = "等待房梁落到此处\n按下「落梁」按钮"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	panel.add_child(hint)

	var line = Line2D.new()
	line.name = "Arrow"
	line.width = 3.0
	line.default_color = Color(0, 0, 0, 1)
	var tip_x = -120.0
	var base_x = tip_x - 40.0
	var cy = 21.0
	line.add_point(Vector2(base_x, cy))
	line.add_point(Vector2(tip_x - 6, cy))
	line.add_point(Vector2(tip_x - 12, cy - 7))
	line.add_point(Vector2(tip_x, cy))
	line.add_point(Vector2(tip_x - 12, cy + 7))
	line.add_point(Vector2(tip_x - 6, cy))
	add_child(line)
	var tween = create_tween().set_loops().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(line, "position:x", 10.0, 0.8)
	tween.tween_property(line, "position:x", 0.0, 0.8)

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
