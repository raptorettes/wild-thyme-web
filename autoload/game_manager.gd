extends Node

@export var spot_radius: float = 40.0

#var cow_scenes: Array = [
	#preload("res://characters/cow.tscn"),           # purple
	#preload("res://characters/cow_blue.tscn"),
	#preload("res://characters/cow_green.tscn"),
	#preload("res://characters/cow_pink.tscn"),
	##preload("res://characters/cow_brown.tscn"),
	#preload("res://characters/cow_yellow.tscn"),
#]
#
#var baby_cow_scenes: Array = [
	#preload("res://characters/bb_cow.tscn"),        # purple
	#preload("res://characters/bb_cow_blue.tscn"),
	#preload("res://characters/bb_cow_green.tscn"),
	#preload("res://characters/bb_cow_pink.tscn"),
	##preload("res://assets/characters/bb_cow_brown.tscn"),
	#preload("res://characters/bb_cow_yellow.tscn"),
#]
#
#func get_random_cow_scene() -> PackedScene:
	#return cow_scenes[randi() % cow_scenes.size()]
#
#func get_random_baby_scene() -> PackedScene:
	#return baby_cow_scenes[randi() % baby_cow_scenes.size()]

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
	"Pumpkin", "Pear", "Apple", "Moss",
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
