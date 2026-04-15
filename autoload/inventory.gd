extends CanvasLayer

@onready var item_icon = $Control/TextureRect/Item
@onready var pickup_sound = $AudioStreamPlayer

var held_item: String = ""
var held_happiness_boost: float = 0.0

# Preload item textures
var item_textures = {
	"star": preload("res://assets/Objects/star.png"),
}

func _ready():
	item_icon.visible = false


func pick_up(item_name: String, texture: Texture2D = null, boost: float = 0.0):
	if held_item != "":
		return
	held_item = item_name
	held_happiness_boost = boost
	if texture != null:
		item_icon.texture = texture
	elif item_textures.has(item_name):
		item_icon.texture = item_textures[item_name]
	item_icon.visible = true
	pickup_sound.play()

func use_item():
	held_item = ""
	held_happiness_boost = 0.0
	item_icon.visible = false
	item_icon.texture = null
	pickup_sound.play()

func is_holding(item_name: String) -> bool:
	return held_item == item_name

func is_empty() -> bool:
	return held_item == ""
