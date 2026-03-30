extends CanvasLayer

@onready var overlay = $ColorRect
@onready var cricket_sound = $CricketSound
@onready var moo_sound = $MooSound

# Tuning
@export var fade_in_duration: float = 1.5
@export var hold_duration: float = 3.0
@export var fade_out_duration: float = 1.5
@export var music_min_volume: float = -20.0

# sound arrays
var cricket_sounds: Array = []
var moo_sounds: Array = []

signal night_sequence_finished

func _ready():
	# Load cricket sounds
	cricket_sounds = [
		load("res://assets/music/sfx/crickets-1.mp3"),
		load("res://assets/music/sfx/crickets-2.mp3"),
		load("res://assets/music/sfx/crickets-3.mp3"),
		load("res://assets/music/sfx/crickets-4.mp3"),
		load("res://assets/music/sfx/crickets-frogs.mp3"),
		load("res://assets/music/sfx/crickets-frogs-2.mp3")
	]
	
	# load cow sounds
	moo_sounds = [
		load("res://assets/music/sfx/cows-1.mp3"),
		load("res://assets/music/sfx/cows-2.mp3")
	]
	
func _play_random_cricket():
	cricket_sound.stream = cricket_sounds[randi() % cricket_sounds.size()]
	cricket_sound.play()
	
func _play_random_moo():
	moo_sound.stream = moo_sounds[randi() % moo_sounds.size()]
	moo_sound.play()	
	
func play_night_sequence():
	visible = true
	
	_fade_music_down()
	var tween = create_tween()
	tween.set_parallel(false)
	
	# fade overlay in 
	tween.tween_property(overlay, "color:a", 0.85, fade_in_duration)\
	.set_ease(Tween.EASE_IN)\
	.set_trans(Tween.TRANS_SINE)

	# play random sounds once dark
	tween.tween_callback(func():
		_play_random_cricket()
		await get_tree().create_timer(1.0).timeout
		_play_random_moo()
		await get_tree().create_timer(0.8).timeout
	)	
	
	# hold in darkness
	tween.tween_interval(hold_duration)
	
	# fade overlay out 
	tween.tween_property(overlay, "color:a", 0.0, fade_out_duration)\
	.set_ease(Tween.EASE_OUT)\
	.set_trans(Tween.TRANS_SINE)
	
	# clean up and signal finished
	tween.tween_callback(func():
		_fade_music_up()
		cricket_sound.stop()
		visible = false
		emit_signal("night_sequence_finished")
		)
	
func _fade_music_down():
	var tween = create_tween()
	tween.tween_property(
		MusicManager.player,
		"volume_db",
		music_min_volume,
		fade_in_duration
	)

func _fade_music_up():
	var tween = create_tween()
	tween.tween_property(
		MusicManager.player,
		"volume_db",
		0.0,
		fade_out_duration
	)
	
	
