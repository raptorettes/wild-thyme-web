@tool
extends BTAction

@export var range_min: float = 20.0
@export var range_max: float = 60.0
@export var position_var: StringName = &"move_target"

func _generate_name() -> String:
	return "SelectRandomNearbyPos  range: [%s, %s]  ➜%s" % [
		range_min, range_max,
		LimboUtility.decorate_var(position_var)]

func _tick(_delta: float) -> Status:
	var pos: Vector2
	var is_good: bool = false
	while not is_good:
		# pick a cardinal direction only
		var cardinals = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		var dir: Vector2 = cardinals[randi() % 4]
		var distance: float = randf_range(range_min, range_max)
		pos = scene_root.home_position + dir * distance
		is_good = scene_root.is_good_position(pos)
	blackboard.set_var(position_var, pos)
	return SUCCESS
