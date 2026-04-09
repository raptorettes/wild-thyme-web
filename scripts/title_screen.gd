extends CanvasLayer

@onready var canvas_container = $CenterContainer
@onready var press_any_key = $CenterContainer/VBoxContainer/AnimatedSprite2D
@onready var click_sound = $ClickSound

var can_start: bool = false
var rest_y: float

func _ready():
	rest_y = canvas_container.position.y
	canvas_container.position.y = rest_y - 300.0
	canvas_container.modulate.a = 0.0
	press_any_key.modulate.a = 0.0
	press_any_key.stop()
	
	var tween = create_tween()
	tween.set_parallel(false)
	
	tween.tween_property(canvas_container, "modulate:a", 1.0, 0.3)
	tween.tween_property(canvas_container, "position:y", rest_y, 0.8)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)
	
	tween.tween_property(canvas_container, "position:y", rest_y - 8.0, 0.08)
	tween.tween_property(canvas_container, "position:y", rest_y, 0.08)
	
	tween.tween_interval(0.2)
	tween.tween_property(press_any_key, "modulate:a", 1.0, 0.5)
	
	tween.tween_callback(func(): can_start = true)

func _input(event):
	if not can_start:
		return
	if event is InputEventKey and event.pressed:
		_start_game()
	elif event is InputEventMouseButton and event.pressed:
		_start_game()

func _start_game():
	can_start = false
	click_sound.play()
	press_any_key.play("pressed")
	await press_any_key.animation_finished
	
	var tween = create_tween()
	tween.tween_property(canvas_container, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func():
		visible = false
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
			"text": "Guide them toward their resting spot using your mouse.",
			"expression": "smiling",
			"emoji": ""
		},
		{
			"text": "When everyone's inside, press E to say goodnight.",
			"expression": "happy",
			"emoji": ""
		}
	])
		# Enable player
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.set_physics_process(true)
			player.set_process_input(true)
)
