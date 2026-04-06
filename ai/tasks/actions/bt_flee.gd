extends BTAction

func _tick(delta: float) -> int:
	var animal = scene_root
	var mouse_pos = animal.get_global_mouse_position()
	
	var player = animal.get_tree().get_first_node_in_group("player")
	if player == null:
		return SUCCESS
	
	var dist_to_player = animal.global_position.distance_to(player.global_position)
	if dist_to_player > animal.player_flee_radius:
		return SUCCESS
	
	var dist_to_mouse = animal.global_position.distance_to(mouse_pos)
	if dist_to_mouse > animal.mouse_flee_radius:
		return SUCCESS
	
	var flee_dir = (animal.global_position - mouse_pos).normalized()
	animal.velocity = flee_dir * animal.flee_speed
	animal.set_behaviour_state("flee")
	animal.state_machine.travel(animal.get_anim("walk"))
	
	if flee_dir.x < 0:
		animal.sprite.flip_h = true
	elif flee_dir.x > 0:
		animal.sprite.flip_h = false
	
	if animal.is_on_wall():
		var scatter = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		animal.velocity = scatter * animal.flee_speed
	
	return RUNNING
