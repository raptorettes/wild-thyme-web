extends Node2D


func _on_bb_cow_found_cow() -> void:
	$TheLabels/TheLabel.text = "FOUND THE COW"
	$TheLabels/TheLabel.visible = true

@onready var pause_menu = $PauseMenu

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if pause_menu.visible:
				pause_menu.close()
			else:
				pause_menu.open()
