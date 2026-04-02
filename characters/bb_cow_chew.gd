extends CharacterBody2D

enum COW_STATE { IDLE, WALK, REST, BOUNCE, GRAZE, CHEW, LOVE, FLEE, SLEEPING }

signal found_cow

@export var move_speed: float = 20
@export var idle_time: float = 3
@export var walk_time: float = 4
@export var bounce_time: float = 1
@export var graze_time: float = 5
@export var chew_time: float = 4
@export var love_time: float = 2
@export var is_secret: bool = false
@export var flee_speed: float = 40.0
@export var mouse_flee_radius: float = 40.0
@export var player_flee_radius: float = 80.0
@export var rest_time: float = 4

# Happiness — babies start happier and are more resilient
@export var happiness: float = 0.7
@export var happiness_gain_per_night: float = 0.15
@export var happiness_loss_per_night: float = 0.04
@export var happiness_chicken_penalty: float = 0.03

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var sprite = $Sprite2D
@onready var timer = $Timer
@onready var cow_detector = $CowDetector

var move_direction: Vector2 = Vector2.ZERO
var current_state: COW_STATE = COW_STATE.IDLE
var pre_flee_state: COW_STATE = COW_STATE.IDLE

@export var favourite_spot: Vector2 = Vector2.ZERO

func _ready():
	randomize()
	if favourite_spot == Vector2.ZERO:
		favourite_spot = GameManager.get_random_spot()
	pick_new_state()

func _physics_process(_delta):
	# Don't do anything while sleeping
	if current_state == COW_STATE.SLEEPING:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var mouse_flee = get_mouse_flee_force()
	
	if mouse_flee.length() > 0.0:
		if current_state != COW_STATE.FLEE:
			pre_flee_state = current_state
			current_state = COW_STATE.FLEE
			timer.stop()
		var flee_direction = mouse_flee.normalized()
		velocity = flee_direction * flee_speed
		
		state_machine.travel("walk_right")
		if flee_direction.x < 0:
			sprite.flip_h = true
		elif flee_direction.x > 0:
			sprite.flip_h = false
	
	else:
		if current_state == COW_STATE.FLEE:
			current_state = pre_flee_state
			_resume_state(pre_flee_state)
		
		if current_state == COW_STATE.WALK:
			var avoid = get_avoidance_force()
			var final_dir = (move_direction + avoid * 3.0).normalized()
			velocity = final_dir * move_speed
		else:
			var avoid = get_avoidance_force()
			if avoid.length() > 0.8:
				velocity = avoid.normalized() * move_speed * 0.2
			else:
				velocity = Vector2.ZERO
	
	move_and_slide()
	
	if is_on_wall() and current_state == COW_STATE.WALK:
		var away_direction = -velocity.normalized()
		move_direction = away_direction
		if move_direction.x < 0:
			sprite.flip_h = true
		elif move_direction.x > 0:
			sprite.flip_h = false
	
	if is_on_wall() and current_state == COW_STATE.FLEE:
		var scatter = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		velocity = scatter * flee_speed
		
var is_sleeping: bool = false

@export var get_down_duration: float = 1.16  # set to your get_down animation length
@export var get_up_duration: float = 1.0    # set to your get_up animation length

func go_to_sleep():
	timer.stop()
	current_state = COW_STATE.SLEEPING
	is_sleeping = false
	var delay = randf_range(0.0, 5.0)
	await get_tree().create_timer(delay).timeout
	state_machine.travel("get_down")
	await get_tree().create_timer(get_down_duration).timeout
	state_machine.travel("sleep")
	is_sleeping = true

func wake_up(exit_pos: Vector2 = Vector2.ZERO):
	is_sleeping = false
	var delay = randf_range(0.0, 3.0)
	await get_tree().create_timer(delay).timeout
	state_machine.travel("get_up")
	await get_tree().create_timer(get_up_duration).timeout
	current_state = COW_STATE.IDLE
	
	# Walk to enclosure exit first
	if exit_pos != Vector2.ZERO:
		_walk_to_position(exit_pos)
		await _reached_position(exit_pos)
	
	# Then walk to favourite spot
	if favourite_spot != Vector2.ZERO:
		var arrival = GameManager.get_arrival_position(favourite_spot)
		_walk_to_position(arrival)
		await _reached_position(arrival)
	
	pick_new_state()

func _walk_to_position(target: Vector2):
	current_state = COW_STATE.WALK
	move_direction = (target - global_position).normalized()
	state_machine.travel("walk_right")
	if move_direction.x < 0:
		sprite.flip_h = true
	elif move_direction.x > 0:
		sprite.flip_h = false

func _reached_position(target: Vector2) -> bool:
	while global_position.distance_to(target) > 30.0:
		await get_tree().process_frame
	return true

func apply_night_happiness(slept_safely: bool, chickens_present: bool):
	if slept_safely:
		happiness += happiness_gain_per_night
	else:
		happiness -= happiness_loss_per_night
	if chickens_present:
		happiness -= happiness_chicken_penalty
	happiness = clamp(happiness, 0.0, 1.0)
	_update_flee_radius()

