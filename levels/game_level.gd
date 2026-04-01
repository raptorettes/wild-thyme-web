extends Node2D

@onready var title_screen = $TitleScreen 
@onready var pause_menu = $PauseMenu
@onready var enclosure1 = $Enclosure1
@onready var enclosure2 = $Enclosure2
@onready var night_trigger1 = $NightTriggerArea1
@onready var night_trigger2 = $NightTriggerArea2
@onready var gate_prompt1 = $GatePrompt1
@onready var gate_prompt2 = $GatePrompt2
@onready var day_counter = $DayCounter/Control/Label

func _ready():
	day_counter.text = str(NightManager.day_count)
	gate_prompt1.hide()
	gate_prompt2.hide()
	NightManager.night_started.connect(_on_night_started)
	night_trigger1.body_entered.connect(_on_gate1_area_entered)
	night_trigger1.body_exited.connect(_on_gate1_area_exited)
	night_trigger2.body_entered.connect(_on_gate2_area_entered)
	night_trigger2.body_exited.connect(_on_gate2_area_exited)
	NightManager.morning_started.connect(_on_morning_started)
	DialogueBox.message_shown.connect(_on_dialogue_shown)
	DialogueBox.message_dismissed.connect(_on_dialogue_dismissed)

func _on_gate1_area_entered(body):
	if body.is_in_group("player"):
		gate_prompt1.show()

func _on_gate1_area_exited(body):
	if body.is_in_group("player"):
		gate_prompt1.hide()

func _on_gate2_area_entered(body):
	if body.is_in_group("player"):
		gate_prompt2.show()

func _on_gate2_area_exited(body):
	if body.is_in_group("player"):
		gate_prompt2.hide()

	
func _on_dialogue_shown():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_process_input(false) # disable player input
		player.set_physics_process(false) # stop player moving

func _on_dialogue_dismissed():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_process_input(true) # re-enable
		player.set_physics_process(true)

func _on_night_started():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
		player.set_process_input(false)
	
func _on_morning_started(message: String, baby_born: bool):
	day_counter.text = "Day " + str(NightManager.day_count)
	# Re-enable player at morning
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(true)
		player.set_process_input(true)
	var expression = "smiling"
	var emoji = "day"
	
	if baby_born:
		expression = "love_talk"    # excited and warm
		emoji = "cow"
	elif message.contains("outside") or message.contains("tired"):
		expression = "sad_talk"     # genuinely sad news
		emoji = "night"
	elif message.contains("chicken"):
		expression = "angry"           # chickens!! 
		emoji = "chicken"
	elif message.contains("beautiful") or message.contains("genuinely happy"):
		expression = "super-excited"   # best possible night
		emoji = "day"
	else:
		expression = "talking"         # neutral news
		emoji = "day"
	
	DialogueBox.show_sequence([
		{
			"text": "Good morning! Lets see how everyone's doing.",
			"expression": "happy",
		},
		{
			"text": message,
			"expression": expression,
		}
	])
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if pause_menu.visible:
				pause_menu.close()
			else:
				pause_menu.open()
		if event.keycode == KEY_E:
			if _player_near_gate1():
				gate_prompt1.hide()
				DialogueBox.show_message(
					"Everyone's settling in... Goodnight little ones.",
					"love",
					""
				)
				await DialogueBox.message_dismissed
				NightManager.trigger_night(enclosure1)
			elif _player_near_gate2():
				gate_prompt2.hide()
				DialogueBox.show_message(
					"Everyone's settling in... Goodnight little ones.",
					"love",
					""
				)
				await DialogueBox.message_dismissed
				NightManager.trigger_night(enclosure2)

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


func _on_bb_cow_found_cow() -> void:
	$TheLabels/TheLabel.text = "FOUND THE COW"
	$TheLabels/TheLabel.visible = true
