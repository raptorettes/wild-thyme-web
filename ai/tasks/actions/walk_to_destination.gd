extends BTAction

var _timeout: float = 0.0
@export var max_walk_time: float = 8.0
@export var move_speed: float = 20.0

func _enter() -> void:
	_timeout = 0.0

func _tick(delta: float) -> int:
	var cow = scene_root
	var agent = cow.nav_agent
	
	_timeout += delta
	
	# Give up after max_walk_time regardless
	if agent.is_navigation_finished() or _timeout >= max_walk_time:
		cow.velocity = Vector2.ZERO
		return SUCCESS
	
	var next_pos = agent.get_next_path_position()
	var direction = (next_pos - cow.global_position).normalized()
	
	cow.velocity = direction * cow.move_speed
	cow.move_speed = move_speed
	cow.state_machine.travel("walk_right")
	
	if direction.x < 0:
		cow.sprite.flip_h = true
	elif direction.x > 0:
		cow.sprite.flip_h = false
	
	return RUNNING
