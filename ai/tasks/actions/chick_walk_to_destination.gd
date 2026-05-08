extends BTAction

var _timeout: float = 0.0
var chicken: CharacterBody2D = null
var nav_agent: NavigationAgent2D = null
var _flip_cooldown: float = 0.0
@export var flip_cooldown_time: float = 0.3
@export var max_walk_time: float = 8.0
@export var move_speed: float = 20.0

func _enter() -> void:
	chicken = scene_root
	nav_agent = chicken.nav_agent
	_timeout = 0.0

func _tick(delta: float) -> int:
	_timeout += delta
	
	if nav_agent.is_navigation_finished() or _timeout >= max_walk_time:
		chicken.velocity = Vector2.ZERO
		return SUCCESS
	
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - chicken.global_position).normalized()
	chicken.move_speed = move_speed
	chicken.velocity = direction * chicken.move_speed
	chicken.state_machine.travel("walk")  
	
	_update_facing(chicken, direction, delta)
	
	return RUNNING

func _update_facing(animal, direction: Vector2, delta: float) -> void:
	_flip_cooldown -= delta
	if _flip_cooldown > 0.0:
		return
	if abs(direction.x) > 0.3:
		if direction.x < 0:
			animal.sprite.flip_h = true
		elif direction.x > 0:
			animal.sprite.flip_h = false
		_flip_cooldown = flip_cooldown_time

func _exit() -> void:
	chicken.velocity = Vector2.ZERO
	chicken.state_machine.travel("idle") 
	chicken.nav_agent.target_position = chicken.global_position
