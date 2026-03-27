extends Node

enum CATEGORY { CHILL, LOFI, BEATS }

var current_category: CATEGORY = CATEGORY.CHILL
var current_track_index: int = 0
var is_playing: bool = false

var tracks = {
	CATEGORY.CHILL: [
		"res://assets/music/chill/chill-beam.mp3",
		"res://assets/music/chill/chill-wednesday.mp3",
		"res://assets/music/chill/chill-peace.mp3",
		"res://assets/music/chill/chill-universe.mp3",
		"res://assets/music/chill/chill-melody.mp3",
		"res://assets/music/chill/chill-guitar.mp3",
	],
	CATEGORY.LOFI: [
		"res://assets/music/lofi/lofi-trippy.mp3",
		"res://assets/music/lofi/lofi-sunny.mp3",
		"res://assets/music/lofi/lofi-guitar.mp3",
		"res://assets/music/lofi/lofi-sleeping.mp3",
		"res://assets/music/lofi/lofi-inn.mp3",
		"res://assets/music/lofi/lofi-sundown.mp3",
		"res://assets/music/lofi/lofi-adventure.mp3",
		"res://assets/music/lofi/lofi-jazzy.mp3",
		"res://assets/music/lofi/lofi-wind.mp3",
		"res://assets/music/lofi/lofi-journey.mp3",
	],
	CATEGORY.BEATS: [
		"res://assets/music/beats/beats-cosy.mp3",
		"res://assets/music/beats/beats-mountain.mp3",
		"res://assets/music/beats/beats-glider.mp3",
		"res://assets/music/beats/beats-shadow.mp3",
		"res://assets/music/beats/beats-doof.mp3",
	],
}

var player: AudioStreamPlayer

func _ready():
	player = AudioStreamPlayer.new()
	add_child(player)
	player.finished.connect(_on_audio_finished)
	# Start at a random track each time
	current_category = randi() % 3  # 0, 1, or 2 — matches your CATEGORY enum
	current_track_index = randi() % tracks[current_category].size()
	
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
