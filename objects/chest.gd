extends StaticBody2D

@export var chest_item: String = ""
@export var empty_message: String = "Surprise!... it's empty."
@export var item_message: String = "A star fruit!"
@export var respawn_days: int = 2

@onready var closed_sprite = $ClosedSprite
@onready var open_sprite = $OpenSprite
@onready var interact_area = $InteractArea
@onready var open_sound = $AudioStreamPlayer

var is_open: bool = false
var has_been_opened: bool = false
var day_opened: int = -1

func _ready():
	add_to_group("chest")
	open_sprite.visible = false
	NightManager.morning_started.connect(_on_morning_started)

func interact():
	print("chest interact called, item: ", chest_item, " is_open: ", is_open)
	if is_open:
		return
	if has_been_opened and not _can_reopen():
		DialogueBox.show_message(
			"The chest is empty for now.",
			"talking", ""
		)
		return
	_open()

func _can_reopen() -> bool:
	if day_opened == -1:
		return true
	return NightManager.day_count >= day_opened + respawn_days

func _open():
	is_open = true
	has_been_opened = true
	day_opened = NightManager.day_count
	closed_sprite.visible = false
	open_sprite.visible = true
	if open_sound:
		open_sound.play()
	
	if chest_item != "" and Inventory.is_empty():
		# Load star texture for inventory
		var star_texture = load("res://assets/items/star.png")
		Inventory.pick_up(chest_item, star_texture, 0.0)
		DialogueBox.show_message(item_message, "happy", "")
	elif chest_item != "" and not Inventory.is_empty():
		DialogueBox.show_message(
			"Your hands are full. Come back when you have room.",
			"talking", ""
		)
		# Don't mark as opened if inventory full
		is_open = false
		has_been_opened = false
		day_opened = -1
		closed_sprite.visible = true
		open_sprite.visible = false
		return
	else:
		DialogueBox.show_message(empty_message, "talking", "")

func _on_morning_started(_message, _baby_born, _cow_grown_up):
	if has_been_opened and _can_reopen():
		_reset()

func _reset():
	is_open = false
	has_been_opened = false
	closed_sprite.visible = true
	open_sprite.visible = false
