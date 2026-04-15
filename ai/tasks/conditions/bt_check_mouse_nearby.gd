extends BTCondition

func _tick(_delta: float) -> int:
	var cow = scene_root
	if cow.get("player_flee_radius") == null:
		return FAILURE
	var player = cow.get_tree().get_first_node_in_group("player")
	if player == null:
		return FAILURE
	var mouse_pos = player.world_mouse_pos
	var dist_to_mouse = cow.global_position.distance_to(mouse_pos)
	if dist_to_mouse < cow.mouse_flee_radius:
		print("COW FLEEING - mouse: ", mouse_pos, " cow: ", cow.global_position, " dist: ", dist_to_mouse)
		return SUCCESS
	return FAILURE
