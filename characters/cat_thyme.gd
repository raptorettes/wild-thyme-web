extends CharacterBody2D

@export var move_speed: float = 100
@export var starting_direction: Vector2 = Vector2(0, 1)
@export var interact_distance: float = 35.0

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")

var facing_direction: Vector2 = Vector2(0, 1)
var world_mouse_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	update_anamation_parameters(starting_direction)
	NightManager.night_started.connect(_on_night_started)
	NightManager.morning_started.connect(_on_morning_started)
	DialogueBox.message_shown.connect(_on_dialogue_shown)
	DialogueBox.message_dismissed.connect(_on_dialogue_dismissed)

func _process(_delta):
	var new_mouse = get_global_mouse_position()
	world_mouse_pos = new_mouse

func _physics_process(_delta):
	var input_direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	update_anamation_parameters(input_direction)
	velocity = input_direction * move_speed
	move_and_slide()
	pick_new_state()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F:
			_try_interact()

func _try_interact():
	# Find best interactable in facing direction
	var best_target = null
	var best_score = -1.0
	
	# Check all interactables — cows, chests, items
	var all_targets = []
	all_targets.append_array(get_tree().get_nodes_in_group("cows"))
	all_targets.append_array(get_tree().get_nodes_in_group("baby"))
	all_targets.append_array(get_tree().get_nodes_in_group("chest"))
	all_targets.append_array(get_tree().get_nodes_in_group("pickup_item"))
	
	for target in all_targets:
		var to_target = target.global_position - global_position
		var dist = to_target.length()
		if dist > interact_distance:
			continue
		var dot = to_target.normalized().dot(facing_direction.normalized())
		if dot > 0.3:
			if dot > best_score:
				best_score = dot
				best_target = target
	
	if best_target == null:
		return
	
	# Handle based on what we're facing
	if best_target.is_in_group("cows") or best_target.is_in_group("baby"):
		if Inventory.is_empty():
			MessageBox.show_cow_name(best_target.cow_name, "happy")
			best_target.play_name_reaction()
		else:
			best_target.receive_interaction()
	elif best_target.is_in_group("chest"):
		best_target.interact()
	elif best_target.is_in_group("pickup_item"):
		best_target.interact()

func update_anamation_parameters(move_input: Vector2):
	if move_input != Vector2.ZERO:
		facing_direction = move_input
		animation_tree.set('parameters/Walk/blend_position', move_input)
		animation_tree.set('parameters/Idle/blend_position', move_input)

func pick_new_state():
	if velocity != Vector2.ZERO:
		state_machine.travel("Walk")
	else:
		state_machine.travel("Idle")

func _on_dialogue_shown():
	print("dialogue shown — disabling player")
	set_physics_process(false)
	set_process_input(false)

func _on_dialogue_dismissed():
	print("dialogue dismissed — enabling player")
	set_physics_process(true)
	set_process_input(true)

func _on_night_started():
	print("NIGHT STARTED - world_mouse_pos: ", world_mouse_pos)
	set_physics_process(false)
	set_process_input(false)

func _on_morning_started(message: String, baby_born: bool, cow_grown_up: bool):
	print("MORNING STARTED - world_mouse_pos: ", world_mouse_pos)
	set_physics_process(true)
	set_process_input(true)
