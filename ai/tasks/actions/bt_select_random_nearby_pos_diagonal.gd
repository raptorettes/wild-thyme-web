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
		var angle: float = randf() * TAU
		var distance: float = randf_range(range_min, range_max)
		pos = scene_root.home_position + Vector2(sin(angle), cos(angle)) * distance
		is_good = scene_root.is_good_position(pos)
	blackboard.set_var(position_var, pos)
	return SUCCESS
