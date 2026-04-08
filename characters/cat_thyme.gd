extends CharacterBody2D

@export var move_speed : float = 100
@export var starting_direction : Vector2 = Vector2(0, 1)

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")

func _ready() -> void:
	update_anamation_parameters(starting_direction)

func _physics_process(_delta):
	# Get input direction
	var input_direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
		
	update_anamation_parameters(input_direction)
		# Update Velocity
	velocity = input_direction * move_speed
	
	# Move and slide
	move_and_slide()
	
	pick_new_state()


func update_anamation_parameters(move_input : Vector2):
	# dont change animation parameters if there is no move input 
	if(move_input != Vector2.ZERO):
		animation_tree.set('parameters/Walk/blend_position', move_input)
		animation_tree.set('parameters/Idle/blend_position', move_input)
		

# Choose state based on what is happening with the player
func pick_new_state():
	if(velocity != Vector2.ZERO):
		state_machine.travel("Walk")
	else:
		state_machine.travel("Idle")
