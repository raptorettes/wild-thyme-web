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

var cow_name: String = ""

func _ready() -> void:
	cow_name = GameManager.get_cow_name()
	
func move_to(target: Vector2) -> void:
	nav_agent.target_position = target

func is_navigation_finished() -> bool:
	return nav_agent.is_navigation_finished()

func set_anim_state(state: StringName) -> void:
	anim_tree["parameters/conditions/" + state] = true

func _physics_process(delta: float) -> void:
	move_and_slide()
	
func play_name_reaction():
	$BTPlayer.set_active(false)
	state_machine.travel(get_anim("love"))
	await get_tree().create_timer(2.0).timeout
	$BTPlayer.set_active(true)	

func get_anim(state_name: String) -> String:
	match state_name:
		"idle": return "idle_right"
		"walk": return "walk_right"
		"graze": return "graze_right"
		"rest": return "rest"
		"chew": return "chew"
		"love": return "love"
		"bounce": return "bounce"
		_: return "idle_right"
