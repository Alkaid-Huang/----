extends CanvasLayer

@onready var item_list: ItemList = $ItemList
@onready var detail_label: RichTextLabel = $DetailLabel

func _ready():
		# ✅ 默认隐藏
	visible = false
	print("🎨[UI] 知识面板启动...")
	if not item_list or not detail_label:
		push_error("[UI] 节点缺失！请检查场景树")
		return
		
	#  监听全局信号
	KnowledgeManager.list_refresh_needed.connect(_refresh_list)
	item_list.item_selected.connect(_on_item_selected)
	
	_refresh_list()
	
	# 默认选中第一项（如果已解锁）
	if item_list.get_item_count() > 0 and not item_list.is_item_disabled(0):
		item_list.select(0)
		_show_detail(0)
	else:
		detail_label.text = "[center][color=#888]请选择左侧卡片查看[/color][/center]"
	
	print("🎨[UI] 面板就绪")

func _refresh_list():
	print("🔄[UI] 开始刷新列表...")
	item_list.clear()
	
	for i in range(KnowledgeManager.CARD_DATA.size()):
		var card = KnowledgeManager.CARD_DATA[i]
		item_list.add_item(card.title)
		
		if not KnowledgeManager.is_unlocked(i):
			item_list.set_item_text(i, "???")
			item_list.set_item_disabled(i, true)
			print("   🔒 第", i, "项：未解锁")
		else:
			item_list.set_item_disabled(i, false)
			print("   🔓 第", i, "项：已解锁")
			
	print("✅[UI] 列表刷新完成，共 ", item_list.get_item_count(), " 项")

func _on_item_selected(index):
	_show_detail(index)

func _show_detail(index):
	if index < 0 or index >= KnowledgeManager.CARD_DATA.size(): return
	var card = KnowledgeManager.CARD_DATA[index]
	
	detail_label.text = """
		[font_size=26][color=#4299e1]{title}[/color][/font_size]
		[font_size=14][color=#a0aec0]【{tag}】| 📅 {date} | ⭐ {level}[/color][/font_size]
		
		[h1]简介[/h1]
		{desc}
		
		[h1]详细内容[/h1]
		{content}
		""".format(card)
		
	print("👁️[UI] 显示详情 -> ", card.title)
	
# 🔘 开关函数（供按钮调用）
func toggle():
	visible = !visible
	#get_tree().paused = visible  # 打开时暂停游戏，关闭时恢复
	print("📚 知识卡片UI: ", "打开" if visible else "关闭")
