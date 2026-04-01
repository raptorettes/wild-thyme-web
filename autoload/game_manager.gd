extends Node

@export var spot_radius: float = 40.0

func get_all_spots() -> Array:
	return get_tree().get_nodes_in_group("favourite_spot")
	
func get_random_spot() -> Vector2:
	var spots = get_all_spots()
	if spots.is_empty():
		return Vector2.ZERO
	return spots[randi() % spots.size()].global_position
	
func get_arrival_position(spot: Vector2) -> Vector2:
	return spot + Vector2(
		randf_range(-spot_radius, spot_radius),
		randf_range(-spot_radius, spot_radius)
	)
