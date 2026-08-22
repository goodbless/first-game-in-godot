extends StaticBody2D

## Era gate. Exists in BOTH timelines and blocks both players until the
## future player opens it via the era switch.
## Scene-placed: set Y so the base sits flush on the floor (no settle).
## exists_in stays runtime-changeable (synced) for scripted scope shifts.

enum Existence { BOTH, PAST_ONLY, FUTURE_ONLY }

var open := false:
	set(value):
		if open == value:
			return
		open = value
		_update_state()

@export var exists_in := Existence.BOTH:
	set(value):
		exists_in = value
		_update_state()


func _ready() -> void:
	add_to_group("doors")
	add_to_group("level_resettable")
	_update_state()


func _update_state() -> void:
	collision_layer = 0 if open else MultiplayerManager.existence_layer(exists_in)
	var gate := get_node_or_null("PastVisual/Gate")
	if gate != null:
		gate.visible = not open
	var arch := get_node_or_null("FutureVisual/Arch")
	if arch != null:
		arch.modulate = Color(0.4, 1.0, 0.8, 0.9) if open else Color(0.3, 0.3, 0.35, 0.5)


func reset_level() -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		open = false
