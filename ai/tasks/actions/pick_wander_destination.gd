extends BTAction

@export var wander_radius: float = 150.0

func _tick(_delta: float) -> int:
	var cow = scene_root
	cow.nav_agent.target_position = cow.global_position
	
	var random_offset = Vector2(
		randf_range(-wander_radius, wander_radius),
		randf_range(-wander_radius, wander_radius)
	)
	
	var target = cow.global_position + random_offset
	
	# Bias toward favourite spot if set
	if cow.favourite_spot != Vector2.ZERO:
		target = target.lerp(cow.favourite_spot, 0.3)
	
	cow.nav_agent.target_position = target
	return SUCCESS
