extends "res://scripts/interactables/interactable_body.gd"

## Era gate. Blocks only the PAST player (layer 8); the future player walks
## through freely and opens it via the era switch. Turns fully static once
## it has settled on the floor.

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


func _physics_process(delta: float) -> void:
	_settle(delta)
	# The door only needs physics for its initial drop. Once settled it must
	# become a truly static wall: a still-simulating door would let a pushed
	# box shove it aside via penetration recovery.
	if is_on_floor():
		set_physics_process(false)


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
		set_physics_process(true)  # re-drop and re-settle at the reset position
