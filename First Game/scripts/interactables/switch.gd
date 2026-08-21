extends "res://scripts/interactables/interactable_body.gd"

## Future-era switch. Only the FUTURE player can press it (X nearby).
## Activating it opens every door in the level — including gates that
## block the PAST player's path (future helps past).

var active := false:
	set(value):
		if active == value:
			return
		active = value
		_update_state()

@onready var sensor := $Sensor


func _ready() -> void:
	super()
	_update_state()


func _physics_process(delta: float) -> void:
	_settle(delta)
	if active:
		return
	for body in sensor.get_overlapping_bodies():
		if _can_interact(body) and Input.is_action_just_pressed("attack"):
			print("switch: activate requested by ", body.name)
			request_activate.rpc()
			return


func _update_state() -> void:
	for visual in [get_node_or_null("PastVisual"), get_node_or_null("FutureVisual")]:
		if visual == null:
			continue
		if active:
			visual.modulate = Color(0.4, 1.0, 0.8, 1)
		else:
			visual.modulate = Color(0.5, 0.5, 0.55, 1)
	set_physics_process(not active)


@rpc("any_peer", "call_local", "reliable")
func request_activate() -> void:
	if not multiplayer.is_server() or active:
		return
	var sender_era := MultiplayerManager.era_of(multiplayer.get_remote_sender_id())
	print("switch: request from peer ", multiplayer.get_remote_sender_id(), " era ", sender_era, " (owner ", owner_era, ")")
	if sender_era != owner_era:
		return
	active = true
	var doors := get_tree().get_nodes_in_group("doors")
	print("switch: activating ", doors.size(), " doors")
	for door in doors:
		door.open = true


func reset_level() -> void:
	super()
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		active = false
