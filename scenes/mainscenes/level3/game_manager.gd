extends Node

@export var required_accuracy: float = 0.70
@export var next_level: String = "res://levels/Level3.tscn"

@onready var canvas = $"../DrawingLayer"
@onready var pivot = $"../PaperGroup"
@onready var target = $"../PaperGroup/TargetQuarter"
@onready var mask_r = $"../PaperGroup/QuarterMask/MaskRight"
@onready var mask_b = $"../PaperGroup/QuarterMask/MaskBottom"
@onready var unfold_cont = $"../UnfoldedContainer"
@onready var bar = $"../ValidationUI/ProgressBar"
@onready var lbl = $"../ValidationUI/LabelResult"
@onready var btn_fold = $"../ValidationUI/BtnFold"
@onready var btn_unfold = $"../ValidationUI/BtnUnfold"
@onready var btn_reset = $"../ValidationUI/BtnReset"

var img: Image
const TOL = 15.0

func _ready():
	img = target.texture.get_image() if target.texture else null
	_set_masks(false)
	btn_unfold.disabled = true
	lbl.text = "点击【折叠】开始剪裁"
	btn_fold.pressed.connect(_on_fold)
	btn_unfold.pressed.connect(_on_unfold)
	btn_reset.pressed.connect(_on_reset)

func _on_fold():
	canvas.enable()
	_set_masks(true)
	btn_fold.disabled = true
	btn_unfold.disabled = false
	lbl.text = "在亮区沿纹样剪裁（支持多笔）"

func _on_unfold():
	canvas.disable()
	canvas.set_strokes_visible(false) # ✅ 隐藏原笔触，防止重叠
	btn_unfold.disabled = true
	lbl.text = "展开验证中..."
	
	_spawn_symmetry(canvas.get_points())
	
	var acc = _validate(canvas.get_points())
	bar.value = acc * 100
	
	if acc >= required_accuracy:
		lbl.text = "窗花完成！精美绝伦！"
		lbl.modulate = Color.GREEN
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file(next_level)
	else:
		lbl.text = "贴合度不足，请调整或重做 (需%d%%)" % int(required_accuracy*100)
		lbl.modulate = Color.RED
		btn_unfold.disabled = false
		canvas.set_strokes_visible(true) # 失败允许继续补画

func _on_reset():
	canvas.clear()
	canvas.disable()
	canvas.set_strokes_visible(true)
	_set_masks(false)
	for c in unfold_cont.get_children(): c.queue_free()
	bar.value = 0
	lbl.text = "点击【折叠】开始剪裁"
	lbl.modulate = Color.WHITE
	btn_fold.disabled = false
	btn_unfold.disabled = true

func _spawn_symmetry(pts: PackedVector2Array):
	for c in unfold_cont.get_children(): c.queue_free()
	if pts.size() < 2: return
	
	var center = pivot.global_position # (576, 324)
	
	# ✅ 四个象限的镜像向量 (相对于中心点)
	var mirrors = [
		Vector2(1, 1),   # 左上 (原图)
		Vector2(-1, 1),  # 右上 (X轴翻转)
		Vector2(1, -1),  # 左下 (Y轴翻转)
		Vector2(-1, -1)  # 右下 (双轴翻转)
	]
	
	for m in mirrors:
		var line = Line2D.new()
		line.default_color = Color.WHITE
		line.width = 3.0
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		
		for pt in pts:
			# 计算相对于中心的偏移，应用镜像后加入容器
			var offset = (pt - center) * m
			line.add_point(offset)
			
		unfold_cont.add_child(line)
		# 展开动画
		line.scale = Vector2(0.1, 0.1)
		create_tween().tween_property(line, "scale", Vector2(1, 1), 0.4).set_ease(Tween.EASE_OUT)

func _validate(pts: PackedVector2Array) -> float:
	if img == null or pts.size() < 5: return 0.0
	
	var valid = 0
	
	# ✅ Godot 4.x 正确方法：手动计算全局矩形
	var local_rect = target.get_rect()  # 局部矩形（含 Offset）
	var global_pos = target.global_position  # 全局位置
	var global_rect = Rect2(global_pos + local_rect.position, local_rect.size)
	
	var img_w = img.get_width()
	var img_h = img.get_height()
	
	# 计算实际显示缩放比例
	var scale_x = global_rect.size.x / img_w
	var scale_y = global_rect.size.y / img_h
	
	for pt in pts:
		# 全局坐标 转 图片局部坐标
		var rel_x = pt.x - global_rect.position.x
		var rel_y = pt.y - global_rect.position.y
		
		var ix = int(rel_x / scale_x)
		var iy = int(rel_y / scale_y)
		
		# 边界检查
		if ix < 0 or ix >= img_w or iy < 0 or iy >= img_h:
			continue
			
		# 颜色检测（红色纹样）
		var c = img.get_pixel(ix, iy)
		if c.r > 0.5 and c.g < 0.3 and c.b < 0.3:
			valid += 1
			
	return float(valid) / pts.size()

func _near_red(x, y) -> bool:
	var r = int(TOL)
	for dx in range(-r, r+1):
		for dy in range(-r, r+1):
			if dx*dx + dy*dy <= r*r:
				var c = img.get_pixel(clamp(x+dx,0,255), clamp(y+dy,0,255))
				if c.r > 0.5 and c.g < 0.3 and c.b < 0.3: return true
	return false

func _set_masks(v):
	mask_r.visible = v
	mask_b.visible = v
