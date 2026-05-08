extends Node
class_name WeedGroupManager

@export var trigger_ref: NodePath

var last_check_count: int = 0

func _ready():
	print("📦 [WeedGroupManager] 初始化...")
	print("  - 子节点数量：", get_child_count())
	print("  - trigger_ref: ", trigger_ref)
	
	for child in get_children():
		print("  - 子节点：", child.name, " (类型：", child.get_class(), ")")

func _process(_delta):
	# 已清理则停止检测
	if GameManager.grass_cut:
		print("✅ [WeedGroupManager] GameManager.grass_cut 已为 true，停止检测")
		set_process(false)
		return
	
	# 每 0.5 秒检测一次（避免每帧检测）
	if Engine.get_frames_drawn() % 30 != 0:
		return
		
	var all_cleared = true
	var cleared_count = 0
	var total_count = 0
	
	print("🔍 [WeedGroupManager] 开始检测杂草状态...")
	
	for child in get_children():
		total_count += 1
		var is_cleared = child.get("is_cleared")
		
		if is_cleared:
			cleared_count += 1
		else:
			all_cleared = false
			print("  - ", child.name, ": 未清理")
	
	print("📊 [WeedGroupManager] 清理进度：", cleared_count, "/", total_count)
	
	if all_cleared and total_count > 0:
		print("✅ [WeedGroupManager] 所有杂草已清理！")
		GameManager.grass_cut = true
		print("  - GameManager.grass_cut = true")
		
		var trigger = get_node_or_null(trigger_ref)
		if trigger and trigger.has_method("refresh_state"):
			print("🔔 [WeedGroupManager] 通知触发器刷新状态")
			trigger.refresh_state()
		else:
			print("⚠️ [WeedGroupManager] 触发器未找到或没有 refresh_state 方法")
			print("  - trigger: ", trigger)
	else:
		print("⏳ [WeedGroupManager] 还有杂草未清理")
