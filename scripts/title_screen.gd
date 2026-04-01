extends Node2D

@onready var canvas = $CanvasLayer
@onready var canvas_container = $CanvasLayer/CenterContainer
@onready var press_any_key = $CanvasLayer/CenterContainer/VBoxContainer/AnimatedSprite2D
@onready var click_sound = $ClickSound

var can_start: bool = false
var canvas_rest_y: Vector2

func _ready():
	canvas.offset = Vector2(0, -300)
	canvas_container.modulate.a = 0.0  # ← changed
	press_any_key.modulate.a = 0.0
	press_any_key.stop()
	
	var tween = create_tween()
	tween.set_parallel(false)
	
	tween.tween_property(canvas_container, "modulate:a", 1.0, 0.3)  # ← changed
	tween.tween_property(canvas, "offset", Vector2(0, 0), 0.8)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)
	
	tween.tween_property(canvas, "offset", Vector2(0, -8), 0.08)
	tween.tween_property(canvas, "offset", Vector2(0, 0), 0.08)
	
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
	
	# Play the key press animation on the sprite sheet
	press_any_key.play("pressed") 
	
	# Wait for that animation to finish then transition
	await press_any_key.animation_finished
	
	# Fade everything out
	var tween = create_tween()
	tween.tween_property(canvas_container, "modulate:a", 0.0, 0.4) 
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://levels/game_level.tscn")
)
