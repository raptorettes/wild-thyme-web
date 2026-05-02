extends CanvasLayer

@onready var label = $Control/Label

func _ready():
	visible = false

func show_prompt(text: String):
	label.text = text
	visible = true

func hide_prompt():
	visible = false
