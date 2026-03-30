extends CanvasLayer

@onready var overlay = $ColorRect
@onready var cricket_sound = $CricketSound
@onready var moo_sound = $MooSound

# Tuning
@export var fade_in_duration: float = 2
@export var hold_duration: float = 3.0
@export var fade_out_duration: float = 2
@export var music_min_volume: float = -20.0 
@export var moo_volume_db: float = -8.0
# sound arrays
var cricket_sounds: Array = []
var moo_sounds: Array = []

signal night_sequence_finished

func _ready():
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		load("res://assets/music/sfx/cows1.mp3"),
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
	
	# Fade overlay in slowly
	tween.tween_property(overlay, "color:a", 0.85, fade_in_duration)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_SINE)
	
	# Crickets start as soon as it's dark
	tween.tween_callback(func():
		_play_random_cricket()
		_play_random_moo()
	)

	
	# Switch song while still dark
	tween.tween_interval(5.0)
	tween.tween_callback(func():
		MusicManager.next_track()
	)
	
	# Brief silence after track switch
	#tween.tween_interval(1.0)
	
	# Stop crickets cleanly before fading back
	tween.tween_callback(func():
		cricket_sound.stop()
	)
	
	# Fade overlay out
	tween.tween_property(overlay, "color:a", 0.0, fade_out_duration)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_SINE)
	
	# Clean up and signal finished
	tween.tween_callback(func():
		_fade_music_up()
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
	
	
