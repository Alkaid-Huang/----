class_name NodeStateMachine
extends Node

@export var initial_node_state : NodeState

var node_states : Dictionary = {}
var current_node_state : NodeState
var current_node_state_name : String

func _ready() -> void:
	for child in get_children():
		if child is NodeState:
			node_states[child.name.to_lower()] = child
			child.transition.connect(transition_to)
	
	if initial_node_state:
		initial_node_state._on_enter()
		current_node_state = initial_node_state


func _process(delta : float) -> void:
	if current_node_state:
		current_node_state._on_process(delta)


func _physics_process(delta: float) -> void:
	if current_node_state:
		current_node_state._on_physics_process(delta)
		current_node_state._on_next_transitions()


func transition_to(node_state_name : String) -> void:
	if node_state_name == current_node_state.name.to_lower():
		return
	
	var new_node_state = node_states.get(node_state_name.to_lower())
	
	if !new_node_state:
		return
	
	if current_node_state:
		current_node_state._on_exit()
	
	new_node_state._on_enter()
	
	current_node_state = new_node_state
	current_node_state_name = current_node_state.name.to_lower()
	print("Current State: ", current_node_state_name)


# 🆕 添加这两个方法，不要用 enabled 变量
func pause_on() -> void:
	# 0 = PROCESS_MODE_INHERIT (继承父节点)
	# 1 = PROCESS_MODE_PAUSED (当游戏暂停时处理) 不适用
	# 2 = PROCESS_MODE_ALWAYS (始终处理)
	# 3 = PROCESS_MODE_DISABLED (从不处理)
	process_mode = Node.PROCESS_MODE_DISABLED

func pause_off() -> void:
	# 恢复为继承父节点
	process_mode = Node.PROCESS_MODE_INHERIT
