extends BTAction

@export var min_time: float = 3.0
@export var max_time: float = 6.0

var _timer: float = 0.0
var _duration: float = 0.0

func _enter() -> void:
	var animal = scene_root
	_duration = randf_range(min_time, max_time)
	_timer = 0.0
	animal.set_behaviour_state("rest")
	animal.state_machine.travel(animal.get_anim("rest"))
	animal.velocity = Vector2.ZERO

func _tick(delta: float) -> int:
	_timer += delta
	if _timer >= _duration:
		return SUCCESS
	return RUNNING
