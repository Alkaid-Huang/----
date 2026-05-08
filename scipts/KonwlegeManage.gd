extends Node
signal card_unlocked(index)
signal list_refresh_needed

# 知识数据（只读常量）
const CARD_DATA := [
	{"id": 0, "tag": "剪纸历史", "title": "剪纸起源", "desc": "中国剪纸最早可追溯至汉代...", "content": "详细内容...", "date": "2025-01-10", "level": "基础"},
	{"id": 1, "tag": "工艺原理", "title": "折叠对称", "desc": "传统窗花利用轴对称原理...", "content": "详细内容...", "date": "2025-01-12", "level": "核心"},
	{"id": 2, "tag": "文化寓意", "title": "红色寓意", "desc": "窗花多用红纸，象征喜庆...", "content": "详细内容...", "date": "2025-01-15", "level": "基础"}
]

# 解锁状态（运行时变量）
var unlocked_status := []
const SAVE_PATH = "user://knowledge_save.dat"

func _ready():
	print("📘[管理器] 正在初始化...")
	_load_data()
	_ensure_status_array()
	print("📘[管理器] 初始化完成！共 ", CARD_DATA.size(), " 张卡片")
	print("📘[管理器] 当前解锁状态: ", unlocked_status)

func _ensure_status_array():
	# 确保状态数组长度与数据一致
	if unlocked_status.size() != CARD_DATA.size():
		print("📘[管理器] 状态数组长度不匹配，重置为全未解锁")
		# ========== 这里修复了！Godot 3 可用 ==========
		unlocked_status = []
		for i in range(CARD_DATA.size()):
			unlocked_status.append(false)
		# ===========================================
	else:
		print("📘[管理器] 状态数组长度正常")

func unlock_card(index: int) -> bool:
	print("📘[管理器] 收到解锁请求 -> 索引: ", index)
	
	if index < 0 or index >= CARD_DATA.size():
		print("🔴[管理器] 错误：索引越界！")
		return false
		
	if unlocked_status[index]:
		print("⚠️[管理器] 提示：卡片 '", CARD_DATA[index].title, "' 已解锁过")
		return false
		
	# ✅ 执行解锁
	unlocked_status[index] = true
	print("[管理器] 解锁成功 -> ", CARD_DATA[index].title)
	
	_save_data()
	card_unlocked.emit(index)
	list_refresh_needed.emit()
	return true

func is_unlocked(index: int) -> bool:
	return unlocked_status[index] if index >= 0 and index < unlocked_status.size() else false

func _save_data():
	print("📘[管理器] 正在保存数据到: ", SAVE_PATH)
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(unlocked_status)
		file.close()
		print("💾[管理器] 保存成功")
	else:
		print("🔴[管理器] 保存失败！无法创建文件")

func _load_data():
	print("📘[管理器] 正在读取存档: ", SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var data = file.get_var()
			file.close()
			if data is Array:
				unlocked_status = data
				print("📂[管理器] 读取成功！状态: ", unlocked_status)
			else:
				print("🔴[管理器] 读取失败：存档格式错误")
		else:
			print("🔴[管理器] 读取失败：文件损坏")
	else:
		print("📂[管理器] 未找到存档，使用初始状态")
		
# 事件名 -> 卡片索引 映射表
const EVENT_TO_CARD := {
	"grass_cut": 0,          # 拔草事件解锁第0张
	"level1_clear": 1,       # 通关第一关解锁第1张
	"meet_npc_elder": 2      # 遇见NPC老人解锁第2张
}

func unlock_by_event(event_name: String) -> void:
	print("📩[管理器] 收到事件: ", event_name)
	
	if not EVENT_TO_CARD.has(event_name):
		print("⚠️[管理器] 未绑定该事件，忽略")
		return
		
	var card_index = EVENT_TO_CARD[event_name]
	if is_unlocked(card_index):
		print("⚠️[管理器] 卡片 ", card_index, " 已解锁，跳过")
		return
		
	# 执行解锁
	unlocked_status[card_index] = true
	_save_data()
	
	var card_title = CARD_DATA[card_index].title
	print("🎉[管理器] 解锁成功 -> ", card_title)
	card_unlocked.emit(card_index)
	list_refresh_needed.emit()
