extends Node2D

@onready var banner = $TextureRect
@onready var press_any_key = $AnimatedSprite2D

var can_start: bool = false

var banner_rest_y: float
var press_key_rest_y: float

func _ready():
	# Remember where you placed them in the editor
	banner_rest_y = banner.position.y
	press_key_rest_y = press_any_key.position.y
	
	# Start banner above its resting position
	banner.position.y = banner_rest_y - 300.0
	banner.modulate.a = 0.0
	
	# Hide press any key
	press_any_key.modulate.a = 0.0
	press_any_key.stop()
	
	var tween = create_tween()
	tween.set_parallel(false)
	
	# Banner falls into its editor position
	tween.tween_property(banner, "modulate:a", 1.0, 0.3)
	tween.tween_property(banner, "position:y", banner_rest_y, 0.8)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)
	
	# Bounce settle
	tween.tween_property(banner, "position:y", banner_rest_y - 8.0, 0.08)
	tween.tween_property(banner, "position:y", banner_rest_y, 0.08)
	
	# Fade in press any key
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
	
	# Play the key press animation on the sprite sheet
	press_any_key.play("pressed") 
	
	# Wait for that animation to finish then transition
	await press_any_key.animation_finished
	
	# Fade everything out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://levels/game_level.tscn")
	)
