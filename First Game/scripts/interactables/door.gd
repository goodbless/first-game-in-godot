extends StaticBody2D

## Era gate. Exists in BOTH timelines and blocks both players until the
## future player opens it via the era switch. Opening RAISES the gate
## (portcullis style) in both eras instead of making it vanish.
## Scene-placed: set Y so the base sits flush on the floor (no settle).

enum Existence { BOTH, PAST_ONLY, FUTURE_ONLY }

const GATE_TRAVEL := 44.0
const GATE_SPEED := 60.0  ## px per second

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

var _gate_tween: Tween


func _ready() -> void:
	add_to_group("doors")
	add_to_group("level_resettable")
	_update_state()


func _update_state() -> void:
	collision_layer = 0 if open else MultiplayerManager.existence_layer(exists_in)
	var arch := get_node_or_null("FutureVisual/Arch")
	if arch != null:
		arch.modulate = Color(0.4, 1.0, 0.8, 0.9) if open else Color(0.3, 0.3, 0.35, 0.5)
	_animate_gates()


## Raise/lower the era-specific gate sprites in sync. Collision switches
## instantly; the visuals catch up over a fraction of a second.
func _animate_gates() -> void:
	if _gate_tween != null and _gate_tween.is_valid():
		_gate_tween.kill()
	_gate_tween = create_tween()
	var target_y := -GATE_TRAVEL if open else 0.0
	for gate in [get_node_or_null("PastVisual/Gate"), get_node_or_null("FutureVisual/Grate")]:
		if gate == null:
			continue
		var duration := absf(target_y - gate.position.y) / GATE_SPEED
		_gate_tween.parallel().tween_property(gate, "position:y", target_y, duration)


func reset_level() -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		open = false
