extends BTAction

@export var flee_duration: float = 1.0
var _timer: float = 0.0
var _flee_dir: Vector2 = Vector2.ZERO

func _enter() -> void:
	_timer = 0.0
	var animal = scene_root
	var panic_source = HerdManager.get_panic_source_near(animal.global_position)
	if panic_source != Vector2.ZERO:
		_flee_dir = (animal.global_position - panic_source).normalized()
	else:
		_flee_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	animal.set_behaviour_state("flee")
	animal.state_machine.travel(animal.get_anim("walk"))
	if _flee_dir.x < 0:
		animal.sprite.flip_h = true
	elif _flee_dir.x > 0:
		animal.sprite.flip_h = false

func _tick(delta: float) -> int:
	var animal = scene_root
	_timer += delta
	
	if _timer >= flee_duration:
		animal.velocity = Vector2.ZERO
		return SUCCESS
	
	animal.velocity = _flee_dir * animal.flee_speed
	
	if animal.is_on_wall():
		_flee_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	return RUNNING
