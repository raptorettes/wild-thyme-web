extends CharacterBody2D

enum COW_STATE { IDLE, WALK, REST, BOUNCE, GRAZE, CHEW, LOVE, FLEE, SLEEPING }
signal ready_to_grow_up(baby)
signal found_cow

@export var navigation_region: NavigationRegion2D
@export var is_secret: bool = false

@export var move_speed: float = 45.0
@export var flee_speed: float = 60.0
@export var skittishness: float = 1.0

@export var happiness: float = 0.7
@export var happiness_gain_per_night: float = 0.3
@export var happiness_loss_per_night: float = 0.04
@export var happiness_chicken_penalty: float = 0.03

@export var favourite_spot: Vector2 = Vector2.ZERO
@export var get_down_duration: float = 0.6
@export var get_up_duration: float = 0.8
@export var days_in_herd: int = 0  # affects lead cow that chooses favourite spot
@export var confidence: float = 0.5  # affects lead cow, born with a number
@export var herd_cohesion: float = 0.0
@export var is_wanderer: bool = false
@export var cow_name: String = ""
@export var color_variant: String = "purple"

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine = anim_tree.get("parameters/playback")
@onready var sprite = $Sprite2D

var current_state: COW_STATE = COW_STATE.IDLE
var is_sleeping: bool = false
var is_fleeing: bool = false
var player_flee_radius: float = 80.0  

func _ready() -> void:
	randomize()
	await get_tree().process_frame
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

# --- Growing up ------------------------------------------------------------

func grow_up_sequence():
	var bt = $BTPlayer
	bt.set_active(false)

	# Flash white then normal several times
	for i in range(4):
		sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(10, 10, 10, 1)  # very bright white flash
		await get_tree().create_timer(0.1).timeout

	# Hold white
	sprite.modulate = Color(10, 10, 10, 1)
	await get_tree().create_timer(0.2).timeout

	# Signal NightManager to do the scene swap
	emit_signal("ready_to_grow_up", self)

func set_behaviour_state(state_name: String):
	match state_name:
		"idle": current_state = COW_STATE.IDLE
		"walk": current_state = COW_STATE.WALK
		"flee": current_state = COW_STATE.FLEE
		"graze": current_state = COW_STATE.GRAZE
		"rest": current_state = COW_STATE.REST
		"chew": current_state = COW_STATE.CHEW
		"bounce": current_state = COW_STATE.BOUNCE

func get_anim(state_name: String) -> String:
	match state_name:
		"idle": return "idle_right"
		"walk": return "walk_right"
		"graze": return "graze"
		"rest": return "rest"
		"chew": return "chew"
		"bounce": return "bounce"
		"love": return "love"
		_: return "idle_right"

# --- Night cycle -------------------------------------------------------

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
	var delay = randf_range(0.5, 5.0)
	await get_tree().create_timer(delay).timeout
	state_machine.travel("get_up")
	await get_tree().create_timer(get_up_duration).timeout
	current_state = COW_STATE.IDLE

	# Use nav agent to walk to exit
	if exit_pos != Vector2.ZERO:
		nav_agent.target_position = exit_pos
		while global_position.distance_to(exit_pos) > 30.0:
			var next = nav_agent.get_next_path_position()
			var dir = (next - global_position).normalized()
			velocity = dir * move_speed
			move_and_slide()

			# Play walk animation
			state_machine.travel(get_anim("walk"))
			if dir.x < 0:
				sprite.flip_h = true
			elif dir.x > 0:
				sprite.flip_h = false

			await get_tree().process_frame

	# Restart behaviour tree
	$BTPlayer.set_active(true)
	current_state = COW_STATE.IDLE

	# Immediately start walking toward favourite spot
	if favourite_spot != Vector2.ZERO:
		nav_agent.target_position = GameManager.get_arrival_position(favourite_spot)

# --- Misc / interaction -------------------------------------------------

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_pressed() and is_secret:
		current_state = COW_STATE.BOUNCE
		state_machine.travel("bounce")
		emit_signal("found_cow")

func get_effective_cohesion() -> float:
	var base = herd_cohesion
	var happiness_modifier = happiness * 0.3
	var experience_modifier = clamp(days_in_herd * 0.02, 0.0, 0.3)
	return clamp(base + happiness_modifier + experience_modifier, 0.0, 1.0)

func receive_interaction():
	if Inventory.is_holding("star"):
		# Baby cows can't give birth!
		DialogueBox.show_message(
			"They're too little for that kind of magic.",
			"talking",
			""
		)
		return

	if not Inventory.is_empty():
		happiness += Inventory.held_happiness_boost
		happiness = clamp(happiness, 0.0, 1.0)
		Inventory.use_item()
		set_behaviour_state("love")
		state_machine.travel(get_anim("love"))
		$BTPlayer.set_active(false)
		await get_tree().create_timer(2.0).timeout
		$BTPlayer.set_active(true)
		return

	# No item — just bounce
	$BTPlayer.set_active(false)
	set_behaviour_state("bounce")
	state_machine.travel(get_anim("bounce"))
	await get_tree().create_timer(2.0).timeout
	$BTPlayer.set_active(true)

func play_name_reaction():
	$BTPlayer.set_active(false)
	set_behaviour_state("love")
	state_machine.travel(get_anim("love"))
	await get_tree().create_timer(2.0).timeout
	$BTPlayer.set_active(true)
