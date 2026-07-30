extends CharacterBody2D

enum COW_STATE { IDLE, WALK, REST, GRAZE, CHEW, LOVE, FLEE, SLEEPING }

@export var navigation_region: NavigationRegion2D
@export var color_index: int = 0

@export var move_speed: float = 30.0
@export var flee_speed: float = 45.0
@export var skittishness: float = 1.0

@export var happiness: float = 0.5
@export var happiness_gain_per_night: float = 0.3
@export var happiness_loss_per_night: float = 0.08
@export var happiness_chicken_penalty: float = 0.05

@export var favourite_spot: Vector2 = Vector2.ZERO
@export var get_down_duration: float = 0.6
@export var get_up_duration: float = 0.8
@export var days_in_herd: int = 0
@export var confidence: float = 0.5
@export var herd_cohesion: float = 0.0
@export var is_wanderer: bool = false
@export var cow_name: String = ""

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine = anim_tree.get("parameters/playback")
@onready var sprite = $Sprite2D

var current_state: COW_STATE = COW_STATE.IDLE
var is_sleeping: bool = false
var birth_ready: bool = false
var is_fleeing: bool = false

func _ready() -> void:
	randomize()
	color_index = randi_range(1, 5) if color_index == 0 else color_index
	match color_index:
		1: sprite.texture = load("res://assets/Animals/Cow/green-cow-sprites.png")
		2: sprite.texture = load("res://assets/Animals/Cow/blue-cow-sprites.png")
		3: sprite.texture = load("res://assets/Animals/Cow/pink-cow-sprites.png")
		4: sprite.texture = load("res://assets/Animals/Cow/yellow-cow-sprites.png")
		5: sprite.texture = load("res://assets/Animals/Cow/purple-cow-sprites.png")

	await get_tree().process_frame
	if favourite_spot == Vector2.ZERO:
		favourite_spot = GameManager.get_random_spot()
	if cow_name == "":
		cow_name = GameManager.get_cow_name()

func move_to(target: Vector2) -> void:
	nav_agent.target_position = target

func is_navigation_finished() -> bool:
	return nav_agent.is_navigation_finished()

func set_anim_state(state: StringName) -> void:
	anim_tree["parameters/conditions/" + state] = true

func _physics_process(delta: float) -> void:
	# Sleeping — do nothing else
	if current_state == COW_STATE.SLEEPING:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if is_fleeing:  # set true/false by the BT action
		return

	if nav_agent.is_navigation_finished():
		return

	var next = nav_agent.get_next_path_position()
	set_velocity((next - global_position).normalized() * move_speed)
	move_and_slide()

# --- Night cycle ---------------------------------------------------------

func apply_night_happiness(slept_safely: bool, chickens_present: bool):
	if slept_safely:
		happiness += happiness_gain_per_night
	else:
		happiness -= happiness_loss_per_night
	if chickens_present:
		happiness -= happiness_chicken_penalty
	happiness = clamp(happiness, 0.0, 1.0)

func go_to_sleep():
	var bt = $BTPlayer
	bt.set_active(false)  # pause behaviour tree while sleeping
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
	var delay = randf_range(0.5, 6.0)
	await get_tree().create_timer(delay).timeout
	state_machine.travel("get_up")
	await get_tree().create_timer(get_up_duration).timeout
	current_state = COW_STATE.IDLE

	# Walk to exit using the nav agent (BT is still paused here)
	if exit_pos != Vector2.ZERO:
		nav_agent.target_position = exit_pos
		while global_position.distance_to(exit_pos) > 40.0:
			var next = nav_agent.get_next_path_position()
			var dir = (next - global_position).normalized()
			velocity = dir * move_speed
			move_and_slide()
			await get_tree().process_frame

	# Restart behaviour tree
	$BTPlayer.set_active(true)
	current_state = COW_STATE.IDLE

	# Immediately start walking toward favourite spot
	if favourite_spot != Vector2.ZERO:
		nav_agent.target_position = GameManager.get_arrival_position(favourite_spot)

func get_effective_cohesion() -> float:
	var base = herd_cohesion
	var happiness_modifier = happiness * 0.3
	var experience_modifier = clamp(days_in_herd * 0.02, 0.0, 0.3)
	return clamp(base + happiness_modifier + experience_modifier, 0.0, 1.0)

# --- Player interaction ---------------------------------------------------

func receive_interaction():
	if Inventory.is_holding("star"):
		birth_ready = true
		Inventory.use_item()
		DialogueBox.show_message(
			"They've never eaten that before!",
			"love", ""
		)
		return

	if not Inventory.is_empty():
		happiness += Inventory.held_happiness_boost
		happiness = clamp(happiness, 0.0, 1.0)
		var mat = sprite.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("saturation", happiness)
		Inventory.use_item()
		$BTPlayer.set_active(false)
		state_machine.travel("love")
		await get_tree().create_timer(2.0).timeout
		$BTPlayer.set_active(true)
		return

	# No item — just show name
	$BTPlayer.set_active(false)
	state_machine.travel("love")
	await get_tree().create_timer(2.0).timeout
	$BTPlayer.set_active(true)

func play_name_reaction():
	$BTPlayer.set_active(false)
	state_machine.travel("love")
	await get_tree().create_timer(2.0).timeout
	$BTPlayer.set_active(true)
