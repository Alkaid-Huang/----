extends Control

func _ready():
	for i in range(KnowledgeManager.CARD_DATA.size()):
		KnowledgeManager.unlocked_status[i] = true
	await get_tree().process_frame
	$KnowledgeUI.content_container.visible = true
	$KnowledgeUI._refresh_list()

func _input(event):
	if event is InputEventKey and event.keycode == KEY_TAB and event.pressed:
		$KnowledgeUI.toggle()
