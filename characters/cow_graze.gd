extends CharacterBody2D

enum COW_STATE { IDLE, WALK, REST, GRAZE, CHEW, LOVE, FLEE, SLEEPING }

@export var move_speed: float = 20
@export var flee_speed: float = 35.0
@export var mouse_flee_radius: float = 40.0
@export var player_flee_radius: float = 70.0
@export var happiness: float = 0.5
@export var happiness_gain_per_night: float = 0.3
@export var happiness_loss_per_night: float = 0.08
@export var happiness_chicken_penalty: float = 0.05
@export var favourite_spot: Vector2 = Vector2.ZERO
@export var get_down_duration: float = 0.6
@export var get_up_duration: float = 0.8
@export var skittishness: float = 0.0  # 0=very calm, 1=very skittish
@export var days_in_herd: int = 0
@export var confidence: float = 0.5
@export var herd_cohesion: float = 0.0
@export var is_wanderer: bool = false
@export var cow_name: String = ""

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var sprite = $Sprite2D
@onready var nav_agent = $NavigationAgent2D

var current_state: COW_STATE = COW_STATE.IDLE
var is_sleeping: bool = false
var birth_ready: bool = false

func _ready():
	randomize()
	await get_tree().process_frame
	if favourite_spot == Vector2.ZERO:
		favourite_spot = GameManager.get_random_spot()
	if cow_name == "":
		cow_name = GameManager.get_cow_name()
	## Apply random hue
	#var mat = sprite.material as ShaderMaterial
	#if mat:
		##mat.set_shader_parameter("hue_shift", randf())
		#mat.set_shader_parameter("saturation", happiness)


func _physics_process(_delta):
	# Sleeping — do nothing else
	if current_state == COW_STATE.SLEEPING:
		velocity = Vector2.ZERO
		move_and_slide()
		return 
	
	var is_stationary = current_state == COW_STATE.REST or \
		current_state == COW_STATE.GRAZE or \
		current_state == COW_STATE.CHEW or \
		current_state == COW_STATE.IDLE or \
		current_state == COW_STATE.LOVE
	
	if is_stationary:
		velocity = Vector2.ZERO
	
	# Player avoidance — not during flee
	if current_state != COW_STATE.FLEE:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var dist_to_player = global_position.distance_to(player.global_position)
			if dist_to_player < 25.0:
				var push_away = (global_position - player.global_position).normalized()
				var push_strength = 1.0 - (dist_to_player / 25.0)
				if is_stationary:
					velocity += push_away * push_strength * 5.0
				else:
					velocity = velocity.lerp(push_away * push_strength * 1.0, 0.3)
	
	move_and_slide()

func set_behaviour_state(state_name: String):
	match state_name:
		"idle": current_state = COW_STATE.IDLE
		"walk": current_state = COW_STATE.WALK
		"flee": current_state = COW_STATE.FLEE
		"graze": current_state = COW_STATE.GRAZE
		"rest": current_state = COW_STATE.REST
		"chew": current_state = COW_STATE.CHEW
		"love": current_state = COW_STATE.LOVE

func get_anim(state_name: String) -> String:
	match state_name:
		"idle": return "idle_right"
		"walk": return "walk_right"
		"graze": return "graze_right"
		"rest": return "rest"
		"chew": return "chew"
		"love": return "love"
		"bounce": return "bounce"
		_: return "idle_right"

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
	var delay = randf_range(0.5, 8.0)
	await get_tree().create_timer(delay).timeout
	state_machine.travel("get_up")
	await get_tree().create_timer(get_up_duration).timeout
	current_state = COW_STATE.IDLE
	
	# Use nav agent to walk to exit then favourite spot
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
	
		# Moved to limbo AI 
		#if favourite_spot != Vector2.ZERO:
		#var arrival = GameManager.get_arrival_position(favourite_spot)
		#nav_agent.target_position = arrival
		#while global_position.distance_to(arrival) > 30.0:
			#var next = nav_agent.get_next_path_position()
			#velocity = (next - global_position).normalized() * move_speed
			#move_and_slide()
			#await get_tree().process_frame
	
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

func receive_interaction():
	if Inventory.is_holding("star"):
		birth_ready = true
		Inventory.use_item()
		DialogueBox.show_message(
			"The cow nuzzles the star gently...",
			"love", ""
		)
		return
	
	if not Inventory.is_empty():
		happiness += Inventory.held_happiness_boost
		happiness = clamp(happiness, 0.0, 1.0)
		_update_flee_radius()
		var mat = sprite.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("saturation", happiness)
		Inventory.use_item()
		set_behaviour_state("love")
		state_machine.travel(get_anim("love"))
		$BTPlayer.set_active(false)
		await get_tree().create_timer(2.0).timeout
		$BTPlayer.set_active(true)
		return
	
	# No item — just show name
	$BTPlayer.set_active(false)
	set_behaviour_state("love")
	state_machine.travel(get_anim("love"))
	await get_tree().create_timer(2.0).timeout
	$BTPlayer.set_active(true)

func play_name_reaction():
	$BTPlayer.set_active(false)
	set_behaviour_state("love")
	state_machine.travel(get_anim("love"))
	await get_tree().create_timer(2.0).timeout
	$BTPlayer.set_active(true)
