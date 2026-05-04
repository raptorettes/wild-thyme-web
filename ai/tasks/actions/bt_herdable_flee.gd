extends BTAction

@export var flee_speed: float = 35.0
@export var mouse_flee_radius: float = 60.0

func _tick(delta: float) -> int:
	var animal = scene_root
	
	var player = animal.get_tree().get_first_node_in_group("player")
	if player == null:
		return SUCCESS
	
	var mouse_pos = player.world_mouse_pos
	
	# Only stop fleeing when mouse is far enough away
	var dist_to_mouse = animal.global_position.distance_to(mouse_pos)
	if dist_to_mouse > mouse_flee_radius:  # slightly larger radius to stop
		return SUCCESS
	
	if animal.nav_agent.is_navigation_finished():
		return SUCCESS
	
	#HerdManager.register_panic(animal)
	
	var flee_dir = (animal.global_position - mouse_pos).normalized()
	animal.velocity = flee_dir * flee_speed
	animal.move_speed = flee_speed
	animal.state_machine.travel("walk_right")
	
	if flee_dir.x == 0:
		animal.sprite.flip_h = true
	elif flee_dir.x < 0:
		animal.sprite.flip_h = true
	elif flee_dir.x > 0:
		animal.sprite.flip_h = false

	return RUNNING
