extends CanvasLayer

var is_active := false
var is_drawing := false
var current_line: Line2D = null
var all_points := PackedVector2Array()

var zone := Rect2(320, 68, 256, 256)

func _ready():
	print("[Level3.Draw] _ready, 默认绘制区域 zone=", zone)
	set_process_input(false)

func set_zone(r: Rect2):
	zone = r
	print("[Level3.Draw] set_zone zone=", zone)

func _input(event):
	if not is_active:
		return
	var pos = get_viewport().get_mouse_position()

	if not zone.has_point(pos):
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_drawing = true
			current_line = Line2D.new()
			current_line.default_color = Color.WHITE
			current_line.width = 3.0
			current_line.joint_mode = Line2D.LINE_JOINT_ROUND
			add_child(current_line)
			current_line.add_point(pos)
			all_points.append(pos)
			print("[Level3.Draw] 开始新笔画, pos=", pos)
		else:
			is_drawing = false
			current_line = null
			print("[Level3.Draw] 笔画结束, 总点数=", all_points.size())
	elif event is InputEventMouseMotion and is_drawing:
		if current_line:
			current_line.add_point(pos)
			all_points.append(pos)

func enable():
	print("[Level3.Draw] enable 激活绘制, zone=", zone)
	is_active = true
	set_process_input(true)
	clear()

func disable():
	print("[Level3.Draw] disable 禁用绘制, 总点数=", all_points.size())
	is_active = false
	set_process_input(false)

func clear():
	print("[Level3.Draw] clear 清除所有笔画, 之前点数=", all_points.size())
	for c in get_children():
		if c is Line2D:
			c.queue_free()
	all_points.clear()
	current_line = null

func get_points() -> PackedVector2Array:
	return all_points

func set_strokes_visible(v: bool):
	print("[Level3.Draw] set_strokes_visible ", v)
	for c in get_children():
		if c is Line2D:
			c.visible = v
