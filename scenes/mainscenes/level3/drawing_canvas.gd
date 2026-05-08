extends CanvasLayer

var is_active := false
var is_drawing := false
var current_line: Line2D = null
var all_points := PackedVector2Array()

# 严格限制绘制区域：左上角折叠区 (适配 1152x648)
const ZONE = Rect2(320, 68, 256, 256)

func _ready():
	set_process_input(false)

func _input(event):
	if not is_active: return
	var pos = get_viewport().get_mouse_position()
	
	# ✅ 限制只能在左上角亮区内绘制
	if not ZONE.has_point(pos): return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_drawing = true
			# ✅ 每次按下鼠标创建新线段，解决多笔自动连线问题
			current_line = Line2D.new()
			current_line.default_color = Color.WHITE
			current_line.width = 3.0
			current_line.joint_mode = Line2D.LINE_JOINT_ROUND
			add_child(current_line)
			current_line.add_point(pos)
			all_points.append(pos)
		else:
			is_drawing = false
			current_line = null
	elif event is InputEventMouseMotion and is_drawing:
		if current_line:
			current_line.add_point(pos)
			all_points.append(pos)

func enable():
	is_active = true
	set_process_input(true)
	clear()

func disable():
	is_active = false
	set_process_input(false)

func clear():
	for c in get_children():
		if c is Line2D: c.queue_free()
	all_points.clear()
	current_line = null

func get_points() -> PackedVector2Array:
	return all_points

func set_strokes_visible(v: bool):
	for c in get_children():
		if c is Line2D: c.visible = v
