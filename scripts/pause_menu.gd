extends CanvasLayer

func _ready():
	visible = false
	# Highlight the current category button on open
	_update_category_buttons()

func _update_category_buttons():
	var current = MusicManager.current_category
	$CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/ChillButton.disabled = \
		current == MusicManager.CATEGORY.CHILL
	$CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/LofiButton.disabled = \
		current == MusicManager.CATEGORY.LOFI
	$CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/BeatsButton.disabled = \
		current == MusicManager.CATEGORY.BEATS

func open():
	visible = true
	get_tree().paused = true
	_update_category_buttons()

func close():
	visible = false
	get_tree().paused = false

func _on_chill_button_pressed():
	MusicManager.set_category(MusicManager.CATEGORY.CHILL)
	_update_category_buttons()

func _on_lofi_button_pressed():
	MusicManager.set_category(MusicManager.CATEGORY.LOFI)
	_update_category_buttons()

func _on_beats_button_pressed():
	MusicManager.set_category(MusicManager.CATEGORY.BEATS)
	_update_category_buttons()

func _on_next_song_pressed():
	MusicManager.next_track()

func _on_resume_pressed():
	close()

func _on_quit_pressed():
	get_tree().quit()
