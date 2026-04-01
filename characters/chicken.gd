extends CharacterBody2D

enum CHICKEN_STATE { IDLE, WALK, REST, PECK, FLEE, CARRIED, FLAPPING, SLEEPING }

@export var move_speed: float = 15
@export var idle_time: float = 3
@export var walk_time: float = 2
@export var rest_time: float = 2
@export var peck_time: float = 3
@export var flee_speed: float = 40.0
@export var mouse_flee_radius: float = 50.0
@export var player_flee_radius: float = 100.0

@onready var flap_sprite = $FlapSprite
@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var sprite = $Sprite2D
@onready var timer = $Timer
@onready var cow_detector = $CowDetector
@onready var pickup_area = $PickupArea

var water_layer: TileMapLayer
var move_direction: Vector2 = Vector2.ZERO
var current_state: CHICKEN_STATE = CHICKEN_STATE.IDLE
var pre_flee_state: CHICKEN_STATE = CHICKEN_STATE.IDLE
var wall_redirect_cooldown: float = 0.0

@export var favourite_spot: Vector2 = Vector2.ZERO

func _ready():
	randomize()
	pick_new_state()
	pickup_area.input_event.connect(_on_pickup_area_input)
	water_layer = get_tree().get_root().find_child("water", true, false)
	flap_sprite.visible = false
	# Auto assign favourite spot if not set
	if favourite_spot == Vector2.ZERO:
		favourite_spot = GameManager.get_random_spot()

func wake_up(exit_pos: Vector2 = Vector2.ZERO):
	is_sleeping = false
	var delay = randf_range(0.0, 3.0)
	await get_tree().create_timer(delay).timeout
	state_machine.travel("get_up")
	await get_tree().create_timer(get_up_duration).timeout
	current_state = CHICKEN_STATE.IDLE
	
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
	current_state = CHICKEN_STATE.WALK
	move_direction = (target - global_position).normalized()
	state_machine.travel("walk")  # chickens use "walk" not "walk_right"
	if move_direction.x < 0:
		sprite.flip_h = true
	elif move_direction.x > 0:
		sprite.flip_h = false

func _reached_position(target: Vector2) -> bool:
	while global_position.distance_to(target) > 30.0:
		await get_tree().process_frame
	return true

func _physics_process(_delta):
	# Don't do anything while sleeping
	if current_state == CHICKEN_STATE.SLEEPING:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	wall_redirect_cooldown -= _delta
	
	# Flapping back to land — handled entirely here, clean and simple
	if current_state == CHICKEN_STATE.FLAPPING:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var dir = (player.global_position - global_position).normalized()
			velocity = dir * flee_speed * 1.5
			move_and_slide()
		print("pos: ", global_position, " over water: ", _is_over_water(global_position))
		
		# Check every frame if we've reached land
		if not _is_over_water(global_position):
			_land_safely()
		return
	
	# Carried state
	if current_state == CHICKEN_STATE.CARRIED:
		global_position = get_global_mouse_position()
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_put_down()
		return
	
	# Mouse flee
	var mouse_flee = get_mouse_flee_force()
	
	if mouse_flee.length() > 0.0:
		if current_state != CHICKEN_STATE.FLEE:
			pre_flee_state = current_state
			current_state = CHICKEN_STATE.FLEE
			timer.stop()
		
		var flee_dir = mouse_flee.normalized()
		velocity = flee_dir * flee_speed
		
		state_machine.travel("walk")
		if flee_dir.x < 0:
			sprite.flip_h = true
		elif flee_dir.x > 0:
			sprite.flip_h = false
	
	else:
		if current_state == CHICKEN_STATE.FLEE:
			current_state = pre_flee_state
			_resume_state(pre_flee_state)
		
		if current_state == CHICKEN_STATE.WALK:
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
	
	if is_on_wall() and current_state == CHICKEN_STATE.WALK and wall_redirect_cooldown <= 0.0:
		wall_redirect_cooldown = 0.5
		select_new_direction()
	
	if is_on_wall() and current_state == CHICKEN_STATE.FLEE:
		var wall_scatter = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		velocity = wall_scatter * flee_speed

