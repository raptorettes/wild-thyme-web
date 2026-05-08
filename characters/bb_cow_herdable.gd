extends CharacterBody2D
@export var navigation_region: NavigationRegion2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_player: AnimationPlayer = $AnimationPlayer

@onready var state_machine = anim_tree.get("parameters/playback")

@onready var sprite = $Sprite2D

var favourite_spot : Vector2 = Vector2.ZERO
var is_fleeing : bool = false
@export var move_speed = 40.0
@export var flee_speed = 50.0
@export var skittishness = 1.0
@export var is_wanderer: bool = false

	
func move_to(target: Vector2) -> void:
	nav_agent.target_position = target

func is_navigation_finished() -> bool:
	return nav_agent.is_navigation_finished()

func set_anim_state(state: StringName) -> void:
	anim_tree["parameters/conditions/" + state] = true

func _physics_process(delta: float) -> void:
	move_and_slide()
