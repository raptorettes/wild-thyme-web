extends BTAction

@export var min_time: float = 4.0
@export var max_time: float = 7.0
@export var chew_chance: float = 0.5

var _timer: float = 0.0
var _duration: float = 0.0
var _chewing: bool = false

func _enter() -> void:
	var animal = scene_root
	_duration = randf_range(min_time, max_time)
	_timer = 0.0
	_chewing = false
	animal.set_behaviour_state("graze")
	animal.state_machine.travel(animal.get_anim("graze"))
	animal.velocity = Vector2.ZERO

func _tick(delta: float) -> int:
	var animal = scene_root
	_timer += delta
	if not _chewing and _timer > _duration * 0.5 and randf() < chew_chance:
		_chewing = true
		animal.set_behaviour_state("chew")
		animal.state_machine.travel(animal.get_anim("chew"))
	if _timer >= _duration:
		return SUCCESS
	return RUNNING
