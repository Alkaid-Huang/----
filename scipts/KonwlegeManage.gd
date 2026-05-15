extends Node
signal card_unlocked(index)
signal list_refresh_needed

# 知识数据（只读常量）
const CARD_DATA := [
	{"id": 0, "tag": "榫卯工艺", "title": "榫卯起源", "desc": "中国传统榫卯结构最早可追溯至河姆渡文化时期，是木构建筑的精髓。", "content": "榫卯是中国传统建筑、家具及其他器械的主要结构方式，是在两个构件上采用凹凸部位相结合的一种连接方式。凸出部分叫榫（或榫头）；凹进部分叫卯（或榫眼、榫槽）。其特点是在物件上不使用钉子，利用卯榫加固物件，体现出中国古老的文化和智慧。", "date": "2025-01-10", "level": "基础"},
	{"id": 1, "tag": "梁架结构", "title": "斗拱技艺", "desc": "斗拱是中国传统建筑中独特的构件，兼具结构与装饰功能。", "content": "斗拱是由斗形木块和弓形肘木相互穿插、层层叠加而成的构件。它位于立柱和横梁交接处，起到支撑挑檐、传递荷载的作用，同时具有极强的抗震性能。斗拱结构复杂、造型优美，是中国古代建筑艺术的杰出代表。", "date": "2025-01-12", "level": "核心"},
	{"id": 2, "tag": "剪纸艺术", "title": "窗花工艺", "desc": "窗花是中国传统剪纸艺术的一种，多用于春节装饰。", "content": "窗花是有各种颜色、各种图案的民间剪纸艺术品。这种民间风俗已有上千年的历史。山西民间的剪纸，尤其是窗花剪纸充满乡土气息，其风格淳朴、粗犷、色彩鲜明。窗花不仅烘托了喜庆的节日气氛，还能为人们带来美的享受做到集装饰性、欣赏性和实用性于一体。", "date": "2025-01-15", "level": "基础"},
	{"id": 3, "tag": "古建修复", "title": "修缮之道", "desc": "传统建筑修复遵循'不改变文物原状'的原则，力求修旧如旧。", "content": "古建修复是一项综合性的工作，需要对历史建筑进行科学的勘察、研究、设计和施工。修复过程中要尊重历史原貌，尽可能使用传统材料和工艺，同时运用现代科技手段确保修复质量。每一次修缮都是对历史的致敬，也是对文化的传承。", "date": "2025-01-18", "level": "核心"}
]

# 解锁状态（运行时变量）
var unlocked_status := []
const SAVE_PATH = "user://knowledge_save.dat"

func _ready():
	print("📘[管理器] 正在初始化...")
	_load_data()
	_ensure_status_array()

	reset_all()
	print("🔄[管理器] 强制重置存档（调试用，确认正常后请删除此行）")

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
				if data.size() != CARD_DATA.size():
					print("⚠️[管理器] 存档数量(", data.size(), ")与卡片数量(", CARD_DATA.size(), ")不匹配，重置存档")
					_ensure_status_array()
				else:
					unlocked_status = data
					print("📂[管理器] 读取成功！状态: ", unlocked_status)
			else:
				print("🔴[管理器] 读取失败：存档格式错误，重置")
				_ensure_status_array()
		else:
			print("🔴[管理器] 读取失败：文件损坏，重置")
			_ensure_status_array()
	else:
		print("📂[管理器] 未找到存档，使用初始状态")
		_ensure_status_array()
		
# 事件名 -> 卡片索引 映射表
const EVENT_TO_CARD := {
	"grass_cut": 0,          # 拔草事件解锁第0张
	"level1_complete": 1,    # 通关第一关解锁第1张
	"level2_complete": 2,    # 通关第二关解锁第2张
	"level3_complete": 3     # 通关第三关解锁第3张
}

func unlock_by_event(event_name: String) -> void:
	print("📩[管理器] 收到解锁事件: ", event_name)
	print("   当前状态: ", unlocked_status)

	if not EVENT_TO_CARD.has(event_name):
		print("⚠️[管理器] 未绑定该事件 [", event_name, "]，忽略")
		return

	var card_index = EVENT_TO_CARD[event_name]
	print("   映射到卡片索引: ", card_index, " (", CARD_DATA[card_index].title, ")")

	if is_unlocked(card_index):
		print("⚠️[管理器] 卡片 [", card_index, "] 已解锁，跳过")
		return

	unlocked_status[card_index] = true
	_save_data()

	var card_title = CARD_DATA[card_index].title
	print("🎉[管理器] 解锁成功 -> ", card_title)
	print("   更新后状态: ", unlocked_status)
	card_unlocked.emit(card_index)
	list_refresh_needed.emit()

func reset_all():
	unlocked_status = []
	for i in range(CARD_DATA.size()):
		unlocked_status.append(false)
	_save_data()
	list_refresh_needed.emit()
	print("📘[管理器] 知识卡片已全部重置")
