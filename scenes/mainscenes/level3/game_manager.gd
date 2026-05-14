extends Node

const HALF: int = 256
const BG_RED = Color(0.9, 0.1, 0.1, 1)

@export var required_accuracy: float = 0.60
@export var next_level: String = "res://scenes/mainscenes/main3/scene_main_3.tscn"

@onready var canvas = $"../DrawingLayer"
@onready var pivot = $"../PaperGroup"
@onready var target_rect = $"../PaperGroup/TargetQuarter"
@onready var unfold_cont = $"../UnfoldedContainer"
@onready var bar = $"../ValidationUI/ProgressBar"
@onready var lbl = $"../ValidationUI/LabelResult"
@onready var btn_fold = $"../ValidationUI/BtnFold"
@onready var btn_unfold = $"../ValidationUI/BtnUnfold"
@onready var btn_reset = $"../ValidationUI/BtnReset"
@onready var sprite_full = $"../窗花完整"
@onready var sprite_quarter = $"../窗花四分之一"

var img: Image
var quarter_zone: Rect2

var mask_right: ColorRect
var mask_bottom: ColorRect
var red_overlay: ColorRect
var _sfx_click: AudioStreamPlayer

func _play_click():
	_sfx_click.play()

func _create_mask_overlay() -> ColorRect:
	var m = ColorRect.new()
	m.color = BG_RED
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.visible = false
	get_parent().add_child.call_deferred(m)
	return m

func _ready():
	print("[Level3] 窗花关卡初始化, required_accuracy=", required_accuracy, " next_level=", next_level)

	var center = pivot.global_position
	print("[Level3] PaperGroup中心=", center)

	quarter_zone = Rect2(center.x - HALF, center.y - HALF, HALF, HALF)
	print("[Level3] 绘制区域 quarter_zone=", quarter_zone)

	red_overlay = ColorRect.new()
	red_overlay.color = BG_RED
	red_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	red_overlay.offset_left = center.x - HALF
	red_overlay.offset_top = center.y - HALF
	red_overlay.offset_right = center.x + HALF
	red_overlay.offset_bottom = center.y + HALF
	red_overlay.visible = false
	get_parent().add_child.call_deferred(red_overlay)
	print("[Level3] 全尺寸红色遮罩已创建, 覆盖 (", center.x - HALF, ",", center.y - HALF, ")-(", center.x + HALF, ",", center.y + HALF, ")")

	mask_right = _create_mask_overlay()
	mask_right.offset_left = center.x
	mask_right.offset_top = center.y - HALF
	mask_right.offset_right = center.x + HALF
	mask_right.offset_bottom = center.y + HALF
	print("[Level3] 右侧遮罩: (", mask_right.offset_left, ",", mask_right.offset_top, ")-(", mask_right.offset_right, ",", mask_right.offset_bottom, ")")

	mask_bottom = _create_mask_overlay()
	mask_bottom.offset_left = center.x - HALF
	mask_bottom.offset_top = center.y
	mask_bottom.offset_right = center.x + HALF
	mask_bottom.offset_bottom = center.y + HALF
	print("[Level3] 底部遮罩: (", mask_bottom.offset_left, ",", mask_bottom.offset_top, ")-(", mask_bottom.offset_right, ",", mask_bottom.offset_bottom, ")")

	if sprite_quarter.texture:
		img = sprite_quarter.texture.get_image()
		print("[Level3] 四分之一窗花纹理已加载, 尺寸=", img.get_width(), "x", img.get_height())
	else:
		push_error("[Level3] 四分之一窗花纹理未找到!")
		img = null

	var full_size = Vector2(HALF * 2, HALF * 2)
	sprite_full.global_position = center
	if sprite_full.texture:
		var tex_size = sprite_full.texture.get_size()
		sprite_full.scale = full_size / tex_size
		print("[Level3] 完整窗花 tex=", tex_size, " scale=", sprite_full.scale, " pos=", center)
	sprite_full.visible = true
	sprite_quarter.visible = false

	btn_unfold.disabled = true
	lbl.text = "点击【折叠】开始剪裁"

	_sfx_click = AudioStreamPlayer.new()
	_sfx_click.stream = load("res://assets/font/按钮点击.mp3")
	_sfx_click.bus = "SFX"
	add_child(_sfx_click)
	print("[Level3] 音效加载完成")

	var btn_theme = load("res://scenes/mainscenes/level3/button_theme.tres")
	btn_fold.theme = btn_theme
	btn_unfold.theme = btn_theme
	btn_reset.theme = btn_theme
	print("[Level3] 按钮主题已应用")

	var bar_theme = load("res://scenes/mainscenes/level3/progress_bar_theme.tres")
	bar.theme = bar_theme
	print("[Level3] 进度条主题已应用")

	btn_fold.pressed.connect(_on_fold)
	btn_unfold.pressed.connect(_on_unfold)
	btn_reset.pressed.connect(_on_reset)
	print("[Level3] _ready 完成, 完整窗花可见")

