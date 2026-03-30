extends CanvasLayer

@onready var overlay = $ColorRect
@onready var cricket_sound = $CricketSound
@onready var moo_sound = $MooSound

@export var fade_in_duration: float = 2.0
@export var fade_out_duration: float = 2.0
@export var time_before_song_switch: float = 5.0
@export var music_min_volume: float = -80.0

var cricket_sounds: Array = []
var moo_sounds: Array = []

signal night_sequence_finished

func _ready():
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cricket_sounds = [
		load("res://assets/music/sfx/crickets-1.mp3"),
		load("res://assets/music/sfx/crickets-2.mp3"),
		load("res://assets/music/sfx/crickets-3.mp3"),
		load("res://assets/music/sfx/crickets-4.mp3"),
		load("res://assets/music/sfx/crickets-frogs.mp3"),
		load("res://assets/music/sfx/crickets-frogs-2.mp3")
	]
	moo_sounds = [
		load("res://assets/music/sfx/cows2.mp3"),
	]

func _play_random_cricket():
	cricket_sound.stream = cricket_sounds[randi() % cricket_sounds.size()]
	cricket_sound.play()

func _play_random_moo():
	moo_sound.stream = moo_sounds[randi() % moo_sounds.size()]
	moo_sound.play()

func start_fade_in():
	visible = true
	_fade_music_down()
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.85, fade_in_duration)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_SINE)

func play_crickets_and_music():
	_play_random_cricket()
	await get_tree().create_timer(2.0).timeout
	_play_random_moo()

func start_fade_out():
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, fade_out_duration)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_SINE)
	
	# Switch track and fade music up as overlay lifts
	tween.tween_callback(func():
		MusicManager.next_track()
		_fade_music_up()
		cricket_sound.stop()
		moo_sound.stop()
		visible = false
		emit_signal("night_sequence_finished")
	)

func _fade_music_down():
	var tween = create_tween()
	tween.tween_property(MusicManager.player, "volume_db", music_min_volume, fade_in_duration)

func _fade_music_up():
	var tween = create_tween()
	tween.tween_property(MusicManager.player, "volume_db", 0.0, fade_out_duration)
