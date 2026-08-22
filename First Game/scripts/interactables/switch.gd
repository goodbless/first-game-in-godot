extends Area2D

## Future-era switch. Only the FUTURE player can press it (E nearby).
## Activating it opens every door in the level — gates that block the
## PAST player's path (future helps past).
## Scene-placed on the floor; the root Area doubles as the proximity sensor.
@export var owner_era := 2  ## 1 = past player, 2 = future player

var active := false:
	set(value):
		if active == value:
			return
		active = value
		_update_state()


func _ready() -> void:
	add_to_group("level_resettable")
	_update_state()


func _process(_delta: float) -> void:
	if active:
		return
	var bodies: Array = get_overlapping_bodies()
	_update_hint(bodies)
	for body in bodies:
		if _can_interact(body) and Input.is_action_just_pressed("interact"):
			request_activate.rpc()
			return


func _can_interact(body) -> bool:
	return body is CharacterBody2D and "player_id" in body \
		and MultiplayerManager.era_of(body.player_id) == owner_era


func _update_hint(bodies: Array) -> void:
	var hint := get_node_or_null("Hint")
	if hint == null:
		return
	var show_hint := false
	for body in bodies:
		if _can_interact(body) and body.player_id == multiplayer.get_unique_id():
			show_hint = true
			break
	hint.visible = show_hint


func _update_state() -> void:
	for visual in [get_node_or_null("PastVisual"), get_node_or_null("FutureVisual")]:
		if visual == null:
			continue
		if active:
			visual.modulate = Color(0.4, 1.0, 0.8, 1)
		else:
			visual.modulate = Color(0.5, 0.5, 0.55, 1)
	if active:
		var hint := get_node_or_null("Hint")
		if hint != null:
			hint.visible = false


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
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		active = false
