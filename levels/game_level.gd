extends Node2D

@onready var pause_menu = $PauseMenu
@onready var enclosure = $Enclosure
@onready var night_trigger_area = $NightTriggerArea
@onready var gate_prompt = $GatePrompt
@onready var day_counter = $DayCounter/Label

func _ready():
	day_counter.text = "Day " + str(NightManager.day_count)
	gate_prompt.hide()
	NightManager.night_started.connect(_on_night_started)
	night_trigger_area.body_entered.connect(_on_gate_area_entered)
	night_trigger_area.body_exited.connect(_on_gate_area_exited)
	NightManager.register_enclosure($Enclosure)
	# listen for morning message
	NightManager.morning_started.connect(_on_morning_started)
	DialogueBox.message_shown.connect(_on_dialogue_shown)
	DialogueBox.message_dismissed.connect(_on_dialogue_dismissed)
	# Show opening sequence
	DialogueBox.show_sequence([
		{
			"text": "There is a wild herd of cows scattered across the meadow.",
			"expression": "talking",
			"emoji": ""
		},
		{
			"text": "As night falls, they'll need somewhere safe to rest together.",
			"expression": "love_talk",
			"emoji": ""
		},
		{
			"text": "Guide them toward the enclosure using your mouse.",
			"expression": "smiling",
			"emoji": ""
		},
		{
			"text": "When everyone's inside, press E to say goodnight.",
			"expression": "happy",
			"emoji": ""
		}
	])
	
func _on_dialogue_shown():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		#player.set_process_input(false) # disable player input
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
			if _player_near_gate():
				gate_prompt.hide()
				DialogueBox.show_message(
					"Everyone's settling in... Goodnight little ones.",
					"love",
					""
				)
				await DialogueBox.message_dismissed
				NightManager.trigger_night()

func _player_near_gate() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return false
	# Check if player is inside the night trigger area
	var bodies = night_trigger_area.get_overlapping_bodies()
	return player in bodies

func _on_gate_area_entered(body):
	print("body entered: ", body.name, " is player: ", body.is_in_group("player"))
	if body.is_in_group("player"):
		print("showing gate prompt")
		gate_prompt.show()


func _on_gate_area_exited(body):
	if body.is_in_group("player"):
		gate_prompt.hide()

func _on_bb_cow_found_cow() -> void:
	$TheLabels/TheLabel.text = "FOUND THE COW"
	$TheLabels/TheLabel.visible = true
