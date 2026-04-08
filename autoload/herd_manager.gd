extends Node

# Panic system
var panicking_cows: Dictionary = {}  # cow_id: position
@export var panic_radius: float = 50.0
@export var panic_duration: float = 2.0

# Signals
signal cow_started_panicking(cow, position: Vector2)

func register_panic(cow) -> void:
	panicking_cows[cow.get_instance_id()] = {
		"position": cow.global_position,
		"timer": panic_duration
	}
	emit_signal("cow_started_panicking", cow, cow.global_position)

func clear_panic(cow) -> void:
	panicking_cows.erase(cow.get_instance_id())

func _process(delta: float) -> void:
	# Count down panic timers
	var to_remove = []
	for cow_id in panicking_cows:
		panicking_cows[cow_id]["timer"] -= delta
		if panicking_cows[cow_id]["timer"] <= 0:
			to_remove.append(cow_id)
	for id in to_remove:
		panicking_cows.erase(id)

func is_panic_nearby(position: Vector2) -> bool:
	for cow_id in panicking_cows:
		var panic_pos = panicking_cows[cow_id]["position"]
		if position.distance_to(panic_pos) < panic_radius:
			return true
	return false

func get_panic_source_near(position: Vector2) -> Vector2:
	# Returns the position of the nearest panicking cow
	var nearest = Vector2.ZERO
	var nearest_dist = INF
	for cow_id in panicking_cows:
		var panic_pos = panicking_cows[cow_id]["position"]
		var dist = position.distance_to(panic_pos)
		if dist < panic_radius and dist < nearest_dist:
			nearest_dist = dist
			nearest = panic_pos
	return nearest

func get_attractions_near(position: Vector2, animal_tag: String) -> Array:
	var results = []
	var points = get_tree().get_nodes_in_group("attraction_point")
	for point in points:
		if point.is_attracted(animal_tag) and point.get_strength_at(position) > 0:
			results.append(point)
	results.sort_custom(func(a, b): 
		return a.get_strength_at(position) > b.get_strength_at(position)
	)
	return results
