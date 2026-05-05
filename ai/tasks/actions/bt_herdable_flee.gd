extends BTAction

@export var flee_speed: float = 50.0
@export var mouse_flee_radius: float = 60.0
@export var veer: float = 90.0
@export var debug: bool = true
@export var max_flee_duration: float = 1.5  # seconds before forcing re-eval

var _elapsed: float = 0.0

func _enter() -> void:
	_elapsed = 0.0

func _tick(delta: float) -> int:
	_elapsed += delta
	if _elapsed >= max_flee_duration:
		return FAILURE
		
	var animal = scene_root

	var player = animal.get_tree().get_first_node_in_group("player")
	if player == null:
		return SUCCESS

	var mouse_pos = player.world_mouse_pos

	var dist_to_mouse = animal.global_position.distance_to(mouse_pos)
	if dist_to_mouse > mouse_flee_radius:
		return SUCCESS

	if animal.nav_agent.is_navigation_finished():
		return SUCCESS

	var flee_dir = (animal.global_position - mouse_pos).normalized()
	animal.is_fleeing = true

	var next = animal.nav_agent.get_next_path_position()
	var nav_dir = (next - animal.global_position).normalized()

	var angle_to_flee = nav_dir.angle_to(flee_dir)
	var max_rad = deg_to_rad(veer)
	var clamped_angle = clamp(angle_to_flee, -max_rad, max_rad)
	var move_dir = nav_dir.rotated(clamped_angle)

	animal.velocity = move_dir * flee_speed
	animal.move_and_slide()

	if move_dir.x < 0:
		animal.sprite.flip_h = true
	elif move_dir.x > 0:
		animal.sprite.flip_h = false

	animal.state_machine.travel("walk_right")
	animal.anim_player.speed_scale = flee_speed / animal.move_speed

	if debug:
		_draw_debug(animal, nav_dir, flee_dir, move_dir, dist_to_mouse)

	return RUNNING

func _draw_debug(animal: Node2D, nav_dir: Vector2, flee_dir: Vector2, move_dir: Vector2, dist_to_mouse: float) -> void:
	var origin = animal.global_position
	var len = 40.0

	# Nav path direction — blue
	animal.draw_line(Vector2.ZERO, nav_dir * len, Color.BLUE, 1.0)
	# Raw flee direction (away from mouse) — red
	animal.draw_line(Vector2.ZERO, flee_dir * len, Color.RED, 1.0)
	# Actual clamped movement direction — green (the blend)
	animal.draw_line(Vector2.ZERO, move_dir * len, Color.GREEN, 2.0)
	# Veer arc endpoints — yellow, shows the allowed cone
	var max_rad = deg_to_rad(veer)
	animal.draw_line(Vector2.ZERO, nav_dir.rotated(max_rad) * len, Color.YELLOW, 1.0)
	animal.draw_line(Vector2.ZERO, nav_dir.rotated(-max_rad) * len, Color.YELLOW, 1.0)
	animal.queue_redraw() 
	
func _exit() -> void:
	var animal = scene_root
	animal.is_fleeing = false
	animal.anim_player.speed_scale = 1.0
