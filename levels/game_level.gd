extends Node2D

@onready var pause_menu = $PauseMenu
@onready var enclosure1 : Area2D = $Enclosure1
@onready var enclosure2 : Area2D = $Enclosure2
@onready var enclosure3 : Area2D = $Enclosure3
@onready var night_trigger1 = $NightTriggerArea1
@onready var night_trigger2 = $NightTriggerArea2
@onready var night_trigger3 = $NightTriggerArea3


func _ready():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
		player.set_process_input(false)
	
	night_trigger1.body_entered.connect(_on_gate1_area_entered)
	night_trigger1.body_exited.connect(_on_gate1_area_exited)
	night_trigger2.body_entered.connect(_on_gate2_area_entered)
	night_trigger2.body_exited.connect(_on_gate2_area_exited)
	night_trigger3.body_entered.connect(_on_gate3_area_entered)
	night_trigger3.body_exited.connect(_on_gate3_area_exited)
	
	NightManager.night_started.connect(_start_night)
	
	NightManager.morning_started.connect(_start_morning)
	
	
	DialogueBox.show_sequence([
		{
			"text": "There is a wild herd of cows scattered across the meadow.",
			"expression": "talking",
			"emoji": ""
		},
		{
			"text": "As night falls, they'll need somewhere to rest together.",
			"expression": "love_talk",
			"emoji": ""
		},
		{
			"text": "Guide them toward their sleeping spot using your mouse.",
			"expression": "smiling",
			"emoji": ""
		},
		{
			"text": "When everyone's inside, press E to rest for the night.",
			"expression": "happy",
			"emoji": ""
		}
	])

func _start_night():
	$NightCamera.priority = 2

func _start_morning(message: String, baby_born: bool, cow_grown_up: bool):
	$NightCamera.priority = 0
	
func _on_gate1_area_entered(body):
	if body.is_in_group("player"):
		GatePrompt.show_prompt("Press E to rest for the night")

func _on_gate1_area_exited(body):
	if body.is_in_group("player"):
		GatePrompt.hide_prompt()

func _on_gate2_area_entered(body):
	if body.is_in_group("player"):
		GatePrompt.show_prompt("Press E to rest for the night")

func _on_gate2_area_exited(body):
	if body.is_in_group("player"):
		GatePrompt.hide_prompt()

func _on_gate3_area_entered(body):
	if body.is_in_group("player"):
		GatePrompt.show_prompt("Press E to rest for the night")

func _on_gate3_area_exited(body):
	if body.is_in_group("player"):
		GatePrompt.hide_prompt()

func _input(event):
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if pause_menu.visible:
				pause_menu.close()
			else:
				pause_menu.open()
		if event.keycode == KEY_E:
			if _player_in_area(night_trigger1):
				_rest_message("Everyone's settling down for the night...", $Enclosure1, $Enclosure1/CollisionShape2D)
			elif _player_in_area(night_trigger2):
				_rest_message("Everyone's settling down...", $Enclosure2, $Enclosure2/CollisionShape2D)
			elif _player_in_area(night_trigger3):
				_rest_message("Everyone's settling down for the night...", $Enclosure3, $Enclosure3/CollisionShape2D)
				
func _rest_message(message: String, node: Area2D, focusNode: CollisionShape2D):
	GatePrompt.hide_prompt()
	DialogueBox.show_message(
		message,
		"love", ""
	)
	await DialogueBox.message_dismissed
	$NightCamera.follow_target = focusNode
	NightManager.trigger_night(node)

func _player_in_area(area: Area2D) -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return false
	return player in area.get_overlapping_bodies()

func _on_bb_cow_found_cow() -> void:
	$TheLabels/TheLabel.text = "FOUND THE COW"
	$TheLabels/TheLabel.visible = true
