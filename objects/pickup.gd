extends Area2D

@export var item_name: String = ""
@export var item_texture: Texture2D = null
@export var happiness_boost: float = 0.15
@export var is_special: bool = false

func _ready():
	if item_texture != null:
		$Sprite2D.texture = item_texture
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		pass

func _on_body_exited(body):
	if body.is_in_group("player"):
		pass

func interact():
	if Inventory.is_empty():
		Inventory.pick_up(item_name, item_texture, happiness_boost)
		queue_free()
	else:
		DialogueBox.show_message(
			"Your hands are full.",
			"talking",
			""
		)
