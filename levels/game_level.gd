extends Node2D


func _on_bb_cow_found_cow() -> void:
	$TheLabels/TheLabel.text = "FOUND THE COW"
	$TheLabels/TheLabel.visible = true
