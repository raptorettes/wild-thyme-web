extends BTAction

@export var min_time: float = 2.0
@export var max_time: float = 5.0
@export var player_avoidance_radius: float = 40.0

var _timer: float = 0.0
var _duration: float = 0.0
var _direction: Vector2 = Vector2.ZERO
var _stuck_timer: float = 0.0
var _last_position: Vector2 = Vector2.ZERO
var _escape_attempts: int = 0

func _enter() -> void:
	var animal = scene_root
	_duration = randf_range(min_time, max_time)
	_timer = 0.0
	_stuck_timer = 0.0
	_escape_attempts = 0
	_last_position = animal.global_position
	_pick_direction(animal)
	animal.set_behaviour_state("walk")
	animal.state_machine.travel(animal.get_anim("walk"))
	if _direction.x < 0:
		animal.sprite.flip_h = true
	elif _direction.x > 0:
		animal.sprite.flip_h = false

func _pick_direction(animal) -> void:
	var random_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var final_dir = random_dir
	
	# Check if player is nearby — disable biases if so
	var player = animal.get_tree().get_first_node_in_group("player")
	var player_nearby = false
	if player and animal.get("player_flee_radius") != null:
		var dist = animal.global_position.distance_to(player.global_position)
		if dist < animal.player_flee_radius:
			player_nearby = true
	
	var use_biases = _escape_attempts < 2 and not player_nearby
	
	if use_biases and animal.get("is_wanderer") != null and not animal.is_wanderer:
		# Pull toward herd center
		var herd_center = HerdManager.get_herd_center()
		if herd_center != null and herd_center != Vector2.ZERO:
			var dist_to_herd = animal.global_position.distance_to(herd_center)
			if dist_to_herd > 80.0:
				var toward_herd = (herd_center - animal.global_position).normalized()
				var cohesion_bias = clamp(dist_to_herd / 400.0, 0.1, 0.5) * animal.get_effective_cohesion()
				final_dir = final_dir.lerp(toward_herd, cohesion_bias).normalized()
		
		# Pull toward lead cow
		var lead = HerdManager.current_lead
		if lead != null and lead != animal and is_instance_valid(lead):
			var dist_to_lead = animal.global_position.distance_to(lead.global_position)
			if dist_to_lead > 100.0:
				var toward_lead = (lead.global_position - animal.global_position).normalized()
				final_dir = final_dir.lerp(toward_lead, 0.2 * animal.get_effective_cohesion()).normalized()
	
	# Favourite spot pull — disabled when stuck or player nearby
	if use_biases and animal.get("favourite_spot") != null and animal.favourite_spot != Vector2.ZERO:
		var dist_to_spot = animal.global_position.distance_to(animal.favourite_spot)
		if dist_to_spot > 50.0:
			var toward_spot = (animal.favourite_spot - animal.global_position).normalized()
			var spot_bias = clamp(dist_to_spot / 500.0, 0.05, 0.2)
			final_dir = final_dir.lerp(toward_spot, spot_bias).normalized()
	
	_direction = final_dir

func _tick(delta: float) -> int:
	var animal = scene_root
	_timer += delta
	
	if _timer >= _duration:
		animal.velocity = Vector2.ZERO
		return SUCCESS
	
	# Initialise last position if needed
	if _last_position == Vector2.ZERO:
		_last_position = animal.global_position
	
	# Check if actually moving
	var moved = animal.global_position.distance_to(_last_position)
	if moved < 0.5:
		_stuck_timer += delta
	else:
		_stuck_timer = 0.0
		_escape_attempts = 0
	_last_position = animal.global_position
	
	# Stuck escape logic
	if _stuck_timer > 1.5:
		_escape_attempts += 1
		_stuck_timer = 0.0
		
		if _escape_attempts >= 3:
			animal.velocity = Vector2.ZERO
			return SUCCESS
		else:
			_direction = _direction.rotated(PI / 2.0)
			if _direction.x < 0:
				animal.sprite.flip_h = true
			elif _direction.x > 0:
				animal.sprite.flip_h = false
	
	# Wall response — slide along wall
	if animal.is_on_wall():
		var wall_normal = animal.get_wall_normal()
		if wall_normal != Vector2.ZERO:
			_direction = wall_normal.rotated(PI / 2.0 * sign(randf() - 0.5))
		else:
			_direction = _direction.rotated(PI / 2.0)
		if _direction.x < 0:
			animal.sprite.flip_h = true
		elif _direction.x > 0:
			animal.sprite.flip_h = false
	
	var move_dir = _direction
	
	# Short range separation from nearby cows
	var nearby = HerdManager.get_nearby_cows(animal.global_position, 25.0)
	var separation = Vector2.ZERO
	for other in nearby:
		if other != animal:
			var push = (animal.global_position - other.global_position).normalized()
			separation += push
	
	if separation.length() > 0:
		move_dir = (move_dir + separation * 0.2).normalized()
	
	# Player avoidance — personal space bubble
	var player = animal.get_tree().get_first_node_in_group("player")
	if player:
		var dist_to_player = animal.global_position.distance_to(player.global_position)
		if dist_to_player < player_avoidance_radius:
			var push_away = (animal.global_position - player.global_position).normalized()
			var push_strength = 1.0 - (dist_to_player / player_avoidance_radius)
			move_dir = (move_dir + push_away * push_strength * 2.0).normalized()
	
	animal.velocity = move_dir * animal.move_speed
	
	return RUNNING
