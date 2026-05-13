extends Node2D

func _ready():
	print("[Main3] 主场景3加载完成 - 房屋完整，NPC2可对话进入第三关")
	_fix_background()

func _fix_background():
	var bg = get_node_or_null("Sprite2D")
	if not bg or not bg is ColorRect:
		return
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "BGLayer"
	canvas_layer.layer = -100
	add_child(canvas_layer)
	var fixed_bg = ColorRect.new()
	fixed_bg.name = "FixedBG"
	fixed_bg.color = bg.color
	fixed_bg.anchor_right = 1.0
	fixed_bg.anchor_bottom = 1.0
	fixed_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(fixed_bg)
	bg.color = Color(0, 0, 0, 0)
	bg.clip_contents = false
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	print("[Main3] 背景已固定到CanvasLayer")
