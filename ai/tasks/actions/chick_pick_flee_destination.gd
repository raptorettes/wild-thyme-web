extends BTAction

@export var flee_distance: float = 55.0

func _tick(_delta: float) -> int:
	var chicken = agent  # use agent, not scene_root

	var player = chicken.get_tree().get_first_node_in_group("player")
	if player == null:
		return SUCCESS

	var mouse_pos = player.world_mouse_pos
	var flee_dir = (chicken.global_position - mouse_pos).normalized()
	var target = chicken.global_position + flee_dir * flee_distance

	chicken.nav_agent.target_position = target
	return SUCCESS
