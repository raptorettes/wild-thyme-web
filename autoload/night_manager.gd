extends Node

# Tuning vars — lower for testing!
@export var days_happy_needed_for_birth: int = 1
@export var birth_happiness_threshold: float = 0.5
@export var baby_outside_herd_penalty: float = 0.15
@export var sleep_duration: float = 4.0

# State
var day_count: int = 1
var night_active: bool = false
var current_enclosure: Area2D = null
var last_enclosure: Area2D = null
var days_happy_tracker: Dictionary = {}

# Signals
signal night_started
signal morning_started(message: String, baby_born: bool, cow_grown_up: bool)

func _all_animals_sleeping() -> bool:
	var animals = get_tree().get_nodes_in_group("animals")
	for animal in animals:
		if not animal.is_sleeping:
			return false
	return true

func _wait_for_all_sleeping() -> void:
	while not _all_animals_sleeping():
		await get_tree().process_frame

func _wait_for_all_awake() -> void:
	while true:
		var animals = get_tree().get_nodes_in_group("animals")
		var all_awake = true
		for animal in animals:
			if animal.is_sleeping:
				all_awake = false
				break
		if all_awake:
			break
		await get_tree().process_frame

func trigger_night(enclosure: Area2D):
	if night_active:
		return
	if enclosure == null:
		return
	
	# Check if same enclosure as last night
	if enclosure == last_enclosure:
		DialogueBox.show_message(
			"The herd seems restless here tonight... maybe try another meadow?",
			"sad_talk",
			""
		)
		return
	
	current_enclosure = enclosure
	night_active = true
	
	emit_signal("night_started")
	
	var any_grown_up = false
	var all_cows = get_tree().get_nodes_in_group("cows")
	var all_babies = get_tree().get_nodes_in_group("baby")
	var all_animals = all_cows + all_babies
	
	var chickens_inside = _check_chickens_in_enclosure()
	
	var cows_inside = []
	var cows_outside = []
	var babies_inside = []
	var babies_outside = []
	
	for cow in all_cows:
		if cow.is_in_group("baby"):
			continue
		if cow.has_method("apply_night_happiness"):
			if _is_in_enclosure(cow):
				cows_inside.append(cow)
				cow.apply_night_happiness(true, chickens_inside)
				_track_happy_days(cow, true)
				cow.days_in_herd += 1
			else:
				cows_outside.append(cow)
				cow.apply_night_happiness(false, false)
				_track_happy_days(cow, false)
				cow.days_in_herd += 1
	
	for baby in all_babies:
		if _is_in_enclosure(baby):
			babies_inside.append(baby)
			baby.apply_night_happiness(true, chickens_inside)
		else:
			babies_outside.append(baby)
			baby.apply_night_happiness(false, false)
	
	# Baby outside penalty
	if babies_outside.size() > 0:
		for cow in all_cows:
			cow.happiness -= baby_outside_herd_penalty
			cow.happiness = clamp(cow.happiness, 0.0, 1.0)
			#cow._update_flee_radius()
	
	var herd_happiness = _get_herd_happiness(all_animals)
	var birth_cow = _check_for_birth(all_cows)
	
	var message = _build_morning_message(
		cows_inside.size(),
		cows_outside.size(),
		babies_outside.size(),
		chickens_inside,
		herd_happiness,
		birth_cow,
		any_grown_up
	)
	
	day_count += 1
	
	# PHASE 1 — start overlay and animals sleeping
	NightOverlay.start_fade_in()
	NightOverlay.play_crickets_and_music()
	
	var sleeping_animals = get_tree().get_nodes_in_group("animals")
	for animal in sleeping_animals:
		if animal.has_method("go_to_sleep"):
			animal.go_to_sleep()
	
	# PHASE 2 — wait for last animal to settle then hold
	await _wait_for_all_sleeping()

	# Check for babies growing up during night
	var grown_up_babies = _check_for_grown_up_babies()
	any_grown_up = grown_up_babies.size() > 0

	for baby in grown_up_babies:
		var b = baby
		baby.ready_to_grow_up.connect(_grow_up_cow, CONNECT_ONE_SHOT)
		baby.grow_up_sequence()

	if any_grown_up:
		await get_tree().create_timer(2.0).timeout

	await get_tree().create_timer(sleep_duration).timeout
	
	if birth_cow != null:
		_spawn_baby_cow(birth_cow)
	
	# PHASE 3 — fade out then wake animals
	NightOverlay.start_fade_out()
	await NightOverlay.night_sequence_finished
	
	# Get exit point BEFORE waking animals
	var exit_pos = Vector2.ZERO
	var exits = get_tree().get_nodes_in_group("enclosure_exit")
	for exit in exits:
		if exit.name == "EnclosureExit1" and current_enclosure.name == "Enclosure1":
			exit_pos = exit.global_position
		elif exit.name == "EnclosureExit2" and current_enclosure.name == "Enclosure2":
			exit_pos = exit.global_position
		elif exit.name == "EnclosureExit3" and current_enclosure.name == "Enclosure3":
			exit_pos = exit.global_position

	# Wake all animals with exit position
	# var cows = get_tree().root.find_children("*")
	
	var waking_animals = get_tree().get_nodes_in_group("animals")
	for animal in waking_animals:
		if animal.has_method("wake_up"):
			if _is_in_enclosure(animal):
			# Was inside — walk to exit
				var spread_exit = exit_pos + Vector2(
					randf_range(-70.0, 70.0),
					randf_range(-70.0, 70.0)
				)
				animal.wake_up(spread_exit)
			else:
				animal.wake_up()
	
	await _wait_for_all_awake()
	
	# Save last enclosure AFTER everything is done
	last_enclosure = current_enclosure
	emit_signal("morning_started", message, birth_cow != null, any_grown_up)
	night_active = false
	current_enclosure = null

