extends CharacterBody2D
@export var navigation_region: NavigationRegion2D

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim_tree: AnimationTree = $AnimationTree

@onready var state_machine = anim_tree.get("parameters/playback")

@onready var sprite = $Sprite2D

var favourite_spot : Vector2 = Vector2.ZERO

@export var move_speed = 20.0

func move_to(target: Vector2) -> void:
	nav_agent.target_position = target

func is_navigation_finished() -> bool:
	return nav_agent.is_navigation_finished()

func set_anim_state(state: StringName) -> void:
	anim_tree["parameters/conditions/" + state] = true

func _physics_process(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		return
	var next = nav_agent.get_next_path_position()
	set_velocity((next - global_position).normalized() * move_speed)
	move_and_slide()
	# Drive blend positions if using 2D directional blending
	#anim_tree["parameters/Walk/blend_position"] = velocity.normalized()
