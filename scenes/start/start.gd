extends Control

@onready var prologue_label: RichTextLabel = $ProloguePanel/PrologueLabel
@onready var title_container: CenterContainer = $TitleContainer
@onready var menu_container: VBoxContainer = $MenuContainer
@onready var title_label: Label = $TitleContainer/Title
@onready var subtitle_label: Label = $TitleContainer/Subtitle

var _prologue_lines: Array[String] = [
	"七年后，陈远再次回到了青石镇。",
	"父亲在电话里说：「老宅快塌了，你回去看看。」",
	"陈远本来不想来。",
	"但昨晚梦见了祖父。",
	"梦里的祖父坐在院子里，",
	"手里拿着一块刨光的木头，",
	"抬头对他笑了笑。",
	"陈远醒了之后，订了最早的车票。"
]
var _line_index: int = 0
var _prologue_done: bool = false

func _ready():
	print("[StartScreen] 启动界面加载完成")
	prologue_label.text = ""
	_show_next_line()

func _show_next_line():
	if _line_index >= _prologue_lines.size():
		_on_prologue_finished()
		return
	prologue_label.modulate = Color(1, 1, 1, 0)
	prologue_label.text = "[center][color=#d4c5a9]" + _prologue_lines[_line_index] + "[/color][/center]"
	var tween = create_tween()
	tween.tween_property(prologue_label, "modulate", Color(1, 1, 1, 1), 1.0)
	_line_index += 1

func _on_prologue_finished():
	_prologue_done = true
	prologue_label.text = "[center][color=#d4c5a9]— 点击开始游戏 —[/color][/center]"
	prologue_label.modulate = Color(1, 1, 1, 1)

func _on_prologue_click():
	if _prologue_done:
		_show_menu()
	else:
		_show_next_line()

func _show_menu():
	var tween = create_tween()
	tween.tween_property(prologue_label, "modulate", Color(1, 1, 1, 0), 0.5)
	await tween.finished
	prologue_label.visible = false
	title_container.visible = true
	menu_container.visible = true
	title_container.modulate = Color(1, 1, 1, 0)
	menu_container.modulate = Color(1, 1, 1, 0)
	var t2 = create_tween()
	t2.tween_property(title_container, "modulate", Color(1, 1, 1, 1), 0.8)
	t2.parallel().tween_property(menu_container, "modulate", Color(1, 1, 1, 1), 0.8)
	subtitle_label.text = "— 中式古建筑修缮之旅 —"
	print("[StartScreen] 菜单已显示")

func _input(event):
	var triggered = event.is_action_pressed("interact") or (event is InputEventMouseButton and event.pressed)
	if not triggered:
		return
	if _prologue_done:
		_show_menu()
	else:
		_on_prologue_click()

func _on_start_pressed():
	print("[StartScreen] 开始游戏 → 主场景1")
	SceneManager.change_scene("res://scenes/mainscenes/main1/scene_main_1.tscn", {"pattern": "fade", "speed": 1.5})

func _on_quit_pressed():
	print("[StartScreen] 退出游戏")
	get_tree().quit()
