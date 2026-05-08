extends Node

# 📊 游戏进度标记（持久化）
var grass_cut: bool = false
var wood_selected: bool = false
var has_talked_to_npc: bool = false
var level1_complete: bool = false
var level2_complete: bool = false
var level3_complete: bool = false
var has_ability: bool = false  # ✅ 必须添加这一行！


# 🗺️ 场景路径配置（方便修改）
const SCENES := {
	"main_1": "res://scenes/MainScene1.tscn",
	"main_2": "res://scenes/MainScene2.tscn", 
	"main_3": "res://scenes/MainScene3.tscn",
	"level1": "res://scenes/Level1.tscn",
	"level2": "res://scenes/Level2.tscn",
	"level3": "res://scenes/Level3.tscn",
	"end": "res://scenes/GameEnd.tscn"
}

# 🔓 事件 -> 卡片索引 映射（与 KnowledgeManager 对应）
const EVENT_TO_CARD := {
	"grass_cut": 0,
	"level1_complete": 1,
	"level2_complete": 2,
	"level3_complete": 3  # 如果需要第4张卡片
}

func _ready():
	print("🎮 GameManager 初始化完成")

# 🎯 核心函数：解锁卡片 + 跳转场景
func proceed(next_scene_key: String, unlock_event: String = "") -> void:
	print("🔄 流程推进：", next_scene_key, " | 事件：", unlock_event)
	
	# 1. 如果需要解锁知识卡片
	if unlock_event != "" and EVENT_TO_CARD.has(unlock_event):
		var card_index = EVENT_TO_CARD[unlock_event]
		if KnowledgeManager.unlock_card(card_index):
			print("🎉 解锁知识卡片 #", card_index)
			# 等待1秒让玩家看到提示（可选）
			await get_tree().create_timer(1.0).timeout
	
	# 2. 跳转场景
	if SCENES.has(next_scene_key):
		print("🚀 跳转到：", SCENES[next_scene_key])
		get_tree().change_scene_to_file(SCENES[next_scene_key])
	else:
		push_error("❌ 未找到场景键：", next_scene_key)

# 📝 进度保存/加载（可选扩展）
func save_progress():
	var data = {
		"grass_cut": grass_cut,
		"wood_selected": wood_selected,
		"level1_complete": level1_complete,
		"level2_complete": level2_complete,
		"level3_complete": level3_complete
	}
	var file = FileAccess.open("user://game_progress.dat", FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()

func load_progress():
	if FileAccess.file_exists("user://game_progress.dat"):
		var file = FileAccess.open("user://game_progress.dat", FileAccess.READ)
		if file:
			var data = file.get_var()
			file.close()
			if data is Dictionary:
				grass_cut = data.get("grass_cut", false)
				wood_selected = data.get("wood_selected", false)
				level1_complete = data.get("level1_complete", false)
				level2_complete = data.get("level2_complete", false)
				level3_complete = data.get("level3_complete", false)
				print("📂 游戏进度已加载")
