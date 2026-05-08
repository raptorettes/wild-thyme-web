extends Node

var herding_cursor = preload("res://assets/UI/Sprite sheets/Mouse sprites/catpaw_mouse_big.png")
var default_cursor = preload("res://assets/UI/Sprite sheets/Mouse sprites/catpaw_pointing_big.png")
var is_herding_cursor: bool = false

func _ready():
	Input.set_custom_mouse_cursor(default_cursor, Input.CURSOR_ARROW, Vector2(24, 0))

func _process(_delta):
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		_set_default_cursor()
		return
	
	var mouse_pos = player.world_mouse_pos
	var all_animals = []
	all_animals.append_array(get_tree().get_nodes_in_group("cows"))
	all_animals.append_array(get_tree().get_nodes_in_group("baby"))
	all_animals.append_array(get_tree().get_nodes_in_group("chickens"))
	
	for animal in all_animals:
		if animal.get("player_flee_radius") == null:
			continue
		if animal.get("mouse_flee_radius") == null:
			continue

		var dist_to_player = animal.global_position.distance_to(player.global_position)
		var dist_to_mouse = animal.global_position.distance_to(mouse_pos)
		if dist_to_player > animal.player_flee_radius:
			continue

		if dist_to_mouse < animal.mouse_flee_radius:
			_set_herding_cursor()
		return

	_set_default_cursor()

func _set_herding_cursor():
	if not is_herding_cursor:
		is_herding_cursor = true
		Input.set_custom_mouse_cursor(herding_cursor, Input.CURSOR_ARROW, Vector2(24, 24))

func _set_default_cursor():
	if is_herding_cursor:
		is_herding_cursor = false
		Input.set_custom_mouse_cursor(default_cursor, Input.CURSOR_ARROW, Vector2(24, 0))
