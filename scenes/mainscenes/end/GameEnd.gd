extends Control

@onready var black_screen: ColorRect = $BlackScreen
@onready var black_text_label: RichTextLabel = $BlackScreen/BlackVBox/BlackTextLabel
@onready var big_quote_label: Label = $BlackScreen/BlackVBox/BigQuoteLabel
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var content_label: RichTextLabel = $Panel/VBox/ContentLabel
@onready var buttons: HBoxContainer = $Panel/VBox/Buttons

var black_lines: Array[String] = [
	"我给父亲打了电话。我说，老宅不卖了。",
	"电话那头沉默了很久，然后父亲说：「好。」",
	"",
	"后来，陈远每个假期都回青石镇。",
	"他跟林师傅学了大木作，跟陈伯学了小木作。",
	"大三那年，他带着同学把青石镇的古建筑做了完整的测绘记录。",
	"毕业设计，他做的是一份《华北地区传统民居修缮导则》。",
	"",
	"答辩那天，他在致谢里写道：",
	"「谨以此文献给我的祖父陈怀瑾，",
	"以及所有守护着中国乡土建筑的无名匠人。」",
]

var _line_index: int = 0

func _ready():
	print("[GameEnd] 结局场景加载")
	black_text_label.text = ""
	big_quote_label.text = ""
	big_quote_label.modulate = Color(1, 1, 1, 0)
	panel.visible = false
	buttons.modulate = Color(1, 1, 1, 0)
	buttons.visible = false
	_start_black_screen()

func _start_black_screen():
	print("[GameEnd] 黑屏报幕开始")
	black_screen.visible = true
	_line_index = 0
	await get_tree().create_timer(1.5).timeout
	_type_black_line()

func _type_black_line():
	if _line_index >= black_lines.size():
		_show_big_quote()
		return
	var line = black_lines[_line_index]
	if line == "":
		black_text_label.append_text("\n")
		_line_index += 1
		await get_tree().create_timer(0.5).timeout
		_type_black_line()
		return
	var full = ""
	for ch in line:
		full += ch
		black_text_label.parse_bbcode(full)
		await get_tree().create_timer(0.04).timeout
	_line_index += 1
	await get_tree().create_timer(0.8).timeout
	_type_black_line()

func _show_big_quote():
	print("[GameEnd] 显示大字结语")
	await get_tree().create_timer(1.0).timeout
	big_quote_label.text = "房子会老，但手艺不会。\n人走了，宅子还在，根就还在。"
	var tween = create_tween()
	tween.tween_property(big_quote_label, "modulate", Color(1, 1, 1, 1), 2.0)
	tween.tween_callback(_show_buttons)

func _show_buttons():
	await get_tree().create_timer(2.0).timeout
	panel.visible = true
	title_label.text = "归园筑梦"
	title_label.modulate = Color(1, 1, 1, 1)
	content_label.text = ""
	buttons.visible = true
	var tween = create_tween()
	tween.tween_property(buttons, "modulate", Color(1, 1, 1, 1), 1.0)
	print("[GameEnd] 结局文字展示完毕")

func _on_restart():
	print("[GameEnd] 重新开始")
	GameManager.grass_cut = false
	GameManager.has_ability = false
	GameManager.has_talked_to_npc = false
	GameManager.wood_selected = false
	GameManager.level1_complete = false
	GameManager.level2_complete = false
	GameManager.level3_complete = false
	KnowledgeManager.reset_all()
	SceneManager.change_scene("res://scenes/start/start.tscn", {"pattern": "fade", "speed": 1.5})

func _on_quit():
	print("[GameEnd] 退出游戏")
	get_tree().quit()
