extends CanvasLayer

signal message_dismissed
signal message_shown

@onready var portrait = $Control/Portrait
@onready var dialogue_label = $Control/Label

var show_time: float = 0.0
var message_queue: Array = []
var is_showing: bool = false
var has_appeared: bool = false

var name_intros: Array[String] = [
	"Hi, ",
	"This is ",
	"Morning, ",
	"It's ",
	"Hey there, ",
	"The herd knows them as ",
]

func _ready():
	visible = false

func _process(delta):
	if visible:
		show_time += delta

func show_message(text: String, expression: String = "talking", emoji: String = "") -> void:
	message_queue.append({
		"text": text,
		"expression": expression,
	})
	if not is_showing:
		_show_next()

func show_sequence(messages: Array) -> void:
	for msg in messages:
		show_message(msg.get("text", ""), msg.get("expression", "talking"))
	await _wait_for_queue()

func _wait_for_queue() -> void:
	while not message_queue.is_empty() or is_showing:
		await get_tree().process_frame

func _show_next():
	if message_queue.is_empty():
		_hide()
		return
	
	show_time = 0.0  # reset timer when new message shows
	var msg = message_queue.pop_front()
	is_showing = true
	visible = true
	emit_signal("message_shown")
	
	var control = $Control
	control.modulate.a = 1.0  # ensure visible
	
	if not has_appeared:
		has_appeared = true
		var rest_y = control.position.y
		control.position.y = rest_y + 200.0
		control.modulate.a = 0.0
		var tween = create_tween()
		tween.set_parallel(false)
		tween.tween_property(control, "modulate:a", 1.0, 0.2)
		tween.tween_property(control, "position:y", rest_y, 0.4)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_BACK)
	
	dialogue_label.text = msg.text
	
	if msg.expression != "" and portrait.sprite_frames.has_animation(msg.expression):
		portrait.play(msg.expression)
	else:
		portrait.play("talking")

func _hide():
	has_appeared = false
	var tween = create_tween()
	tween.tween_property($Control, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		visible = false
		is_showing = false
		emit_signal("message_dismissed")
	)

func _input(event):
	if not visible:
		return
	if show_time < 0.2:  # ignore input briefly after showing
		return
	if event is InputEventMouseButton and event.pressed:
		is_showing = false
		_show_next()
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F:
			is_showing = false
			_show_next()

func get_name_intro() -> String:
	return name_intros[randi() % name_intros.size()]

func show_cow_name(cow_name: String, expression: String = "happy") -> void:
	var intro = get_name_intro()
	show_message(intro + cow_name, expression)
