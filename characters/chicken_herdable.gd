extends CharacterBody2D
@export var navigation_region: NavigationRegion2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_player: AnimationPlayer = $AnimationPlayer

@onready var state_machine = anim_tree.get("parameters/playback")
@onready var sprite = $Sprite2D
var favourite_spot : Vector2 = Vector2.ZERO
var is_fleeing : bool = false
@export var move_speed = 50.0
@export var flee_speed = 60.0

@export var get_down_duration: float = 1.8
@export var get_up_duration: float = 0.8
@onready var flap_sprite = $FlapSprite
var water_layer: TileMapLayer
var is_sleeping: bool = false


func move_to(target: Vector2) -> void:
	nav_agent.target_position = target

func is_navigation_finished() -> bool:
	return nav_agent.is_navigation_finished()

func get_anim(state_name: String) -> String:
	match state_name:
		"idle": return "idle"
		"walk": return "walk"
		"rest": return "rest"
		"peck": return "peck"
		_: return "idle"

func set_anim_state(state: StringName) -> void:
	anim_tree["parameters/conditions/" + state] = true

func _physics_process(delta: float) -> void:
	if is_fleeing:  # set true/false by the BT action
		return
	if nav_agent.is_navigation_finished():
		return
	var next = nav_agent.get_next_path_position()
	set_velocity((next - global_position).normalized() * move_speed)
	move_and_slide()
