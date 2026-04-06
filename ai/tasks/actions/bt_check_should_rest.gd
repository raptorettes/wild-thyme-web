extends BTCondition

@export var base_chance: float = 0.2

func _tick(_delta: float) -> int:
	var cow = scene_root
	var chance = base_chance + (cow.happiness * 0.1)
	if randf() < chance:
		return SUCCESS
	return FAILURE
