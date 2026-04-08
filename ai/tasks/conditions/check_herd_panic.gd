extends BTCondition

func _tick(_delta: float) -> int:
	var animal = scene_root
	
	# Don't react to own panic
	if HerdManager.is_panic_nearby(animal.global_position):
		# Skittishness determines if they react
		if randf() < animal.skittishness:
			return SUCCESS
	
	return FAILURE