func _is_in_enclosure(animal) -> bool:
	if current_enclosure == null:
		return false
	var bodies = current_enclosure.get_overlapping_bodies()
	return animal in bodies

func _check_chickens_in_enclosure() -> bool:
	if current_enclosure == null:
		return false
	var bodies = current_enclosure.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("chickens"):
			return true
	return false

func _check_for_grown_up_babies() -> Array:
	var grown = []
	var babies = get_tree().get_nodes_in_group("baby")
	for baby in babies:
		if baby.days_in_herd >= 2:
			grown.append(baby)
	return grown

var baby_cow_scenes: Array = [
	preload("res://characters/bb_cow.tscn"),
	#preload("res://characters/bb_cow_blue.tscn"),
	#preload("res://characters/bb_cow_green.tscn"),
	#preload("res://characters/bb_cow_pink.tscn"),
	##preload("res://characters/bb_cow_brown.tscn"),
	#preload("res://characters/bb_cow_yellow.tscn"),
]

func get_random_baby_scene() -> PackedScene:
	return baby_cow_scenes[randi() % baby_cow_scenes.size()]

func _grow_up_cow(baby) -> void:
	# Match adult color to baby color
	var adult_scene_path = "res://characters/cow_" + baby.color_variant + ".tscn"
	var adult_scene = load(adult_scene_path)
	if adult_scene == null:
		adult_scene = load("res://characters/cow.tscn")  # fallback to purple
	var adult = adult_scene.instantiate()
	adult.global_position = baby.global_position
	adult.happiness = baby.happiness
	adult.confidence = baby.confidence
	adult.days_in_herd = baby.days_in_herd
	adult.herd_cohesion = baby.herd_cohesion
	adult.skittishness = baby.skittishness
	adult.cow_name = baby.cow_name
	adult.favourite_spot = GameManager.get_random_spot()
	get_tree().current_scene.add_child(adult)
	baby.queue_free()

func _get_herd_happiness(all_animals: Array) -> float:
	if all_animals.is_empty():
		return 0.0
	var total = 0.0
	for animal in all_animals:
		total += animal.happiness
	return total / all_animals.size()

