extends Node2D

class_name AttractionPoint

@export var strength: float = 1.0        # how strongly it attracts
@export var radius: float = 200.0        # how far the attraction reaches
@export var tags: Array[String] = ["all"] # who is attracted: "cow" "chicken" "all"
@export var available: bool = true        # can be toggled off by events

func is_attracted(animal_tag: String) -> bool:
	if not available:
		return false
	return tags.has("all") or tags.has(animal_tag)

func get_strength_at(pos: Vector2) -> float:
	var dist = global_position.distance_to(pos)
	if dist > radius:
		return 0.0
	# Strength falls off with distance
	return strength * (1.0 - (dist / radius))
