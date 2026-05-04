extends BTAction

var cow : CharacterBody2D = null
var nav_region: NavigationRegion2D = null
var nav_agent: NavigationAgent2D = null

@export var target_distance = 20

@export var min_dist = 50
@export var max_dist = 100
@export var debug: bool = true

@export var min_travel = 50
@export var max_travel = 100

@export var move_speed: float = 20

var final_target : Vector2 = Vector2.ZERO

func _setup() -> void:
	cow = scene_root
	var game_scene = scene_root.get_tree().root
	nav_region = game_scene.get_node("/root/GameLevel/NavigationRegion2D")
	nav_agent = cow.nav_agent
	return

func _enter() -> void:

	var direction = Vector2.from_angle(randf_range(0, TAU))
	var distance = randf_range(min_dist, max_dist)
	var target = cow.global_position + direction * distance

	# Snap to nearest navigable point
	#target = NavigationServer2D.map_get_closest_point(nav_agent.get_navigation_map(), target)

	# Get the full path, then walk only a random distance along it
	var travel_distance = randf_range(min_travel, max_travel)
	var path = NavigationServer2D.map_get_path(
		nav_region.get_navigation_map(),
		cow.global_position,
		target,
		true
	)

	# Walk the path segments until we hit our travel distance
	var travelled = 0.0
	final_target = cow.global_position
	for i in range(1, path.size()):
		var seg_length = path[i-1].distance_to(path[i])
		if travelled + seg_length >= travel_distance:
			var remaining = travel_distance - travelled
			final_target = path[i-1].lerp(path[i], remaining / seg_length)
			break
		travelled += seg_length
		final_target = path[i]

	nav_agent.target_position = final_target
	if debug:
		nav_agent.debug_enabled = true
		nav_agent.debug_path_custom_color = Color(randf_range(0.25,0.5), randf_range(0.25,0.5), randf_range(0.25,0.5))
	
	cow.set_behaviour_state("walk")
	cow.state_machine.travel(cow.get_anim("walk"))

	
func _tick(delta: float) -> Status:
	
	cow.move_toward(final_target)
	
	if cow.has_reached(final_target):
		return SUCCESS
	else:
		return RUNNING
