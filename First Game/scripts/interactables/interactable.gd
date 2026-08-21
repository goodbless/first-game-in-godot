extends Node2D

## Base for all era-aware interactables. Handles dual visuals, era ownership
## checks and level reset. Physics/state specifics live in subclasses.

@export var owner_era := 1  ## 1 = past player, 2 = future player

var _initial_position: Vector2


func _ready() -> void:
	add_to_group("level_resettable")
	add_to_group("interactables")
	_initial_position = position
	apply_era_visibility()


func apply_era_visibility() -> void:
	var past_visual := get_node_or_null("PastVisual")
	var future_visual := get_node_or_null("FutureVisual")
	if MultiplayerManager.my_era == MultiplayerManager.Era.FUTURE:
		if past_visual != null:
			past_visual.visible = false
		if future_visual != null:
			future_visual.visible = true
	else:
		if past_visual != null:
			past_visual.visible = true
		if future_visual != null:
			future_visual.visible = false


func _can_interact(body) -> bool:
	return body is CharacterBody2D and "player_id" in body \
		and MultiplayerManager.era_of(body.player_id) == owner_era


func reset_level() -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		position = _initial_position
