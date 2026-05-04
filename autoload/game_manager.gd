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
# In GameManager
var cow_names: Array[String] = [
	"Clover", "Bramble", "Thistle", "Meadow", "Sorrel",
	"Juniper", "Fern", "Nettle", "Moss", "Hazel",
	"Briar", "Rowan", "Sage", "Wren", "Blossom",
	"Dulcie", "Myrtle", "Ember", "Dew", "Lark",
	"Chicory", "Sedge", "Yarrow", "Fennel", "Dill",
	"Pumpkin", "Pear", "Apple", "Moss", "Pancake",
	"Blueberry", "Strawberry",
]
var used_names: Array[String] = []

func get_cow_name() -> String:
	if cow_names.is_empty():
		# Refill from used names when exhausted
		cow_names = used_names.duplicate()
		used_names.clear()
	var name_pick = cow_names[randi() % cow_names.size()]
	cow_names.erase(name_pick)
	used_names.append(name_pick)
	return name_pick
