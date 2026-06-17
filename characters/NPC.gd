extends CharacterBody2D
class_name NPC

@export var default_move_speed: float = 40.0
@export var move_speed: float = 40.0
@export var wander_radius: float = 100.0

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var sprite: Sprite2D = $Sprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var flee_body: CharacterBody2D = null
var target: Vector2
var home_position: Vector2

@export var skins: Array[Texture2D] = []
static var skin_index: int = 0

func _ready() -> void:
	home_position = global_position
	if skins.size() > 0:
		sprite.texture = skins[skin_index % skins.size()]
		skin_index += 1

func _physics_process(_delta: float) -> void:
	var next = nav_agent.get_next_path_position()
	velocity = (next - global_position).normalized() * move_speed
	if not nav_agent.is_navigation_finished():
		if velocity.x < 0.0:
			sprite.flip_h = true
		elif velocity.x >= 0:
			sprite.flip_h = false
	else:
		sprite.flip_h = false
		velocity = Vector2.ZERO
	move_and_slide()

func is_good_position(pos: Vector2) -> bool:
	return pos.distance_to(home_position) <= wander_radius

func _get_navigable(pos: Vector2) -> Vector2:
	return NavigationServer2D.map_get_closest_point(get_world_2d().navigation_map, pos)

func _go_to(pos: Vector2) -> void:
	nav_agent.target_position = pos
	state_machine.travel("run")

# Virtual methods — override in child classes
func _on_idle_state_entered() -> void:
	move_speed = default_move_speed
	velocity = Vector2.ZERO

func _on_wander_state_entered() -> void:
	target = _get_navigable(Vector2(
		global_position.x + randf_range(wander_radius * -1, wander_radius),
		global_position.y + randf_range(wander_radius * -1, wander_radius)
	))
	_go_to(target)

func _on_flee_state_entered() -> void:
	move_speed = default_move_speed * 1.5
	if flee_body:
		var flee_dir: Vector2 = (global_position - flee_body.global_position)
		target = _get_navigable(global_position + flee_dir * 2)
	_go_to(target)

func _on_navigation_agent_2d_navigation_finished() -> void:
	$StateChart.send_event("nav_finished")
