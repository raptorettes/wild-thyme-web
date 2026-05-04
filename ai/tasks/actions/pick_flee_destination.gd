extends BTAction

@export var flee_distance: float = 35.0

func _tick(_delta: float) -> int:
	var cow = agent  # use agent, not scene_root

	var player = cow.get_tree().get_first_node_in_group("player")
	if player == null:
		return SUCCESS

	var mouse_pos = player.world_mouse_pos
	var flee_dir = (cow.global_position - mouse_pos).normalized()
	var target = cow.global_position + flee_dir * flee_distance

	cow.nav_agent.target_position = target
	return SUCCESS
