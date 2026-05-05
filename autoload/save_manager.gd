extends Node

const SAVE_PATTERN = "user://savegames-%s.json"
var last_save = ""

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.is_action("quicksave"):
			save_game(Time.get_datetime_string_from_system())
		elif event.is_action("quickload"):
			load_game()

# Load most recent, or specified game
func load_game(name: String = ""):
	name = last_save if name == "" else name
	var file = FileAccess.open(name, FileAccess.READ)
	if file == null:
		print("ERROR: Could not open save file for reading")
		return
	var file_text = file.get_as_text()
	file.close()
	var save_game = JSON.parse_string(file_text)
	
	return

func save_game(name: String):
	name = name.replace(":", "_")
	var save_data = {
		"day_count": NightManager.day_count,
		#"player": _save_player(),
		#"cows": _save_all_cows(),
		#"babies": _save_all_babies(),
		#"chickens": _save_all_chickens(),
		#"chests": _save_all_chests(),
		#"items": _save_all_items(),
		#"inventory": _save_inventory(),
	}
	var fname = SAVE_PATTERN % name
	#ensure_save_path()
	var file = FileAccess.open(fname, FileAccess.WRITE)
	if file == null:
		print("ERROR: Could not open save file for writing")
		return
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	last_save = fname
	print("Game saved!")
	
#func ensure_save_path():
	#FileAccess.get_
