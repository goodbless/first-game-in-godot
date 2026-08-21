extends "res://scripts/interactables/interactable_body.gd"

## Era gate. Blocks only the PAST player (layer 8); the future player walks
## through freely. The future player opens it via the era switch.

var open := false:
	set(value):
		if open == value:
			return
		open = value
		_update_state()


func _ready() -> void:
	super()
	add_to_group("doors")
	_update_state()
	print("door: ready at ", position, " open=", open, " layer=", collision_layer)


func _physics_process(delta: float) -> void:
	_settle(delta)


func _update_state() -> void:
	collision_layer = 0 if open else 8
	var gate := get_node_or_null("PastVisual/Gate")
	if gate != null:
		gate.visible = not open
	var arch := get_node_or_null("FutureVisual/Arch")
	if arch != null:
		arch.modulate = Color(0.4, 1.0, 0.8, 0.9) if open else Color(0.3, 0.3, 0.35, 0.5)


func reset_level() -> void:
	super()
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		open = false
