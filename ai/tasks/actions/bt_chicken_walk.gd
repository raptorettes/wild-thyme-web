extends BTAction

@export var min_time: float = 2.0
@export var max_time: float = 7.0

var _timer: float = 0.0
var _duration: float = 0.0
var _direction: Vector2 = Vector2.ZERO

func _enter() -> void:
	var animal = scene_root
	_duration = randf_range(min_time, max_time)
	_timer = 0.0
	_pick_direction(animal)
	animal.set_behaviour_state("walk")
	animal.state_machine.travel(animal.get_anim("walk"))
	if _direction.x < 0:
		animal.sprite.flip_h = true
	elif _direction.x > 0:
		animal.sprite.flip_h = false

func _pick_direction(cow) -> void:
	var random_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	if cow.favourite_spot != Vector2.ZERO:
		var dist_to_spot = cow.global_position.distance_to(cow.favourite_spot)
		if dist_to_spot > 50.0:
			var toward_spot = (cow.favourite_spot - cow.global_position).normalized()
			var bias = clamp(dist_to_spot / 500.0, 0.3, 0.7)
			_direction = random_dir.lerp(toward_spot, bias).normalized()
		else:
			_direction = random_dir
	else:
		_direction = random_dir

func _tick(delta: float) -> int:
	var cow = scene_root
	_timer += delta
	
	if _timer >= _duration:
		cow.velocity = Vector2.ZERO
		return SUCCESS
	
	cow.velocity = _direction * cow.move_speed
	
	if cow.is_on_wall():
		_pick_direction(cow)
		if _direction.x < 0:
			cow.sprite.flip_h = true
		elif _direction.x > 0:
			cow.sprite.flip_h = false
	
	return RUNNING
