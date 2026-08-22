extends StaticBody2D

## Era gate. Exists in BOTH timelines and blocks both players until the
## future player opens it via the era switch. Opening RAISES the gate
## (portcullis style) in both eras instead of making it vanish.
## Scene-placed: set Y so the base sits flush on the floor (no settle).

enum Existence { BOTH, PAST_ONLY, FUTURE_ONLY }

const GATE_SPEED := 200.0  ## px per second

@export var open := false:
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

func set_open(open: bool) ->void:
	self.open = open

func _update_state() -> void:
	collision_layer = 0 if open else MultiplayerManager.existence_layer(exists_in)
	_animate_gates()


## Raise/lower the era-specific gate sprites in sync. Each gate sits inside a
## clip-parent sprite (GateClip/GrateClip) sized to the doorway, so the rising
## part vanishes into the frame instead of poking out the top. Collision
## switches instantly; the visuals catch up over a fraction of a second.
func _animate_gates() -> void:
	if _gate_tween != null and _gate_tween.is_valid():
		_gate_tween.kill()
	_gate_tween = create_tween()
	for gate in [get_node_or_null("PastVisual/GateClip/Gate"), get_node_or_null("FutureVisual/GrateClip/Grate")]:
		var sprite := gate as Sprite2D
		if sprite == null or sprite.texture == null:
			continue
		var target_y: float = -sprite.texture.get_height() if open else 0.0
		var duration := absf(target_y - sprite.position.y) / GATE_SPEED
		_gate_tween.parallel().tween_property(sprite, "position:y", target_y, duration)


func reset_level() -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		open = false
