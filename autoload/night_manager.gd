extends Node

# Tuning vars — lower for testing!
@export var days_happy_needed_for_birth: int = 3
@export var birth_happiness_threshold: float = 0.75
@export var baby_outside_herd_penalty: float = 0.15
@export var sleep_duration: float = 5.0

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

# State
var day_count: int = 1
var night_active: bool = false
var enclosure: Area2D = null
var days_happy_tracker: Dictionary = {}

# Signal so the game level can react to night/morning events
signal night_started
signal morning_started(message: String, baby_born: bool)

func register_enclosure(area: Area2D):
	enclosure = area
	print("NightManager: enclosure registered — ", area.name)

func _all_animals_sleeping() -> bool:
	var animals = get_tree().get_nodes_in_group("animals")
	for animal in animals:
		if not animal.is_sleeping:
			return false
	return true

func _wait_for_all_sleeping() -> void:
	var animals = get_tree().get_nodes_in_group("animals")
	print("waiting for ", animals.size(), " animals to sleep")
	while not _all_animals_sleeping():
		await get_tree().process_frame
	print("all animals sleeping!")

func trigger_night():
	if night_active:
		return
	if enclosure == null:
		return
	
	night_active = true
	emit_signal("night_started")
	print("--- Night ", day_count, " ---")
	
	var all_cows = get_tree().get_nodes_in_group("cows")
	var all_babies = get_tree().get_nodes_in_group("baby")
	var all_animals = all_cows + all_babies
	
	var chickens_inside = _check_chickens_in_enclosure()
	
	var cows_inside = []
	var cows_outside = []
	var babies_inside = []
	var babies_outside = []
	
	for cow in all_cows:
		print("Checking cow: ", cow.name, " script: ", cow.get_script())
		if cow.is_in_group("baby"):
			continue # babies handled separately
		if cow.has_method("apply_night_happiness"):
			cow.apply_night_happiness(true, chickens_inside)
			_track_happy_days(cow, true)
		else:
			print("MISSING apply_night_happiness on: ", cow.name)
		if _is_in_enclosure(cow):
			cows_inside.append(cow)
		else:
			cows_outside.append(cow)
	
	for baby in all_babies:
		if _is_in_enclosure(baby):
			babies_inside.append(baby)
		else:
			babies_outside.append(baby)
	
	print("Cows inside: ", cows_inside.size(), " outside: ", cows_outside.size())
	print("Babies inside: ", babies_inside.size(), " outside: ", babies_outside.size())
	print("Chickens inside: ", chickens_inside)
	
	# Apply happiness to adult cows
	for cow in cows_inside:
		cow.apply_night_happiness(true, chickens_inside)
		_track_happy_days(cow, true)
	for cow in cows_outside:
		cow.apply_night_happiness(false, false)
		_track_happy_days(cow, false)
	
	# Apply happiness to baby cows
	for baby in babies_inside:
		baby.apply_night_happiness(true, chickens_inside)
	for baby in babies_outside:
		baby.apply_night_happiness(false, false)
	
	# Big herd penalty if any babies left outside
	if babies_outside.size() > 0:
		print("Baby cows left outside! Herd is distressed!")
		for cow in all_cows:
			cow.happiness -= baby_outside_herd_penalty
			cow.happiness = clamp(cow.happiness, 0.0, 1.0)
			cow._update_flee_radius()
	
	# Calculate herd happiness
	var herd_happiness = _get_herd_happiness(all_animals)
	print("Herd happiness average: ", herd_happiness)
	
	# Check for births
	var birth_cow = _check_for_birth(all_cows)
	
	# Build morning message
	var message = _build_morning_message(
		cows_inside.size(),
		cows_outside.size(),
		babies_outside.size(),
		chickens_inside,
		herd_happiness,
		birth_cow
	)
	
	# Spawn baby if birth happened
	if birth_cow != null:
		_spawn_baby_cow(birth_cow)
	
	day_count += 1
	
	# PHASE 1 — start overlay and animals simultaneously
	NightOverlay.start_fade_in()
	NightOverlay.play_crickets_and_music()
	
	var sleeping_animals = get_tree().get_nodes_in_group("animals")
	for animal in sleeping_animals:
		if animal.has_method("go_to_sleep"):
			animal.go_to_sleep()
	
# PHASE 2 — wait for last animal to settle then hold
	await _wait_for_all_sleeping()
	await get_tree().create_timer(sleep_duration).timeout
	
	# PHASE 3 — fade out first, THEN wake animals
	NightOverlay.start_fade_out()
	await NightOverlay.night_sequence_finished  # wait for overlay to fully lift
	
	# NOW wake everyone up
	for animal in sleeping_animals:
		if animal.has_method("wake_up"):
			animal.wake_up()
	
	await _wait_for_all_awake()
	
	emit_signal("morning_started", message, birth_cow != null)
	night_active = false

func _is_in_enclosure(animal) -> bool:
	if enclosure == null:
		return false
	var bodies = enclosure.get_overlapping_bodies()
	return animal in bodies

func _check_chickens_in_enclosure() -> bool:
	if enclosure == null:
		return false
	var bodies = enclosure.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("chickens"):
			return true
	return false

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
		# skip babies
		if cow.is_in_group("baby_cow"):
			continue
		var cow_id = cow.get_instance_id()
		if days_happy_tracker.has(cow_id):
			if days_happy_tracker[cow_id] >= days_happy_needed_for_birth:
				days_happy_tracker[cow_id] = 0
				return cow
	return null

func _build_morning_message(inside: int, outside: int, babies_outside: int, chickens: bool, herd_happiness: float, birth_cow) -> String:
	if birth_cow != null:
		return "You wake up to a surprise — a babby cow was born in the night! The herd seems happier"
	
	if babies_outside > 0:
		if babies_outside == 1:
			return "A baby was left outside last night. The herd spent the night calling to it, and are now a bit anxious and unsettled this morning."
		else:
			return str(babies_outside) + " babies were left outside! The herd is beside themselves. Make sure the little ones get in tonight."
	
	if outside == 0 and not chickens:
		if herd_happiness > 0.8:
			return "Everyone slept well together last night. The herd seems genuinely happy this morning."
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
	# Add to current scene
	get_tree().current_scene.add_child(baby)
	print("A baby cow was born near ", parent_cow.name)
