@tool
extends BTAction

@export var anim_name: String = ""

func _generate_name() -> String:
	return "PlayAnim  [%s]" % anim_name

func _enter() -> void:
	scene_root.state_machine.travel(anim_name)
	scene_root.velocity = Vector2.ZERO

func _tick(_delta: float) -> Status:
	var playback = scene_root.animation_tree.get("parameters/playback")
	if playback.get_current_node() == anim_name:
		var anim_length = scene_root.animation_tree.get_animation(anim_name).length
		if playback.get_current_play_position() >= anim_length - 0.05:
			return SUCCESS
	return RUNNING
