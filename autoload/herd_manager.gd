extends Node

# Panic system
var panicking_cows: Dictionary = {}
@export var panic_radius: float = 50.0
@export var panic_duration: float = 3.0

# Herd system
var current_lead: Node = null
var lead_update_timer: float = 0.0
@export var lead_update_interval: float = 10.0

signal cow_started_panicking(cow, position: Vector2)

func _process(delta: float) -> void:
	# Update panic timers
	var to_remove = []
	for cow_id in panicking_cows:
		panicking_cows[cow_id]["timer"] -= delta
		if panicking_cows[cow_id]["timer"] <= 0:
			to_remove.append(cow_id)
	for id in to_remove:
		panicking_cows.erase(id)
	
	# Recalculate lead cow periodically
	lead_update_timer += delta
	if lead_update_timer > lead_update_interval:
		lead_update_timer = 0.0
		current_lead = _calculate_lead_cow()

func _calculate_lead_cow() -> Node:
	var cows = get_tree().get_nodes_in_group("cows")
	var best_cow = null
	var best_score = -1.0
	for cow in cows:
		if cow.is_wanderer:
			continue
		if cow.is_in_group("baby"):
			continue
		var score = cow.happiness + (cow.days_in_herd * 0.1) + (cow.confidence * 0.2)
		if score > best_score:
			best_score = score
			best_cow = cow
	return best_cow

func get_herd_center() -> Vector2:
	var cows = get_tree().get_nodes_in_group("cows")
	if cows.is_empty():
		return Vector2.ZERO
	var total = Vector2.ZERO
	var count = 0
	for cow in cows:
		if not cow.get("is_wanderer") != null:
			continue
		if not cow.is_wanderer:
			total += cow.global_position
			count += 1
	if count == 0:
		return Vector2.ZERO
	return total / count

func get_nearby_cows(position: Vector2, radius: float) -> Array:
	var cows = get_tree().get_nodes_in_group("cows")
	var result = []
	for cow in cows:
		if cow.get("is_wanderer") == null:
			print("MISSING SCRIPT on: ", cow.name, " type: ", cow.get_class(), " script: ", cow.get_script())
			continue
		if cow.global_position.distance_to(position) < radius and not cow.is_wanderer:
			result.append(cow)
	return result
	
func register_panic(cow) -> void:
	panicking_cows[cow.get_instance_id()] = {
		"position": cow.global_position,
		"timer": panic_duration
	}
	emit_signal("cow_started_panicking", cow, cow.global_position)

func clear_panic(cow) -> void:
	panicking_cows.erase(cow.get_instance_id())

func is_panic_nearby(position: Vector2) -> bool:
	for cow_id in panicking_cows:
		var panic_pos = panicking_cows[cow_id]["position"]
		if position.distance_to(panic_pos) < panic_radius:
			return true
	return false

func get_panic_source_near(position: Vector2) -> Vector2:
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
