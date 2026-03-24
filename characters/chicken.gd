extends CharacterBody2D

enum CHICKEN_STATE { IDLE, WALK, REST, PECK, FLEE, CARRIED }

@export var move_speed: float = 15
@export var idle_time: float = 3
@export var walk_time: float = 2
@export var rest_time: float = 2
@export var peck_time: float = 3
@export var flee_speed: float = 40.0
@export var mouse_flee_radius: float = 50.0
@export var player_flee_radius: float = 100.0

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var sprite = $Sprite2D
@onready var timer = $Timer
@onready var cow_detector = $CowDetector
@onready var pickup_area = $PickupArea

var move_direction: Vector2 = Vector2.ZERO
var current_state: CHICKEN_STATE = CHICKEN_STATE.IDLE
var pre_flee_state: CHICKEN_STATE = CHICKEN_STATE.IDLE
var wall_redirect_cooldown: float = 0.0

func _ready():
	randomize()
	pick_new_state()
	pickup_area.input_event.connect(_on_pickup_area_input)
	
func _physics_process(delta):
	wall_redirect_cooldown -= delta
	
	# Carried state — chicken follows mouse cursor
	if current_state == CHICKEN_STATE.CARRIED:
		global_position = get_global_mouse_position()
		state_machine.travel("get_down")
		# Release when mouse button is let go
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_put_down()
		return
	
	# Mouse flee takes priority over everything else
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

func _on_pickup_area_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var player = get_tree().get_first_node_in_group("player")
			if player == null:
				return
			var dist_to_player = global_position.distance_to(player.global_position)
			if dist_to_player < 40.0:
				_pick_up()

func _pick_up():
	current_state = CHICKEN_STATE.CARRIED
	timer.stop()
	# Disable collision so it doesn't push things while carried
	$CollisionShape2D.disabled = true

func _put_down():
	current_state = CHICKEN_STATE.IDLE
	$CollisionShape2D.disabled = false
	# Burst away after being dropped, like the grub
	timer.start(randf_range(idle_time * 0.5, idle_time * 1.5))
	state_machine.travel("idle")

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
