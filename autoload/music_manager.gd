extends Node

enum CATEGORY { CHILL, LOFI, BEATS }

var current_category: CATEGORY = CATEGORY.CHILL
var current_track_index: int = 0
var is_playing: bool = false

var tracks = {
	CATEGORY.CHILL: [
		"res://assets/music/chill/chill-beam.ogg",
		"res://assets/music/chill/chill-wednesday.ogg",
		"res://assets/music/chill/chill-peace.ogg",
		"res://assets/music/chill/chill-universe.ogg",
		"res://assets/music/chill/chill-melody.ogg",
	],
	CATEGORY.LOFI: [
		"res://assets/music/lofi/lofi-trippy.ogg",
		"res://assets/music/lofi/lofi-sunny.ogg",
		"res://assets/music/lofi/lofi-guitar.ogg",
		"res://assets/music/lofi/lofi-sleeping.ogg",
		"res://assets/music/lofi/lofi-inn.ogg",
		"res://assets/music/lofi/lofi-sundown.ogg",
		"res://assets/music/lofi/lofi-adventure.ogg",
		"res://assets/music/lofi/lofi-jazzy.ogg",
		"res://assets/music/lofi/lofi-wind.ogg",
		"res://assets/music/lofi/lofi-journey.ogg",
	],
	CATEGORY.BEATS: [
		"res://assets/music/beats/beats-cosy.ogg",
		"res://assets/music/beats/beats-mountain.ogg",
		"res://assets/music/beats/beats-glider.ogg",
		"res://assets/music/beats/beats-shadow.ogg",
		"res://assets/music/beats/beats-doof.ogg",
	],
}

var player: AudioStreamPlayer

func _ready():
	player = AudioStreamPlayer.new()
	add_child(player)
	player.finished.connect(_on_audio_finished)
	# Start with one specific chill track
	current_category = CATEGORY.CHILL
	current_track_index = 3  # chill-beam.ogg
	play_current_track()

func play_current_track():
	var track_list = tracks[current_category]
	if track_list.is_empty():
		return
	var path = track_list[current_track_index]
	print("Trying to load: ", path) 
	var stream = load(path)
	if stream:
		print("Loaded successfully!")
		stream.loop = true
		player.stream = stream
		player.play()
		is_playing = true
	else:
		print("FAILED to load music at: ", path)
		
func next_track():
	var track_list = tracks[current_category]
	current_track_index = (current_track_index + 1) % track_list.size()
	play_current_track()

func set_category(category: CATEGORY):
	if category == current_category:
		return
	current_category = category
	current_track_index = 0
	play_current_track()

func _on_audio_finished():
	pass
