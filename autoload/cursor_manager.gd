extends Node

@export var cursor_speed: float = 800.0
var cursor_pos: Vector2 = Vector2.ZERO

func _ready():
	
	# Start cursor in center of screen
	cursor_pos = get_viewport().get_visible_rect().size / 2.0

func _process(delta):
	#print("cursor_right: ", Input.get_action_strength("cursor_right"))
	#print("cursor_left: ", Input.get_action_strength("cursor_left"))
	if Input.get_connected_joypads().is_empty():
		return
	
	var joy_input = Vector2(
		Input.get_action_strength("cursor_right") - Input.get_action_strength("cursor_left"),
		Input.get_action_strength("cursor_down") - Input.get_action_strength("cursor_up")
	)
	
	if joy_input.length() < 0.15:
		joy_input = Vector2.ZERO
	
	cursor_pos += joy_input * cursor_speed * delta
	cursor_pos = cursor_pos.clamp(Vector2.ZERO, get_viewport().get_visible_rect().size)
	Input.warp_mouse(cursor_pos)
