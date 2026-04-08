extends CharacterBody2D

enum CHICKEN_STATE { IDLE, WALK, REST, PECK, FLEE, CARRIED, FLAPPING, SLEEPING }

@export var move_speed: float = 15
@export var flee_speed: float = 40.0
@export var mouse_flee_radius: float = 50.0
@export var player_flee_radius: float = 100.0
@export var favourite_spot: Vector2 = Vector2.ZERO
@export var get_down_duration: float = 1.8
@export var get_up_duration: float = 0.8

@onready var flap_sprite = $FlapSprite
@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var sprite = $Sprite2D
@onready var nav_agent = $NavigationAgent2D
@onready var pickup_area = $PickupArea

var water_layer: TileMapLayer
var current_state: CHICKEN_STATE = CHICKEN_STATE.IDLE
var is_sleeping: bool = false

func _ready():
	randomize()
	pickup_area.input_event.connect(_on_pickup_area_input)
	water_layer = get_tree().get_root().find_child("water", true, false)
	flap_sprite.visible = false
	await get_tree().process_frame
	if favourite_spot == Vector2.ZERO:
		favourite_spot = GameManager.get_random_spot()

func _physics_process(_delta):
	# Sleeping
	if current_state == CHICKEN_STATE.SLEEPING:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Flapping back to land
	if current_state == CHICKEN_STATE.FLAPPING:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var dir = (player.global_position - global_position).normalized()
			velocity = dir * flee_speed * 1.5
			move_and_slide()
		if not _is_over_water(global_position):
			_land_safely()
		return
	
	# Carried state
	if current_state == CHICKEN_STATE.CARRIED:
		global_position = get_global_mouse_position()
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_put_down()
		return
	
	# Everything else — LimboAI sets velocity
	move_and_slide()

func set_behaviour_state(state_name: String):
	match state_name:
		"idle": current_state = CHICKEN_STATE.IDLE
		"walk": current_state = CHICKEN_STATE.WALK
		"flee": current_state = CHICKEN_STATE.FLEE
		"rest": current_state = CHICKEN_STATE.REST
		"peck": current_state = CHICKEN_STATE.PECK

func get_anim(state_name: String) -> String:
	match state_name:
		"idle": return "idle"
		"walk": return "walk"
		"rest": return "rest"
		"peck": return "peck"
		_: return "idle"

func apply_night_happiness(slept_safely: bool, chickens_present: bool = false):
	pass  # implement if needed

func go_to_sleep():
	$BTPlayer.set_active(false)
	current_state = CHICKEN_STATE.SLEEPING
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
	current_state = CHICKEN_STATE.IDLE
	
	if exit_pos != Vector2.ZERO:
		nav_agent.target_position = exit_pos
		while global_position.distance_to(exit_pos) > 30.0:
			var next = nav_agent.get_next_path_position()
			velocity = (next - global_position).normalized() * move_speed
			move_and_slide()
			await get_tree().process_frame
	
	$BTPlayer.set_active(true)
	current_state = CHICKEN_STATE.IDLE
	
	# Immediately start walking toward favourite spot
	if favourite_spot != Vector2.ZERO:
		nav_agent.target_position = GameManager.get_arrival_position(favourite_spot)

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
	$BTPlayer.set_active(false)  # pause BT while carried
	current_state = CHICKEN_STATE.CARRIED
	$CollisionShape2D.disabled = true
	state_machine.travel("get_down")

func _put_down():
	var drop_pos = get_global_mouse_position()
	if _is_over_water(drop_pos):
		current_state = CHICKEN_STATE.FLAPPING
		$CollisionShape2D.disabled = true
		sprite.visible = false
		flap_sprite.visible = true
		flap_sprite.play("flap")
	else:
		$BTPlayer.set_active(true)  # resume BT on land
		current_state = CHICKEN_STATE.IDLE
		$CollisionShape2D.disabled = false
		state_machine.travel("idle")

func _land_safely():
	$BTPlayer.set_active(true)  # resume BT after landing
	current_state = CHICKEN_STATE.IDLE
	$CollisionShape2D.disabled = false
	flap_sprite.stop()
	flap_sprite.visible = false
	sprite.visible = true

func _is_over_water(world_pos: Vector2) -> bool:
	if water_layer == null:
		return false
	var tile_pos = water_layer.local_to_map(world_pos)
	return water_layer.get_cell_source_id(tile_pos) != -1
