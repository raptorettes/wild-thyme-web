extends BTAction

@export var mouse_flee_radius: float = 60.0
@export var veer: float = 90.0
@export var min_flee_duration: float = 1.5
@export var max_flee_duration: float = 3.0
var _elapsed: float = 0.0
var _flip_cooldown: float = 0.0
@export var flip_cooldown_time: float = 0.3

func _enter() -> void:
	_elapsed = 0.0 + randf_range(-0.3, 0.3)

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
	
	if _elapsed >= min_flee_duration and dist_to_mouse > mouse_flee_radius * 1.5:
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
	
	animal.velocity = move_dir * animal.flee_speed
	
	_update_facing(animal, move_dir, delta)	
	
	animal.state_machine.travel("walk")
	animal.anim_player.speed_scale = animal.flee_speed / animal.move_speed
	
	return RUNNING

func _update_facing(animal, direction: Vector2, delta: float) -> void:
	_flip_cooldown -= delta
	if _flip_cooldown > 0.0:
		return
	if abs(direction.x) > 0.3:
		if direction.x < 0:
			animal.sprite.flip_h = true
		elif direction.x > 0:
			animal.sprite.flip_h = false
		_flip_cooldown = flip_cooldown_time

func _exit() -> void:
	var animal = scene_root
	animal.velocity = Vector2.ZERO
	animal.is_fleeing = false
	animal.state_machine.travel("idle")
	animal.anim_player.speed_scale = 1.0
