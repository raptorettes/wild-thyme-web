extends NPC
class_name npc_frogge

func _ready() -> void:
	super._ready()
	$StateChartDebugger.hide()

func _on_idle_state_entered() -> void:
	super._on_idle_state_entered()
	state_machine.travel("idle%d" % randi_range(1, 3))

func _on_surpise_state_entered() -> void:
	state_machine.travel("surprise")

func _on_surprise_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$StateChart.send_event("character_nearby")

func _on_surprise_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		$StateChart.send_event("character_left")

func _on_run_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		flee_body = body
		$StateChart.send_event("character_too_close")

func _on_run_state_entered() -> void:
	_go_to(target)
