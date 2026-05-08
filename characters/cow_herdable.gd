extends CharacterBody2D
@export var navigation_region: NavigationRegion2D
@export var color_index: int = 0
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_player: AnimationPlayer = $AnimationPlayer

@onready var state_machine = anim_tree.get("parameters/playback")

@onready var sprite = $Sprite2D

var favourite_spot : Vector2 = Vector2.ZERO
var is_fleeing : bool = false
@export var move_speed = 30.0
@export var flee_speed = 40.0
@export var skittishness = 1.0

func _ready() -> void:
	randomize()
	color_index = randi_range(1,5) if color_index == 0 else color_index
	match color_index:
		1: sprite.texture = load("res://assets/Animals/Cow/green-cow-sprites.png")
		2: sprite.texture = load("res://assets/Animals/Cow/blue-cow-sprites.png")
		3: sprite.texture = load("res://assets/Animals/Cow/pink-cow-sprites.png")
		4: sprite.texture = load("res://assets/Animals/Cow/yellow-cow-sprites.png")
		5: sprite.texture = load("res://assets/Animals/Cow/purple-cow-sprites.png")

func move_to(target: Vector2) -> void:
	nav_agent.target_position = target

func is_navigation_finished() -> bool:
	return nav_agent.is_navigation_finished()

func set_anim_state(state: StringName) -> void:
	anim_tree["parameters/conditions/" + state] = true

func _physics_process(delta: float) -> void:
	if nav_agent.is_navigation_finished() and not is_fleeing:
		velocity = velocity.lerp(Vector2.ZERO, 0.2)
	move_and_slide()
