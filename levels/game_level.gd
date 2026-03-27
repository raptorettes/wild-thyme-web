extends Node2D

@onready var pause_menu = $PauseMenu
@onready var enclosure = $Enclosure
@onready var night_trigger_area = $NightTriggerArea

func _ready():
	NightManager.register_enclosure($Enclosure)
	
	# listen for morning message
	NightManager.morning_started.connect(_on_morning_started)
	NightManager.night_started.connect(_on_night_started)
	
func _on_night_started():
	# add visual overlay later
	print("you're all turning in for the night")
	
func _on_morning_started(message: String, baby_born: bool):
	# display this in UI panel later
	print("Morning message: ", message)
	if baby_born:
		print("A babby!")
	
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if pause_menu.visible:
				pause_menu.close()
			else:
				pause_menu.open()
		if event.keycode == KEY_E:
			print("E pressed!")  # temporary test
			if _player_near_gate():
				print("Player near gate!")
				NightManager.trigger_night()
		if event.keycode == KEY_F:
			var mouse_pos = get_global_mouse_position()
			var water = get_tree().get_root().find_child("water", true, false)
			if water:
				var tile_pos = water.local_to_map(mouse_pos)
				var cell = water.get_cell_source_id(tile_pos)
				print("tile: ", tile_pos, " id: ", cell)
func _player_near_gate() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return false
	# Check if player is inside the night trigger area
	var bodies = night_trigger_area.get_overlapping_bodies()
	return player in bodies


func _on_bb_cow_found_cow() -> void:
	$TheLabels/TheLabel.text = "FOUND THE COW"
	$TheLabels/TheLabel.visible = true