func _track_happy_days(cow, was_happy: bool):
	var cow_id = cow.get_instance_id()
	if not days_happy_tracker.has(cow_id):
		days_happy_tracker[cow_id] = 0
	if was_happy and cow.happiness >= birth_happiness_threshold:
		days_happy_tracker[cow_id] += 1
	else:
		days_happy_tracker[cow_id] = 0

func _check_for_birth(all_cows: Array):
	for cow in all_cows:
		if cow.is_in_group("baby"):
			continue
		# Also check birth_ready for star item
		if cow.get("birth_ready") != null and cow.birth_ready:
			cow.birth_ready = false
			return cow
		var cow_id = cow.get_instance_id()
		if days_happy_tracker.has(cow_id):
			if days_happy_tracker[cow_id] >= days_happy_needed_for_birth:
				days_happy_tracker[cow_id] = 0
				return cow
	return null

func _build_morning_message(inside: int, outside: int, babies_outside: int, chickens: bool, herd_happiness: float, birth_cow, cow_grown_up: bool) -> String:
	if cow_grown_up and birth_cow != null:
		return "A calf grew up and a new baby was born. The herd is growing!"
	if cow_grown_up:
		return "One of your calves has grown up overnight. The herd welcomes a new adult."
	if birth_cow != null:
		return "You wake up to a surprise — a baby was born in the night!"
	if babies_outside > 0:
		if babies_outside == 1:
			return "A baby was left outside last night. The herd spent the night calling to it, and are now a bit anxious and unsettled."
		else:
			return str(babies_outside) + " babies were left outside! The herd is beside themselves. Make sure the little ones get in tonight."
	if outside == 0 and not chickens:
		if herd_happiness > 0.8:
			return "Everyone had a great sleep. The herd seems genuinely happy this morning."
		else:
			return "Everyone made it in last night. The herd rested well together."
	elif outside == 0 and chickens:
		return "All the cows made it in, but some chickens snuck in too and caused a fuss. The cows are a little grumpy this morning."
	elif outside == 1:
		return "One cow was left outside last night. They look tired and a little worried this morning."
	elif outside <= 3:
		return str(outside) + " cows slept outside last night. The herd feels unsettled."
	else:
		return "Most of the herd was left outside. Everyone looks exhausted and unhappy. Try to get them all in tonight."

func _spawn_baby_cow(parent_cow):
	var baby_scene = load("res://characters/bb_cow.tscn")
	if baby_scene == null:
		return
	var baby = baby_scene.instantiate()
	baby.global_position = parent_cow.global_position + Vector2(
		randf_range(-20, 20),
		randf_range(-20, 20)
	)
	baby.confidence = randf_range(0.2, 0.9)
	baby.days_in_herd = 0
	baby.happiness = 0.7
	baby.herd_cohesion = 0.6
	get_tree().current_scene.add_child(baby)
	print("=== BABY COW BORN ===")
	print("position: ", baby.global_position)
	print("happiness: ", baby.happiness)
	print("herd_cohesion: ", baby.herd_cohesion)
	print("has BTPlayer: ", baby.has_node("BTPlayer"))
	print("BTPlayer active: ", baby.get_node("BTPlayer").active if baby.has_node("BTPlayer") else "NO BTPLAYER")
	print("groups: ", baby.get_groups())
	
	# Wait for full initialisation then swap texture
	await get_tree().process_frame
	await get_tree().process_frame
	var baby_textures = [
		load("res://assets/Animals/Cow_Baby/baby-cow-blue.png"),
		load("res://assets/Animals/Cow_Baby/baby-cow-green.png"),
		load("res://assets/Animals/Cow_Baby/baby-cow-pink.png"),
		load("res://assets/Animals/Cow_Baby/baby-cow-yellow.png"),
		load("res://assets/Animals/Cow_Baby/baby purple cow animations sprites.png"),
	]
	var tex = baby_textures[randi() % baby_textures.size()]
	baby.sprite.texture = tex