func _on_fold():
	_play_click()
	print("[Level3] _on_fold 折叠")
	red_overlay.visible = false
	sprite_full.visible = false
	sprite_quarter.visible = true

	var q_center = quarter_zone.position + quarter_zone.size / 2.0
	sprite_quarter.global_position = q_center
	if sprite_quarter.texture:
		var tex_size = sprite_quarter.texture.get_size()
		sprite_quarter.scale = quarter_zone.size / tex_size
		print("[Level3] 四分之一窗花 tex=", tex_size, " scale=", sprite_quarter.scale, " pos=", q_center)

	mask_right.visible = true
	mask_bottom.visible = true
	canvas.set_zone(quarter_zone)
	canvas.enable()
	btn_fold.disabled = true
	btn_unfold.disabled = false
	lbl.text = "在亮区沿窗花纹样描画"
	print("[Level3] 进入绘制模式, 遮罩已显示, 绘区=", quarter_zone)

func _on_unfold():
	_play_click()
	canvas.disable()
	canvas.set_strokes_visible(false)
	btn_unfold.disabled = true
	lbl.text = "展开验证中..."
	var pts = canvas.get_points()
	print("[Level3] _on_unfold 展开验证, 总点数=", pts.size())
	mask_right.visible = false
	mask_bottom.visible = false
	sprite_quarter.visible = false

	_spawn_symmetry(pts)
	var acc = _validate(pts)
	bar.value = acc * 100
	print("[Level3] 验证重合率=", acc, " 阈值=", required_accuracy)

	if acc >= required_accuracy:
		lbl.text = "窗花完成！精美绝伦！"
		lbl.modulate = Color.GREEN
		print("[Level3] 窗花通关! 跳转: ", next_level)
		GameManager.level3_complete = true
		KnowledgeManager.unlock_by_event("level3_complete")
		await get_tree().create_timer(1.5).timeout
		SceneManager.change_scene(next_level, {"pattern": "fade", "speed": 2.0})
	else:
		lbl.text = "贴合度不足，请调整或重做 (需%d%%)" % int(required_accuracy * 100)
		lbl.modulate = Color.RED
		btn_unfold.disabled = false
		canvas.set_strokes_visible(true)
		sprite_quarter.visible = true
		mask_right.visible = true
		mask_bottom.visible = true
		print("[Level3] 未达标, 恢复绘制模式")

func _on_reset():
	_play_click()
	print("[Level3] _on_reset 重置")
	canvas.clear()
	canvas.disable()
	canvas.set_strokes_visible(true)
	for c in unfold_cont.get_children():
		c.queue_free()
	bar.value = 0
	lbl.text = "点击【折叠】开始剪裁"
	lbl.modulate = Color.WHITE
	btn_fold.disabled = false
	btn_unfold.disabled = true
	mask_right.visible = false
	mask_bottom.visible = false
	red_overlay.visible = false
	sprite_full.visible = true
	sprite_quarter.visible = false
	print("[Level3] 重置完成, 完整窗花可见")

func _spawn_symmetry(pts: PackedVector2Array):
	for c in unfold_cont.get_children():
		c.queue_free()
	if pts.size() < 2:
		print("[Level3] _spawn_symmetry 点数不足(", pts.size(), "), 跳过")
		return
	var center = pivot.global_position
	print("[Level3] _spawn_symmetry 中心点=", center, " 点数=", pts.size())
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
	print("[Level3] _spawn_symmetry 完成, 生成4象限镜像")

func _validate(pts: PackedVector2Array) -> float:
	if pts.size() < 5:
		print("[Level3] _validate 点数太少(", pts.size(), "), 返回0")
		return 0.0
	if img == null:
		print("[Level3] _validate img为空, 返回0")
		return 0.0

	var valid = 0
	var total = 0
	var img_w = img.get_width()
	var img_h = img.get_height()
	var zone_pos = quarter_zone.position
	var zone_size = quarter_zone.size
	var scale_x = zone_size.x / img_w
	var scale_y = zone_size.y / img_h
	print("[Level3] _validate img=", img_w, "x", img_h, " zone=", quarter_zone, " scale=", scale_x, ",", scale_y)

	for pt in pts:
		if not quarter_zone.has_point(pt):
			continue
		total += 1
		var rel_x = pt.x - zone_pos.x
		var rel_y = pt.y - zone_pos.y
		var ix = clampi(int(rel_x / scale_x), 0, img_w - 1)
		var iy = clampi(int(rel_y / scale_y), 0, img_h - 1)
		var c = img.get_pixel(ix, iy)
		if c.a > 0.1:
			valid += 1

	if total == 0:
		print("[Level3] _validate 没有点在绘制区域内")
		return 0.0

	var ratio = float(valid) / float(total)
	print("[Level3] _validate 有效点=", valid, " 区域内总点=", total, " 重合率=", ratio)
	return ratio
