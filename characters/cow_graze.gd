extends CharacterBody2D

enum COW_STATE { IDLE, WALK, REST, GRAZE, CHEW, LOVE, FLEE }

#signal found_cow

@export var move_speed: float = 20
@export var idle_time: float = 3
@export var walk_time: float = 2
@export var rest_time: float = 4 
@export var graze_time: float = 5
@export var chew_time: float = 4
@export var love_time: float = 2
#@export var is_secret: bool = false

@export var flee_speed: float = 40.0
@export var mouse_flee_radius: float = 40.0
@export var player_flee_radius: float = 80.0

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var sprite = $Sprite2D
@onready var timer = $Timer
@onready var cow_detector = $CowDetector

var move_direction: Vector2 = Vector2.ZERO
var current_state: COW_STATE = COW_STATE.IDLE
var pre_flee_state: COW_STATE = COW_STATE.IDLE


func _ready():
	randomize()
	pick_new_state()

func _physics_process(_delta):
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
	
	# If cow hits wall, pick new direction
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
		
func get_mouse_flee_force() -> Vector2:
	# first check if player is close by
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return Vector2.ZERO
		
	var dist_to_player = global_position.distance_to(player.global_position)
	if dist_to_player > player_flee_radius:
		return Vector2.ZERO
		
	# player is close enough, now check mouse distance
	var mouse_pos = get_global_mouse_position()
	var dist = global_position.distance_to(mouse_pos)
	if dist < mouse_flee_radius and dist > 0.0:
		var strength = 1.0 - (dist / mouse_flee_radius)
		return (global_position - mouse_pos).normalized() * strength
	return Vector2.ZERO
				
func get_avoidance_force() -> Vector2:
	var force = Vector2.ZERO
	var bodies =  cow_detector.get_overlapping_bodies()
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

func _resume_state(state: COW_STATE):
	match state:
		COW_STATE.IDLE:
			state_machine.travel("idle_right")
			timer.start(randf_range(idle_time * 0.5, idle_time * 1.5))
		COW_STATE.WALK:
			state_machine.travel("walk_right")
			select_new_direction()
			timer.start(randf_range(walk_time * 0.5, walk_time * 1.5))
		COW_STATE.REST:
			state_machine.travel("rest")
			timer.start(randf_range(walk_time * 0.5, walk_time * 1.5))
		COW_STATE.GRAZE:
			state_machine.travel("graze_right")
			timer.start(5.6)
		COW_STATE.LOVE:
			state_machine.travel("love")
			timer.start(randf_range(love_time * 0.5, love_time * 1.5))
		_:
			pick_new_state()

func select_new_direction():
	move_direction = Vector2(
		randi_range(-1,1),
		randi_range(-1,1)
	)
	move_direction = move_direction.normalized()
	if move_direction.x < 0:
		sprite.flip_h = true
	elif move_direction.x > 0:
		sprite.flip_h = false


func pick_new_state():
	var state_roll = randi() % 5  # 0=idle, 1=walk, 2=bounce, 3=graze, 4=love
	
	match state_roll:
		0:
			current_state = COW_STATE.IDLE
			state_machine.travel("idle_right")
			timer.start(randf_range(idle_time * 0.5, idle_time * 1.5))
		1:
			current_state = COW_STATE.WALK
			state_machine.travel("walk_right")
			select_new_direction()
			timer.start(randf_range(walk_time * 0.5, walk_time * 1.5))
		2:
			current_state = COW_STATE.REST
			state_machine.travel("rest")
			timer.start(randf_range(rest_time * 0.5, rest_time * 1.5))
		3:
			current_state = COW_STATE.GRAZE
			state_machine.travel("graze_right")
			timer.start(5.6)
		4:
			current_state = COW_STATE.LOVE
			state_machine.travel("love")
			timer.start(randf_range(love_time * 0.5, love_time * 1.5))

	
func _on_timer_timeout():
	if current_state == COW_STATE.GRAZE and randf() < 0.5:
		current_state = COW_STATE.CHEW
		state_machine.travel("chew")
		timer.start(randf_range(chew_time * 0.5, chew_time * 1.5))
	else:
		pick_new_state()


#func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	#if event.is_pressed() and is_secret:
		#current_state = COW_STATE.BOUNCE
		#state_machine.travel("bounce")
		#emit_signal("found_cow")
