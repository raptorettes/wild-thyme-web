@tool
extends BTAction

@export var anim_name: String = ""
@export var min_duration: float = 2.0
@export var max_duration: float = 6.0

var _timer: float = 0.0
var _duration: float = 0.0

func _generate_name() -> String:
	return "PlayAnimTimed  [%s]  [%ss-%ss]" % [anim_name, min_duration, max_duration]

func _enter() -> void:
	_timer = 0.0
	_duration = randf_range(min_duration, max_duration)
	scene_root.state_machine.travel(anim_name)
	scene_root.velocity = Vector2.ZERO

func _tick(delta: float) -> Status:
	_timer += delta
	if _timer >= _duration:
		return SUCCESS
	return RUNNING
