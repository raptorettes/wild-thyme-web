extends BTAction

@export var speed_var: StringName = "move_speed"

var _cow: CharacterBody2D

func _setup() -> void:
	_cow = agent  # agent is your NPC root

func _enter() -> void:
	var target = blackboard.get_var("move_target")
	_cow.move_to(target)
	_cow.set_anim_state("walk")

func _tick(delta: float) -> Status:
	if _cow.is_navigation_finished():
		_cow.set_anim_state("idle")
		return SUCCESS
	return RUNNING

func _exit() -> void:
	_cow.set_anim_state("idle")
