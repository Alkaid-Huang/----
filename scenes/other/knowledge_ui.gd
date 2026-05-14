extends CanvasLayer

@onready var item_list: ItemList = $ContentContainer/CardListPanel/ItemList
@onready var detail_label: RichTextLabel = $ContentContainer/DetailPanel/DetailLabel
@onready var content_container: Control = $ContentContainer

func _ready():
	print("🎨[UI] 知识面板启动...")
	if not item_list or not detail_label:
		push_error("[UI] 节点缺失！请检查场景树")
		return
		
	#  监听全局信号
	item_list.allow_rmb_select = false
	KnowledgeManager.list_refresh_needed.connect(_refresh_list)
	item_list.item_selected.connect(_on_item_selected)
	$ToggleBtn.pressed.connect(toggle)
	content_container.gui_input.connect(_on_content_gui_input)
	
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
		[font_size=26][color=#3d1c00]{title}[/color][/font_size]
		
		[color=#000]{desc}[/color]
		
		[font_size=20][color=#5c2a0a]详细内容[/color][/font_size]
		[color=#000]{content}[/color]
		""".format(card)
		
	print("👁️[UI] 显示详情 -> ", card.title)
	
# 🔘 开关函数（供按钮调用）
func toggle():
	content_container.visible = not content_container.visible
	print("📚 知识卡片UI: ", "打开" if content_container.visible else "关闭")

func close_panel():
	content_container.visible = false
	print("📚 知识卡片UI: 关闭")

func _on_content_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos = event.position
		var card_rect = Rect2($ContentContainer/CardListPanel.position, $ContentContainer/CardListPanel.size)
		var detail_rect = Rect2($ContentContainer/DetailPanel.position, $ContentContainer/DetailPanel.size)
		if not card_rect.has_point(pos) and not detail_rect.has_point(pos):
			close_panel()
