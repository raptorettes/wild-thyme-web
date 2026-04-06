extends BTCondition

func _tick(_delta: float) -> int:
	var cow = scene_root
	
	var player = cow.get_tree().get_first_node_in_group("player")
	if player == null:
		print("no player found")
		return FAILURE
	
	var dist_to_player = cow.global_position.distance_to(player.global_position)
	if dist_to_player > cow.player_flee_radius:
		return FAILURE
	
	var mouse_pos = cow.get_global_mouse_position()
	var dist_to_mouse = cow.global_position.distance_to(mouse_pos)
	if dist_to_mouse < cow.mouse_flee_radius:
		return SUCCESS
	
	return FAILURE
