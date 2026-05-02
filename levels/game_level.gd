extends Node2D

@onready var pause_menu = $PauseMenu
@onready var enclosure1 = $Enclosure1
@onready var enclosure2 = $Enclosure2
@onready var enclosure3 = $Enclosure3
@onready var night_trigger1 = $NightTriggerArea1
@onready var night_trigger2 = $NightTriggerArea2
@onready var night_trigger3 = $NightTriggerArea3

const maxZoom = Vector2(8, 8)
const minZoom = Vector2(2, 2)
const zoomStep = Vector2(0.25, 0.25)

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
	#if event.is_action("ui_page_up") and $Camera2D.zoom < maxZoom:
		#$Camera2D.zoom += zoomStep
	#if event.is_action("ui_page_down") and $Camera2D.zoom > minZoom:
		#$Camera2D.zoom -= zoomStep
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if pause_menu.visible:
				pause_menu.close()
			else:
				pause_menu.open()
		if event.keycode == KEY_E:
			if _player_near_gate1():
				GatePrompt.hide_prompt()
				DialogueBox.show_message(
					"Everyone's settling down for the night...",
					"love", ""
				)
				await DialogueBox.message_dismissed
				NightManager.trigger_night(enclosure1)
			elif _player_near_gate2():
				GatePrompt.hide_prompt()
				DialogueBox.show_message(
					"Everyone's settling down...",
					"love", ""
				)
				await DialogueBox.message_dismissed
				NightManager.trigger_night(enclosure2)
			elif _player_near_gate3():
				GatePrompt.hide_prompt()
				DialogueBox.show_message(
					"Everyone's settling down for the night...",
					"love", ""
				)
				await DialogueBox.message_dismissed
				NightManager.trigger_night(enclosure3)

func _player_near_gate1() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return false
	return player in night_trigger1.get_overlapping_bodies()

func _player_near_gate2() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return false
	return player in night_trigger2.get_overlapping_bodies()

func _player_near_gate3() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return false
	return player in night_trigger3.get_overlapping_bodies()

func _on_bb_cow_found_cow() -> void:
	$TheLabels/TheLabel.text = "FOUND THE COW"
	$TheLabels/TheLabel.visible = true
