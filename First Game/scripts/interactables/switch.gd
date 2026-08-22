extends "res://scripts/interactables/interactable_body.gd"

## Future-era switch. Only the FUTURE player can press it (E nearby).
## Activating it opens every door in the level — gates that block the
## PAST player's path (future helps past).

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


## Physics only runs for the initial drop; after settling the switch becomes
## static so a pushed box can never depenetrate-shove it around.
func _physics_process(delta: float) -> void:
	_settle(delta)
	if is_on_floor():
		set_physics_process(false)


## Interaction + hint live in _process so they keep running after physics
## has stopped for good.
func _process(_delta: float) -> void:
	if active:
		return
	var bodies: Array = sensor.get_overlapping_bodies()
	_update_hint(bodies)
	for body in bodies:
		if _can_interact(body) and Input.is_action_just_pressed("interact"):
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
	if active:
		_hide_hint()


@rpc("any_peer", "call_local", "reliable")
func request_activate() -> void:
	if not multiplayer.is_server() or active:
		return
	if MultiplayerManager.era_of(multiplayer.get_remote_sender_id()) != owner_era:
		return
	active = true
	for door in get_tree().get_nodes_in_group("doors"):
		door.open = true


func reset_level() -> void:
	super()
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		active = false
		set_physics_process(true)  # re-drop and re-settle
