extends Node
class_name WeedGroupManager

@export var trigger_ref: NodePath

var _total: int = 0
var _cleared: int = 0

func _ready():
	var children = get_children()
	_total = children.size()
	print("[WeedGroup] 共 ", _total, " 处杂草")

	for child in children:
		if child is WeedArea:
			child.cleared.connect(_on_weed_cleared)

func _on_weed_cleared():
	_cleared += 1
	print("[WeedGroup] 清理进度：", _cleared, "/", _total)

	if _cleared >= _total:
		print("[WeedGroup] 所有杂草已清理！")
		GameManager.grass_cut = true

		var trigger = get_node_or_null(trigger_ref)
		if trigger and trigger.has_method("refresh_state"):
			trigger.refresh_state()
