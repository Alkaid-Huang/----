extends Node

@export var return_scene_path: String = "res://scenes/mainscenes/scene_main_2.tscn"

func _ready():
	print("🏆[Level2] 关卡加载")

func on_level_complete():
	print("🏆[Level2] ========== 通关结算 ==========")
	
	# 更新状态
	GameManager.level2_complete = true
	print("✅ [Level2] level2_complete = true")
	
	# 解锁知识
	if KnowledgeManager:
		KnowledgeManager.unlock_by_event("level2_complete")
	
	# 返回
	print("🚀 [Level2] 返回工坊")
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file(return_scene_path)
