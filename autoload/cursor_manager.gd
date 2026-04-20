extends Node

@export var cursor_speed: float = 800.0
var cursor_pos: Vector2 = Vector2.ZERO

func _ready():
	cursor_pos = get_viewport().get_visible_rect().size / 2.0
	Input.warp_mouse(Vector2(200, 200))

func _process(delta):
	if Input.get_connected_joypads().is_empty():
		return
	
	var joy_input = Vector2(
		Input.get_action_strength("cursor_right") - Input.get_action_strength("cursor_left"),
		Input.get_action_strength("cursor_down") - Input.get_action_strength("cursor_up")
	)
	
	if joy_input.length() < 0.15:
		return
	
	cursor_pos += joy_input * cursor_speed * delta
	cursor_pos = cursor_pos.clamp(Vector2.ZERO, get_viewport().get_visible_rect().size)
	
	# Convert viewport coords to screen coords
	var transform = get_viewport().get_screen_transform()
	var screen_pos = transform * cursor_pos
	
	var mouse_event = InputEventMouseMotion.new()
	mouse_event.position = cursor_pos
	mouse_event.relative = joy_input * cursor_speed * delta
	Input.parse_input_event(mouse_event)
	
	Input.warp_mouse(screen_pos)
