extends CharacterBody2D

@export var move_speed: float = 100
@export var starting_direction: Vector2 = Vector2(0, 1)
@export var interact_distance: float = 35.0

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")

var facing_direction: Vector2 = Vector2(0, 1)

func _ready() -> void:
	update_anamation_parameters(starting_direction)

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
			_try_interact_with_cow()

func _try_interact_with_cow():
	print("trying to interact")
	var all_animals = get_tree().get_nodes_in_group("cows") + get_tree().get_nodes_in_group("baby")
	print("animals found: ", all_animals.size())
	var best_cow = null
	var best_score = -1.0
	
	for animal in all_animals:
		var to_animal = animal.global_position - global_position
		var dist = to_animal.length()
		print(animal.name, " dist: ", dist, " interact_distance: ", interact_distance)
		if dist > interact_distance:
			continue
		var dot = to_animal.normalized().dot(facing_direction.normalized())
		print(animal.name, " dot: ", dot)
		if dot > 0.3:
			if dot > best_score:
				best_score = dot
				best_cow = animal
	
	print("best cow: ", best_cow)
	if best_cow != null:
		MessageBox.show_cow_name(best_cow.cow_name, "happy")
	
	
	if best_cow != null:
		best_cow.receive_interaction()
		MessageBox.show_cow_name(best_cow.cow_name, "happy")

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
