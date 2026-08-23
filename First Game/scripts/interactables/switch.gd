extends Area2D

## Future-era switch. Only the FUTURE player can press it (E nearby).
## Activating it opens every door in the level — gates that block the
## PAST player's path (future helps past).
## Scene-placed on the floor; the root Area doubles as the proximity sensor.
signal switch_on
signal switch_off
signal switch_changed(on:bool)

enum Existence { BOTH, PAST_ONLY, FUTURE_ONLY }  # scope: which timelines this exists in
@onready var on: Sprite2D = $ON
@onready var off: Sprite2D = $OFF

@export var owner_era := 2  ## 1 = past player, 2 = future player
@export var exists_in := Existence.BOTH:
	set(value):
		exists_in = value
		_apply_existence()

var active := false:
	set(value):
		if active == value:
			return
		active = value
		_update_state()


func _ready() -> void:
	add_to_group("level_resettable")
	add_to_group("interactables")
	owner_era = MultiplayerManager.clamp_owner(exists_in, owner_era, name)
	_apply_existence()
	_update_state()


func _apply_existence() -> void:
	collision_mask = MultiplayerManager.existence_trigger_mask(exists_in)
	apply_era_visibility()


## Scoped-out era hides the WHOLE switch — body, hint and the ON/OFF lamps,
## which sit outside PastVisual/FutureVisual and were leaking. Hidden Areas
## still monitor, and the mask already excludes that era's player anyway.
func apply_era_visibility() -> void:
	var mine := MultiplayerManager.my_era
	match exists_in:
		Existence.PAST_ONLY:
			visible = mine == MultiplayerManager.Era.NONE or mine == MultiplayerManager.Era.PAST
		Existence.FUTURE_ONLY:
			visible = mine == MultiplayerManager.Era.NONE or mine == MultiplayerManager.Era.FUTURE
		_:
			visible = true
	var era_visuals := get_node_or_null("EraVisuals")
	if era_visuals != null:
		era_visuals.apply_era_visibility()


func _process(_delta: float) -> void:
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
	on.visible = active
	off.visible = !active


@rpc("any_peer", "call_local", "reliable")
func request_activate() -> void:
	if not multiplayer.is_server():
		return
	if MultiplayerManager.era_of(multiplayer.get_remote_sender_id()) != owner_era:
		return
	active = !active
	switch_changed.emit(active)
	if active:
		switch_on.emit()
	else:
		switch_off.emit()

func reset_level() -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		active = false
