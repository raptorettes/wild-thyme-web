extends BTCondition

@export var base_chance: float = 0.3

func _tick(_delta: float) -> int:
	var cow = scene_root
	# Higher happiness = more likely to graze
	var chance = base_chance + (cow.happiness * 0.2)
	if randf() < chance:
		return SUCCESS
	return FAILURE
