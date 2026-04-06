extends BTCondition

@export var base_chance: float = 0.3

func _tick(_delta: float) -> int:
	var cow = scene_root
	var chance = base_chance + (cow.happiness * 0.3)
	if randf() < chance:
		return SUCCESS
	return FAILURE
