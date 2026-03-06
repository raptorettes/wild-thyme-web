extends CharacterBody2D

enum COW_STATE { IDLE, WALK, LOVE }

@export var move_speed: float = 20
@export var idle_time: float = 5
@export var walk_time: float = 2


@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var sprite = $Sprite2D
@onready var timer = $Timer

var move_direction: Vector2 = Vector2.ZERO
var current_state: COW_STATE = COW_STATE.IDLE

func _ready():
	randomize()
	pick_new_state()

func _physics_process(_delta):
	if current_state == COW_STATE.WALK:
		velocity = move_direction * move_speed
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
	if current_state == COW_STATE.IDLE:
		current_state = COW_STATE.WALK
		state_machine.travel("walk_right")
		select_new_direction()
		timer.start(randf_range(walk_time * 0.5, walk_time * 1.5))

	else:
		current_state = COW_STATE.IDLE
		state_machine.travel("idle_right")
		timer.start(randf_range(idle_time * 0.5, idle_time * 1.5))

func _on_timer_timeout():
	pick_new_state()
