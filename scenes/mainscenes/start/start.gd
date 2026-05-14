extends Control

@onready var start_menu: VBoxContainer = $StartMenuContainer
@onready var prologue_image: TextureRect = $PrologueImage
@onready var image_fade: ColorRect = $PrologueImage/ImageFade
@onready var image_text_label: RichTextLabel = $PrologueImage/ImageTextVBox/ImageTextLabel
@onready var prologue_overlay: ColorRect = $PrologueOverlay
@onready var prologue_panel: Panel = $ProloguePanel
@onready var prologue_label: RichTextLabel = $ProloguePanel/PrologueLabel
@onready var bgm_slider: HSlider = $AudioSettings/AudioPanel/AudioVBox/BgmRow/BgmSlider
@onready var sfx_slider: HSlider = $AudioSettings/AudioPanel/AudioVBox/SfxRow/SfxSlider
@onready var audio_settings: Control = $AudioSettings
@onready var settings_btn: TextureButton = $SettingsBtn

var _image_lines: Array[String] = [
	"七年后，陈远再次回到了青石镇。",
	"父亲在电话里说：「老宅快塌了，你回去看看。」",
	"陈远本来不想来。但昨晚梦见了祖父。",
	"梦里的祖父坐在院子里，手里拿着一块刨光的木头，抬头对他笑了笑。",
	"陈远醒了之后，订了最早的车票。",
]

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
var _in_image_phase: bool = false
var _image_phase_done: bool = false

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
	if _in_prologue or _in_image_phase:
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
	prologue_overlay.visible = false
	prologue_panel.visible = false
	_start_image_phase()

func _start_image_phase():
	_in_image_phase = true
	prologue_image.visible = true
	image_text_label.text = ""
	image_text_label.modulate = Color(1, 1, 1, 0)
	_line_index = 0
	await get_tree().create_timer(2.0).timeout
	var tween = create_tween()
	tween.tween_property(image_text_label, "modulate", Color(1, 1, 1, 1), 1.0)
	tween.tween_callback(_type_image_line)

func _type_image_line():
	if _line_index >= _image_lines.size():
		_fade_image_out()
		return
	var line = _image_lines[_line_index]
	if line == "":
		image_text_label.append_text("\n")
		_line_index += 1
		await get_tree().create_timer(0.3).timeout
		_type_image_line()
		return
	var full = ""
	for ch in line:
		full += ch
		image_text_label.parse_bbcode(full)
		await get_tree().create_timer(0.04).timeout
	_line_index += 1
	await get_tree().create_timer(0.8).timeout
	_type_image_line()

func _fade_image_out():
	print("[StartScreen] 图片暗淡，准备进入游戏")
	_image_phase_done = true
	var tween = create_tween()
	tween.tween_property(image_fade, "color", Color(0, 0, 0, 1), 2.0)
	tween.parallel().tween_property(image_text_label, "modulate", Color(1, 1, 1, 0), 1.5)
	tween.tween_callback(_show_enter_prompt)

func _show_enter_prompt():
	_in_image_phase = false
	prologue_image.visible = false
	prologue_overlay.visible = true
	prologue_panel.visible = true
	prologue_label.text = "[center][color=#d4c5a9]— 点击进入游戏 —[/color][/center]"
	prologue_label.modulate = Color(1, 1, 1, 1)
	_prologue_done = true
	_in_prologue = true

func _input(event):
	if not _in_prologue and not _in_image_phase:
		return
	var triggered = event.is_action_pressed("interact") or (event is InputEventMouseButton and event.pressed)
	if not triggered:
		return
	if _in_image_phase:
		if not _image_phase_done:
			_fade_image_out()
		return
	if _prologue_done:
		_enter_game()
	else:
		_show_next_line()

func _enter_game():
	print("[StartScreen] 序言结束 → 进入主场景")
	SceneManager.change_scene("res://scenes/mainscenes/main1/scene_main_1.tscn", {"pattern": "fade", "speed": 1.5})
