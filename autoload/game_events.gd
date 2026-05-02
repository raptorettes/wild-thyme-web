extends Node

func _ready():
	NightManager.morning_started.connect(_on_morning_started)

func _on_morning_started(message: String, baby_born: bool, cow_grown_up: bool):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(true)
		player.set_process_input(true)
	
	var expression = "talking"
	var emoji = "day"
	
	if cow_grown_up:
		expression = "super_excited"
		emoji = "cow"
	elif baby_born:
		expression = "love_talk"
		emoji = "cow"
	elif message.contains("outside") or message.contains("tired"):
		expression = "sad_talk"
		emoji = "night"
	elif message.contains("chicken"):
		expression = "angry"
		emoji = "chicken"
	elif message.contains("beautiful") or message.contains("genuinely happy"):
		expression = "super_excited"
		emoji = "day"
	else:
		expression = "talking"
		emoji = "day"
	
	DialogueBox.show_sequence([
		{
			"text": "Good morning! Let's see how everyone's doing.",
			"expression": "happy",
			"emoji": "day"
		},
		{
			"text": message,
			"expression": expression,
			"emoji": emoji
		}
	])
