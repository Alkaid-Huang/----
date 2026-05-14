extends Control

@onready var start_menu: VBoxContainer = $StartMenuContainer
@onready var prologue_overlay: ColorRect = $PrologueOverlay
@onready var prologue_panel: Panel = $ProloguePanel
@onready var prologue_label: RichTextLabel = $ProloguePanel/PrologueLabel
@onready var bgm_slider: HSlider = $AudioSettings/AudioPanel/AudioVBox/BgmRow/BgmSlider
@onready var sfx_slider: HSlider = $AudioSettings/AudioPanel/AudioVBox/SfxRow/SfxSlider
@onready var audio_settings: Control = $AudioSettings
@onready var settings_btn: TextureButton = $SettingsBtn

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
var _in_prologue: bool = false

func _ready():
	print("[StartScreen] 启动界面加载完成")
	_load_audio_settings()
	bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	settings_btn.pressed.connect(_on_settings_toggled)

func _load_audio_settings():
	var music_idx = AudioServer.get_bus_index("Music")
	var sfx_idx = AudioServer.get_bus_index("SFX")
	bgm_slider.value = AudioServer.get_bus_volume_db(music_idx)
	sfx_slider.value = AudioServer.get_bus_volume_db(sfx_idx)

func _on_bgm_volume_changed(value: float):
	var idx = AudioServer.get_bus_index("Music")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, value)

func _on_sfx_volume_changed(value: float):
	var idx = AudioServer.get_bus_index("SFX")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, value)

func _on_settings_toggled():
	audio_settings.visible = not audio_settings.visible

func _on_start_pressed():
	if _in_prologue:
		return
	_start_prologue()

func _start_prologue():
	_in_prologue = true
	audio_settings.visible = false
	var tween = create_tween()
	tween.tween_property(start_menu, "modulate", Color(1, 1, 1, 0), 0.5)
	await tween.finished
	start_menu.visible = false
	settings_btn.visible = false
	prologue_overlay.visible = true
	prologue_panel.visible = true
	prologue_label.text = ""
	_line_index = 0
	_prologue_done = false
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
	prologue_label.text = "[center][color=#d4c5a9]— 点击进入游戏 —[/color][/center]"
	prologue_label.modulate = Color(1, 1, 1, 1)

func _input(event):
	if not _in_prologue:
		return
	var triggered = event.is_action_pressed("interact") or (event is InputEventMouseButton and event.pressed)
	if not triggered:
		return
	if _prologue_done:
		_enter_game()
	else:
		_show_next_line()

func _enter_game():
	print("[StartScreen] 序言结束 → 进入主场景")
	SceneManager.change_scene("res://scenes/mainscenes/main1/scene_main_1.tscn", {"pattern": "fade", "speed": 1.5})
