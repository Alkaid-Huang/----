extends Node2D

var balloon_scene = preload("res://dialogue/game_dialogue_balloon.tscn")
var dialogue_beam_success: DialogueResource

var _image_shown: bool = false

func _ready():
	print("[Main2] 主场景2加载完成, level2_complete=", GameManager.level2_complete)
	dialogue_beam_success = load("res://dialogue/conversations/act3_beam_success.dialogue") as DialogueResource
	if GameManager.level2_complete and not _image_shown:
		_image_shown = true
		_show_beam_success_image()

func _show_beam_success_image():
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "ImageLayer"
	canvas_layer.layer = 100
	add_child(canvas_layer)

	var bg = TextureRect.new()
	bg.name = "BeamImage"
	bg.texture = load("res://assets/上梁大吉.jpg")
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas_layer.add_child(bg)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	var fade = ColorRect.new()
	fade.name = "ImageFade"
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas_layer.add_child(fade)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)

	var text_vbox = VBoxContainer.new()
	text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	canvas_layer.add_child(text_vbox)
	text_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_vbox.add_child(spacer)

	var text_label = RichTextLabel.new()
	text_label.custom_minimum_size = Vector2(700, 180)
	text_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.scroll_active = false
	text_label.add_theme_color_override("default_color", Color(0, 0, 0, 1))
	text_label.add_theme_font_size_override("normal_font_size", 22)
	text_vbox.add_child(text_label)

	var spacer2 = Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_vbox.add_child(spacer2)

	text_label.modulate = Color(1, 1, 1, 0)

	await get_tree().create_timer(3.0).timeout

	var tween = create_tween()
	tween.tween_property(text_label, "modulate", Color(1, 1, 1, 1), 1.0)
	tween.tween_callback(_type_image_lines.bind(text_label, canvas_layer))

func _type_image_lines(label: RichTextLabel, canvas_layer: CanvasLayer):
	var lines: Array[String] = [
		"「好！梁上正了！你爷爷要是看到，应该会高兴的。」",
		"",
		"「这座宅子，总算又有脊梁了。」",
		"",
		"「爷爷，你看到了吗……」",
	]
	var built: String = ""
	var idx = 0
	while idx < lines.size():
		var line = lines[idx]
		if line == "":
			built += "\n"
			label.parse_bbcode("[center]" + built + "[/center]")
			idx += 1
			await get_tree().create_timer(0.3).timeout
			continue
		var partial = ""
		for ch in line:
			partial += ch
			label.parse_bbcode("[center]" + built + partial + "[/center]")
			await get_tree().create_timer(0.04).timeout
		built += line + "\n"
		idx += 1
		await get_tree().create_timer(0.8).timeout

	await get_tree().create_timer(1.0).timeout
	_fade_image_out(canvas_layer)

func _fade_image_out(canvas_layer: CanvasLayer):
	print("[Main2] 上梁图片暗淡")
	var fade = canvas_layer.get_node("ImageFade")
	var text_label = canvas_layer.get_node("VBoxContainer/RichTextLabel") if canvas_layer.has_node("VBoxContainer/RichTextLabel") else null
	var tween = create_tween()
	tween.tween_property(fade, "color", Color(0, 0, 0, 1), 2.0)
	if text_label:
		tween.parallel().tween_property(text_label, "modulate", Color(1, 1, 1, 0), 1.5)
	tween.tween_callback(canvas_layer.queue_free)
