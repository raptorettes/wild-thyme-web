extends BTAction

@export var min_time: float = 2.0
@export var max_time: float = 5.0
@export var direction_smooth: float = 0.1

var _timer: float = 0.0
var _duration: float = 0.0
var _direction: Vector2 = Vector2.ZERO
var _current_dir: Vector2 = Vector2.ZERO
var _stuck_timer: float = 0.0
var _last_position: Vector2 = Vector2.ZERO
var _escape_attempts: int = 0
var _wall_cooldown: float = 0.0

func _enter() -> void:
	var animal = scene_root
	_duration = randf_range(min_time, max_time)
	_timer = 0.0
	_stuck_timer = 0.0
	_escape_attempts = 0
	_wall_cooldown = 0.0
	_last_position = animal.global_position
	_pick_direction(animal)
	_current_dir = _direction
	animal.set_behaviour_state("walk")
	animal.state_machine.travel(animal.get_anim("walk"))
	_update_facing(animal, _direction)

func _update_facing(animal, direction: Vector2) -> void:
	if abs(direction.x) > 0.3:
		if direction.x < 0:
			animal.sprite.flip_h = true
		elif direction.x > 0:
			animal.sprite.flip_h = false

func _pick_direction(animal) -> void:
	var random_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	_direction = random_dir

func _pick_wall_escape(animal) -> void:
	var wall_normal = animal.get_wall_normal()
	if wall_normal != Vector2.ZERO:
		var angle = (PI / 2.0 + randf_range(0, PI / 3.0)) * sign(randf() - 0.5)
		_direction = wall_normal.rotated(angle)
	else:
		_direction = _direction.rotated(PI / 2.0 + randf_range(-0.3, 0.3))
	_update_facing(animal, _direction)

func _tick(delta: float) -> int:
	var animal = scene_root
	_timer += delta
	_wall_cooldown -= delta
	
	if _timer >= _duration:
		animal.velocity = Vector2.ZERO
		return SUCCESS
	
	if _last_position == Vector2.ZERO:
		_last_position = animal.global_position
	
	var moved = animal.global_position.distance_to(_last_position)
	
	if moved < 0.5 and not animal.is_on_wall():
		_stuck_timer += delta
	else:
		_stuck_timer = 0.0
		_escape_attempts = 0
	_last_position = animal.global_position
	
	if _stuck_timer > 1.5:
		_escape_attempts += 1
		_stuck_timer = 0.0
		if _escape_attempts >= 3:
			animal.velocity = Vector2.ZERO
			return SUCCESS
		else:
			_pick_direction(animal)
			_update_facing(animal, _direction)
	
	if animal.is_on_wall() and _wall_cooldown <= 0.0:
		_pick_wall_escape(animal)
		_wall_cooldown = 0.4
	
	var move_dir = _direction
	
	# Gentle separation from nearby cows
	var nearby = HerdManager.get_nearby_cows(animal.global_position, 20.0)
	var separation = Vector2.ZERO
	for other in nearby:
		if other != animal:
			var dist = animal.global_position.distance_to(other.global_position)
			var push = (animal.global_position - other.global_position).normalized()
			separation += push * (1.0 - dist / 20.0)
	
	if separation.length() > 0:
		move_dir = move_dir.lerp((move_dir + separation).normalized(), 0.15)
	
	# Smooth direction with lerp
	_current_dir = _current_dir.lerp(move_dir, direction_smooth)
	_update_facing(animal, _current_dir)
	animal.velocity = _current_dir * animal.move_speed
	
	return RUNNING
