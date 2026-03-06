extends CharacterBody2D

# --- States ---
enum COW_STATE { IDLE, WALK, LOVE }

# --- Exported Variables ---
@export var move_speed: float = 20
@export var idle_time: float = 5       # seconds for idle
@export var walk_time: float = 2       # seconds for walking
@export var love_duration: float = 2   # seconds for love animation

# --- Onready Variables ---
@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var sprite = $Sprite2D
@onready var timer = $Timer
@onready var love_area = $LoveArea

# --- Internal Variables ---
var move_direction: Vector2 = Vector2.ZERO
var current_state: COW_STATE = COW_STATE.IDLE

# --- Initialization ---
func _ready():
	randomize()
	add_to_group("cows")  # so we can detect other cows
	pick_new_state()
	
	# Connect LoveArea signal
	love_area.body_entered.connect(_on_love_area_body_entered)

# --- Physics Process ---
func _physics_process(_delta):
	if current_state == COW_STATE.WALK:
		velocity = move_direction * move_speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	
	# Wall avoidance: pick new direction if bumping into wall
	if is_on_wall() and current_state == COW_STATE.WALK:
		select_new_direction()

# --- Select a New Random Direction ---
func select_new_direction():
	move_direction = Vector2(randi_range(-1,1), randi_range(-1,1))
	
	# Prevent standing still
	if move_direction == Vector2.ZERO:
		move_direction = Vector2.RIGHT
	
	move_direction = move_direction.normalized()
	
	# Flip sprite horizontally
	if move_direction.x < 0:
		sprite.flip_h = true
	elif move_direction.x > 0:
		sprite.flip_h = false

# --- Pick Next State Based on Current State ---
func pick_new_state():
	if current_state == COW_STATE.IDLE:
		current_state = COW_STATE.WALK
		state_machine.travel("walk_right")  # replace with your walk animation name
		select_new_direction()
		timer.start(randf_range(walk_time * 0.5, walk_time * 1.5))
	elif current_state == COW_STATE.WALK:
		current_state = COW_STATE.IDLE
		state_machine.travel("idle_right")  # replace with your idle animation name
		timer.start(randf_range(idle_time * 0.5, idle_time * 1.5))
	# If in LOVE state, do nothing; timer handles resuming

# --- Timer Timeout Handler ---
func _on_timer_timeout():
	# Only pick new state if not currently in LOVE
	if current_state != COW_STATE.LOVE:
		pick_new_state()

# --- LoveArea Signal Handler ---
func _on_love_area_body_entered(body):
	# Ignore self or non-cows
	if body == self or not body.is_in_group("cows"):
		return
	
	# Enter LOVE state
	current_state = COW_STATE.LOVE
	state_machine.travel("love")  # replace with your love animation name
	timer.start(love_duration)
	
	# Face the other cow
	sprite.flip_h = global_position.x > body.global_position.x
