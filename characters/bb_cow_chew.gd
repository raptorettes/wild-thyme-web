extends CharacterBody2D

enum COW_STATE { IDLE, WALK, BOUNCE, GRAZE, CHEW, LOVE }

signal found_cow

@export var move_speed: float = 20
@export var idle_time: float = 3
@export var walk_time: float = 4
@export var bounce_time: float = 1 
@export var graze_time: float = 5
@export var chew_time: float = 4
@export var love_time: float = 2
@export var is_secret: bool = false

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var sprite = $Sprite2D
@onready var timer = $Timer
@onready var cow_detector = $CowDetector

var move_direction: Vector2 = Vector2.ZERO
var current_state: COW_STATE = COW_STATE.IDLE
var avoid_force: Vector2 = Vector2.ZERO

func _ready():
	randomize()
	pick_new_state()

func _physics_process(_delta):
	if current_state == COW_STATE.WALK:
		var avoid_force = get_avoidance_force()
		var final_direction = move_direction + avoid_force * 3.0
		final_direction = final_direction.normalized()
		velocity = final_direction * move_speed
	else:
		# Also apply avoidance when standing still so idle cows get nudged too
		var avoid_force = get_avoidance_force()
		if avoid_force.length() > 0.8:
			velocity = avoid_force.normalized() * move_speed * 0.2
		else:
			velocity = Vector2.ZERO
	
	move_and_slide()
	
	# If cow hits wall, pick new direction
	if is_on_wall() and current_state == COW_STATE.WALK:
		var away_direction = -velocity.normalized()
		move_direction = away_direction
		
		# Flip the sprite based on new horizontal direction
		if move_direction.x < 0:
			sprite.flip_h = true
		elif move_direction.x > 0:
			sprite.flip_h = false

func select_new_direction():
	move_direction = Vector2(
		randi_range(-1,1),
		randi_range(-1,1)
	)

	# Prevent standing still
	if move_direction == Vector2.ZERO:
		move_direction = Vector2.RIGHT

	move_direction = move_direction.normalized()

	# Flip sprite
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
			current_state = COW_STATE.BOUNCE
			state_machine.travel("bounce")
			timer.start(randf_range(bounce_time * 0.5, bounce_time * 1.5))
		3:
			current_state = COW_STATE.GRAZE
			state_machine.travel("graze")
			timer.start(randf_range(graze_time * 0.5, graze_time * 1.5))
		4:
			current_state = COW_STATE.LOVE
			state_machine.travel("love")
			timer.start(randf_range(love_time * 0.5, love_time * 1.5))

func get_avoidance_force():
	var force = Vector2.ZERO
	var bodies = cow_detector.get_overlapping_bodies()
	
	for body in bodies:
		if body != self and body.is_in_group("cow"):
			var push_dir = global_position - body.global_position
			force += push_dir.normalized()
		if body.is_in_group("player"):
			var push_dir = global_position - body.global_position
			force += push_dir.normalized() * 2.5
	
	return force
	
func _on_timer_timeout():
	if current_state == COW_STATE.GRAZE and randf() < 0.5:
		current_state = COW_STATE.CHEW
		state_machine.travel("chew")
		timer.start(randf_range(chew_time * 0.5, chew_time * 1.5))
	else:
		pick_new_state()


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_pressed() and is_secret:
		current_state = COW_STATE.BOUNCE
		state_machine.travel("bounce")
		emit_signal("found_cow")
