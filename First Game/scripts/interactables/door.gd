extends StaticBody2D

## Era gate. Functionally exists only where its existence scope says
## (default PAST_ONLY: blocks the past player, the future player walks
## through). The future side still sees the gate's ruined archway — the
## decay narrative — via remnant_visual.
## Scene-placed: set Y so the base sits flush on the floor (no settle).
enum Existence { BOTH, PAST_ONLY, FUTURE_ONLY }

var open := false:
	set(value):
		if open == value:
			return
		open = value
		_update_state()

@export var exists_in := Existence.PAST_ONLY:
	set(value):
		exists_in = value
		_update_state()

@export var remnant_visual := true

@export var owner_era := 1  ## reserved: who may interact once the gate is interactive


func _ready() -> void:
	add_to_group("doors")
	add_to_group("level_resettable")
	owner_era = MultiplayerManager.clamp_owner(exists_in, owner_era, name)
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
