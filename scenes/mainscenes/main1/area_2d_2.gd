extends Area2D

var is_cleared: bool = false
var player_nearby: bool = false

func _ready():
	print("🌱 [Weed] 初始化：", name)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		print("🟢 [Weed] 玩家进入：", name)
		player_nearby = true

func _on_body_exited(body):
	if body.name == "Player" or body.is_in_group("player"):
		print("🔴 [Weed] 玩家离开：", name)
		player_nearby = false

func _unhandled_input(event):
	# 🔍 调试：打印所有输入事件
	if event.is_action_pressed("interact"):
		print("⌨️ [Weed] 收到 F 键！name=", name, " player_nearby=", player_nearby)
		
		if not player_nearby:
			print("⚠️ 玩家不在范围内，跳过")
			return
		
		# 🔒 能力检查
		if GameManager and not GameManager.get("has_ability"):
			print("⚠️ 还没获得能力")
			return
		
		# ✅ 执行清理
		_do_clear()

func _do_clear():
	if is_cleared:
		print("⚠️ 已清理过")
		return
		
	is_cleared = true
	print("✅ [Weed] 清理成功：", name)
	visible = false
	set_process(false)
	set_physics_process(false)
