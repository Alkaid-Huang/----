extends Control

func _ready():
	print("🧪[测试] 知识UI测试场景启动（不会自动解锁卡片）")
	print("   当前存档状态: ", KnowledgeManager.unlocked_status)
	await get_tree().process_frame
	$KnowledgeUI.content_container.visible = true
	$KnowledgeUI._refresh_list()

func _input(event):
	if event is InputEventKey and event.keycode == KEY_TAB and event.pressed:
		$KnowledgeUI.toggle()
	if event is InputEventKey and event.keycode == KEY_R and event.pressed:
		print("🧪[测试] 手动重置所有卡片")
		KnowledgeManager.reset_all()
		$KnowledgeUI._refresh_list()
