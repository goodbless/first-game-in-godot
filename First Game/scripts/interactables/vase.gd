extends "res://scripts/interactables/interactable_body.gd"

## Breakable vase. The past player attacks (X) while nearby — it shatters in
## BOTH eras: the future player sees it "suddenly" explode into debris.

var broken := false:
	set(value):
		if broken == value:
			return
		broken = value
		_update_state()

@onready var sensor := $Sensor


func _ready() -> void:
	super()
	_update_state()


func _physics_process(delta: float) -> void:
	_settle(delta)
	if broken:
		return
	for body in sensor.get_overlapping_bodies():
		if _can_interact(body) and Input.is_action_just_pressed("attack"):
			request_break.rpc()
			return


func _update_state() -> void:
	for visual in [get_node_or_null("PastVisual"), get_node_or_null("FutureVisual")]:
		if visual == null:
			continue
		if broken:
			visual.modulate = Color(0.35, 0.3, 0.25, 1)
			visual.scale = Vector2(1.0, 0.35)
			visual.position = Vector2(0, 6)
		else:
			visual.modulate = Color(1, 1, 1, 1)
			visual.scale = Vector2(1, 1)
			visual.position = Vector2.ZERO
	collision_layer = 0 if broken else 1
	set_physics_process(not broken)


@rpc("any_peer", "call_local", "reliable")
func request_break() -> void:
	if not multiplayer.is_server() or broken:
		return
	if MultiplayerManager.era_of(multiplayer.get_remote_sender_id()) != owner_era:
		return
	broken = true


func reset_level() -> void:
	super()
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		broken = false
