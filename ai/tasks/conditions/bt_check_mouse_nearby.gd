extends BTCondition

@export var mouse_flee_radius: float = 40.0
@export var player_flee_radius: float = 70.0

func _tick(_delta: float) -> int:
	var cow = scene_root
	
	var player = cow.get_tree().get_first_node_in_group("player")
	if player == null:
		return FAILURE
	
	# Player must be within range for mouse to matter
	var dist_to_player = cow.global_position.distance_to(player.global_position)
	if dist_to_player > player_flee_radius:
		return FAILURE
	
	# Then check mouse distance
	var mouse_pos = player.world_mouse_pos
	var dist_to_mouse = cow.global_position.distance_to(mouse_pos)
	if dist_to_mouse < mouse_flee_radius:
		print("Fleeing!")
		return SUCCESS
	
	return FAILURE