func _update_flee_radius():
	if happiness < 0.3:
		player_flee_radius = 120.0
	elif happiness < 0.6:
		player_flee_radius = 80.0
	elif happiness < 0.8:
		player_flee_radius = 50.0
	else:
		player_flee_radius = 20.0

func pick_new_state():
	var roll = randf()
	
	if happiness < 0.3:
		if roll < 0.40:
			_set_state_idle()
		elif roll < 0.75:
			_set_state_walk()
		elif roll < 0.90:
			_set_state_rest()
		else:
			_set_state_graze()
	
	elif happiness < 0.6:
		if roll < 0.25:
			_set_state_idle()
		elif roll < 0.45:
			_set_state_walk()
		elif roll < 0.60:
			_set_state_rest()
		elif roll < 0.75:
			_set_state_graze()
		elif roll < 0.90:
			_set_state_bounce()
		else:
			_set_state_love()
	
	elif happiness < 0.8:
		if roll < 0.10:
			_set_state_idle()
		elif roll < 0.25:
			_set_state_walk()
		elif roll < 0.40:
			_set_state_rest()
		elif roll < 0.60:
			_set_state_graze()
		elif roll < 0.80:
			_set_state_bounce()
		else:
			_set_state_love()
	
	else:
		# Very happy baby — bouncing everywhere
		if roll < 0.05:
			_set_state_idle()
		elif roll < 0.15:
			_set_state_walk()
		elif roll < 0.25:
			_set_state_rest()
		elif roll < 0.45:
			_set_state_graze()
		elif roll < 0.70:
			_set_state_bounce()
		else:
			_set_state_love()

func _set_state_idle():
	current_state = COW_STATE.IDLE
	state_machine.travel("idle_right")
	timer.start(randf_range(idle_time * 0.5, idle_time * 1.5))

func _set_state_walk():
	current_state = COW_STATE.WALK
	state_machine.travel("walk_right")
	select_new_direction()
	timer.start(randf_range(walk_time * 0.5, walk_time * 1.5))

func _set_state_rest():
	current_state = COW_STATE.REST
	state_machine.travel("rest")
	timer.start(5.2)

func _set_state_graze():
	current_state = COW_STATE.GRAZE
	state_machine.travel("graze")
	timer.start(5.6)

func _set_state_bounce():
	current_state = COW_STATE.BOUNCE
	state_machine.travel("bounce")
	timer.start(randf_range(bounce_time * 0.5, bounce_time * 1.5))

func _set_state_love():
	current_state = COW_STATE.LOVE
	state_machine.travel("love")
	timer.start(randf_range(love_time * 0.5, love_time * 1.5))

func _resume_state(state: COW_STATE):
	match state:
		COW_STATE.IDLE:
			_set_state_idle()
		COW_STATE.WALK:
			_set_state_walk()
		COW_STATE.REST:
			_set_state_rest()
		COW_STATE.GRAZE:
			_set_state_graze()
		COW_STATE.BOUNCE:
			_set_state_bounce()
		COW_STATE.LOVE:
			_set_state_love()
		_:
			pick_new_state()

func get_mouse_flee_force() -> Vector2:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return Vector2.ZERO
	var dist_to_player = global_position.distance_to(player.global_position)
	if dist_to_player > player_flee_radius:
		return Vector2.ZERO
	var mouse_pos = get_global_mouse_position()
	var dist = global_position.distance_to(mouse_pos)
	if dist < mouse_flee_radius and dist > 0.0:
		var strength = 1.0 - (dist / mouse_flee_radius)
		return (global_position - mouse_pos).normalized() * strength
	return Vector2.ZERO

func get_avoidance_force() -> Vector2:
	var force = Vector2.ZERO
	var bodies = cow_detector.get_overlapping_bodies()
	for body in bodies:
		if body != self and body.is_in_group("cow"):
			var push_dir = global_position - body.global_position
			force += push_dir.normalized()
		if body != self and body.is_in_group("chickens"):
			var push_dir = global_position - body.global_position
			force += push_dir.normalized()
		if body.is_in_group("player"):
			var push_dir = global_position - body.global_position
			force += push_dir.normalized() * 2.5
	return force

func select_new_direction():
	move_direction = Vector2(randi_range(-1,1), randi_range(-1,1))
	if move_direction == Vector2.ZERO:
		move_direction = Vector2.RIGHT
	move_direction = move_direction.normalized()
	if move_direction.x < 0:
		sprite.flip_h = true
	elif move_direction.x > 0:
		sprite.flip_h = false

func _on_timer_timeout():
	if current_state == COW_STATE.GRAZE and randf() < 0.5:
		current_state = COW_STATE.CHEW
		state_machine.travel("chew")
		timer.start(randf_range(chew_time * 0.5, chew_time * 1.5))
	else:
		pick_new_state()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_pressed() and is_secret:
		current_state = COW_STATE.BOUNCE
		state_machine.travel("bounce")
		emit_signal("found_cow")
