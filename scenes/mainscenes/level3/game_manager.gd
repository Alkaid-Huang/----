extends Node

@export var required_accuracy: float = 0.70
@export var next_level: String = "res://scenes/mainscenes/GameEnd.tscn"

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
	print("[Level3] 窗花关卡初始化, required_accuracy=", required_accuracy, " next_level=", next_level)
	if target is Sprite2D and target.texture:
		img = target.texture.get_image()
		print("[Level3] 目标纹理已加载, 尺寸=", img.get_width(), "x", img.get_height())
	else:
		img = null
		print("[Level3] 目标纹理为空(ColorRect占位), 使用覆盖度验证")
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
	print("[Level3] 进入绘制模式")

func _on_unfold():
	canvas.disable()
	canvas.set_strokes_visible(false)
	btn_unfold.disabled = true
	lbl.text = "展开验证中..."
	print("[Level3] 展开验证, 点数=", canvas.get_points().size())
	_spawn_symmetry(canvas.get_points())
	var acc = _validate(canvas.get_points())
	bar.value = acc * 100
	print("[Level3] 验证精度=", acc)
	if acc >= required_accuracy:
		lbl.text = "窗花完成！精美绝伦！"
		lbl.modulate = Color.GREEN
		print("[Level3] 窗花通关! 跳转: ", next_level)
		GameManager.level3_complete = true
		KnowledgeManager.unlock_by_event("level3_complete")
		await get_tree().create_timer(1.5).timeout
		SceneManager.change_scene(next_level, {"pattern": "fade", "speed": 2.0})
	else:
		lbl.text = "贴合度不足，请调整或重做 (需%d%%)" % int(required_accuracy*100)
		lbl.modulate = Color.RED
		btn_unfold.disabled = false
		canvas.set_strokes_visible(true)

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
	print("[Level3] 重置")

func _spawn_symmetry(pts: PackedVector2Array):
	for c in unfold_cont.get_children(): c.queue_free()
	if pts.size() < 2: return
	var center = pivot.global_position
	var mirrors = [
		Vector2(1, 1),
		Vector2(-1, 1),
		Vector2(1, -1),
		Vector2(-1, -1)
	]
	for m in mirrors:
		var line = Line2D.new()
		line.default_color = Color.WHITE
		line.width = 3.0
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		for pt in pts:
			var offset = (pt - center) * m
			line.add_point(offset)
		unfold_cont.add_child(line)
		line.scale = Vector2(0.1, 0.1)
		create_tween().tween_property(line, "scale", Vector2(1, 1), 0.4).set_ease(Tween.EASE_OUT)

func _validate(pts: PackedVector2Array) -> float:
	if pts.size() < 5:
		print("[Level3] 点数太少(", pts.size(), "), 返回0")
		return 0.0
	if img == null:
		return _validate_grid_fallback(pts)
	var valid = 0
	var local_rect = target.get_rect()
	var global_pos = target.global_position
	var global_rect = Rect2(global_pos + local_rect.position, local_rect.size)
	var img_w = img.get_width()
	var img_h = img.get_height()
	var scale_x = global_rect.size.x / img_w
	var scale_y = global_rect.size.y / img_h
	for pt in pts:
		var rel_x = pt.x - global_rect.position.x
		var rel_y = pt.y - global_rect.position.y
		var ix = int(rel_x / scale_x)
		var iy = int(rel_y / scale_y)
		if ix < 0 or ix >= img_w or iy < 0 or iy >= img_h:
			continue
		var c = img.get_pixel(ix, iy)
		if c.r > 0.5 and c.g < 0.3 and c.b < 0.3:
			valid += 1
	return float(valid) / pts.size()

func _validate_grid_fallback(pts: PackedVector2Array) -> float:
	var zone = Rect2(320, 68, 256, 256)
	var grid = 12
	var cell_w = zone.size.x / grid
	var cell_h = zone.size.y / grid
	var covered = {}
	for pt in pts:
		if zone.has_point(pt):
			var cx = int((pt.x - zone.position.x) / cell_w)
			var cy = int((pt.y - zone.position.y) / cell_h)
			covered[Vector2(cx, cy)] = true
	var coverage = float(covered.size()) / float(grid * grid)
	print("[Level3] 网格覆盖度: ", covered.size(), "/", grid*grid, " = ", coverage)
	return coverage

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
