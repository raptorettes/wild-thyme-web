extends CanvasLayer

#signals
signal message_dismissed
signal message_shown

@onready var portrait = $Control/Portrait
#@onready var emoji_icon = $Control/EmojiIcon
@onready var dialogue_label = $Control/Label

var message_queue: Array = []
var is_showing: bool = false
var has_appeared: bool = false

func _ready():
	visible = false
	#emoji_icon.visible = false
	
# Main function to show a single message
# Expression "angry" "blink" "happy" "love" "love talking" "sad talking" "sleep" "static" "super excited" "talking"
# Emoji: "day" "night" "transition" "baby_cow" "cow" "baby_grow" "chicken" or "" for none
func show_message(text: String, expression: String = "talking", emoji: String = "") -> void:
	message_queue.append({
		"text": text,
		"expression": expression,
		#"emoji": emoji
	})
	if not is_showing:
		_show_next()
		
# Show a sequence of messages, await them all
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
		
	var msg = message_queue.pop_front()
	is_showing = true
	visible = true
	emit_signal("message_shown")
	
		# Animate box sliding up from below with bounce
	var control = $Control
	if not has_appeared:
		# first time slide in with bounce
		has_appeared = true
		var rest_y = control.position.y
		control.position.y = rest_y + 200.0  # start below
		control.modulate.a = 0.0
	
		var tween = create_tween()
		tween.set_parallel(false)
		tween.tween_property(control, "modulate:a", 1.0, 0.2)
		tween.tween_property(control, "position:y", rest_y, 0.4)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_BACK)
		
	# set text
	dialogue_label.text = msg.text
	
	#set character expression
	if msg.expression != "" and portrait.sprite_frames.has_animation(msg.expression):
		portrait.play(msg.expression)
	else:
		portrait.play("talking")
		
	## set emoji icon
	#if msg.emoji != "" and emoji_icon.sprite_frames.has_animation(msg.emoji):
		#emoji_icon.visible = true 
		#emoji_icon.play(msg.emoji)
	#else:
		#emoji_icon.visible = false
	#
func _hide():
	has_appeared = false  # ← reset so next show bounces in
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
	if event is InputEventMouseButton and event.pressed:
		is_showing = false
		_show_next()
	
	
	