var is_sleeping: bool = false

@export var get_down_duration: float = 1.8  # set to your get_down animation length
@export var get_up_duration: float = 0.8   # set to your get_up animation length

func go_to_sleep():
	timer.stop()
	current_state = CHICKEN_STATE.SLEEPING
	is_sleeping = false
	var delay = randf_range(0.0, 5.0)
	await get_tree().create_timer(delay).timeout
	state_machine.travel("get_down")
	await get_tree().create_timer(get_down_duration).timeout
	state_machine.travel("sleep")
	is_sleeping = true


func _on_pickup_area_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("pickup area clicked!")
			var player = get_tree().get_first_node_in_group("player")
			if player == null:
				return
			var dist_to_player = global_position.distance_to(player.global_position)
			if dist_to_player < 40.0:
				_pick_up()

func _pick_up():
	current_state = CHICKEN_STATE.CARRIED
	timer.stop()
	$CollisionShape2D.disabled = true
	state_machine.travel("get_down")

func _put_down():
	var drop_pos = get_global_mouse_position()
		
	if _is_over_water(drop_pos):
		current_state = CHICKEN_STATE.FLAPPING
		$CollisionShape2D.disabled = true  # ← keep disabled while flapping!
		sprite.visible = false
		flap_sprite.visible = true
		flap_sprite.play("flap")
	else:
		current_state = CHICKEN_STATE.IDLE
		$CollisionShape2D.disabled = false
		state_machine.travel("idle")
		timer.start(randf_range(idle_time * 0.5, idle_time * 1.5))

func _land_safely():
	# Called when flapping chicken reaches land
	current_state = CHICKEN_STATE.IDLE
	$CollisionShape2D.disabled = false  # ← re-enable on landing
	flap_sprite.stop()
	flap_sprite.visible = false
	sprite.visible = true
	pick_new_state()

func _is_over_water(world_pos: Vector2) -> bool:
	if water_layer == null:
		return false
	var tile_pos = water_layer.local_to_map(world_pos)
	return water_layer.get_cell_source_id(tile_pos) != -1

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

func _resume_state(state: CHICKEN_STATE):
	match state:
		CHICKEN_STATE.IDLE:
			state_machine.travel("idle")
			timer.start(randf_range(idle_time * 0.5, idle_time * 1.5))
		CHICKEN_STATE.WALK:
			state_machine.travel("walk")
			select_new_direction()
			timer.start(randf_range(walk_time * 0.5, walk_time * 1.5))
		CHICKEN_STATE.REST:
			state_machine.travel("rest")
			timer.start(randf_range(rest_time * 0.5, rest_time * 1.5))
		CHICKEN_STATE.PECK:
			state_machine.travel("peck")
			timer.start(randf_range(peck_time * 0.5, peck_time * 1.5))
		_:
			pick_new_state()

func select_new_direction():
	move_direction = Vector2(randi_range(-1,1), randi_range(-1,1))
	if move_direction == Vector2.ZERO:
		move_direction = Vector2.RIGHT
	move_direction = move_direction.normalized()
	if move_direction.x < 0:
		sprite.flip_h = true
	elif move_direction.x > 0:
		sprite.flip_h = false

func pick_new_state():
	var state_roll = randi() % 4
	match state_roll:
		0:
			current_state = CHICKEN_STATE.IDLE
			state_machine.travel("idle")
			timer.start(randf_range(idle_time * 0.5, idle_time * 1.5))
		1:
			current_state = CHICKEN_STATE.WALK
			state_machine.travel("walk")
			select_new_direction()
			timer.start(randf_range(walk_time * 0.5, walk_time * 1.5))
		2:
			current_state = CHICKEN_STATE.REST
			state_machine.travel("rest")
			timer.start(randf_range(rest_time * 0.5, rest_time * 1.5))
		3:
			current_state = CHICKEN_STATE.PECK
			state_machine.travel("peck")
			timer.start(randf_range(peck_time * 0.5, peck_time * 1.5))

func _on_timer_timeout():
	pick_new_state()
