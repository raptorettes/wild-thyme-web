extends CanvasLayer

@onready var label = $Control/Label

func _ready():
	update()
	NightManager.morning_started.connect(_on_morning_started)

func update():
	label.text = "Day " + str(NightManager.day_count)

func _on_morning_started(_message: String, _baby_born: bool, _cow_grown_up: bool):
	update()
