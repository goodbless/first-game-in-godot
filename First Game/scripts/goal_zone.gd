extends Area2D

# Goal zone: one per era. Level completes when both zones are occupied.
# Both goals carry a red/blue lamp pair synced across eras: red = the PAST
# player is standing on her goal, blue = the FUTURE player on his — so each
# player sees whether the other era has arrived without seeing each other.
@onready var red_off: Sprite2D = $red_off
@onready var red_on: Sprite2D = $red_on
@onready var blue_off: Sprite2D = $blue_off
@onready var blue_on: Sprite2D = $blue_on

@export var goal_era: MultiplayerManager.Era = MultiplayerManager.Era.PAST

## Server-authoritative "an era player is on this goal" — synced ON_CHANGE;
## the setter refreshes every goal's lamps on every peer, so both doors
## always show both eras' arrival state.
var occupied := false:
	set(value):
		if occupied == value:
			return
		occupied = value
		_refresh_all_lights()


func _ready() -> void:
	add_to_group("goal_zones")
	add_to_group("interactables")
	collision_mask = 2 if goal_era == MultiplayerManager.Era.PAST else 4
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	apply_era_visibility()
	_refresh_all_lights()


func apply_era_visibility() -> void:
	# Pre-join (era NONE) shows both goals; in-game each player sees only
	# own era's — hide the ROOT so door, lamps and flag all go together.
	# Hidden Areas still detect (visibility doesn't stop monitoring), and the
	# collision mask already restricts triggers to the owning era's player.
	visible = MultiplayerManager.my_era == MultiplayerManager.Era.NONE \
		or MultiplayerManager.my_era == goal_era


func _on_body_entered(body):
	# Server decides; clients learn through the synced property.
	if multiplayer.is_server() and _is_era_player(body):
		occupied = true
		_check_win()


func _on_body_exited(body):
	if multiplayer.is_server() and _is_era_player(body):
		occupied = false


func _is_era_player(body) -> bool:
	return body is CharacterBody2D and "player_id" in body \
		and MultiplayerManager.era_of(body.player_id) == goal_era


func _check_win():
	for zone in get_tree().get_nodes_in_group("goal_zones"):
		if not zone.occupied:
			return
	print("Both players reached their goals — level complete!")
	MultiplayerManager.notify_level_complete()


## Any zone flip re-renders the lamp pair on EVERY goal — both doors are two
## views of the same shared state.
func _refresh_all_lights() -> void:
	for zone in get_tree().get_nodes_in_group("goal_zones"):
		zone._update_lights()


func _update_lights() -> void:
	var past_here := false
	var future_here := false
	for zone in get_tree().get_nodes_in_group("goal_zones"):
		if zone.goal_era == MultiplayerManager.Era.PAST:
			past_here = zone.occupied
		elif zone.goal_era == MultiplayerManager.Era.FUTURE:
			future_here = zone.occupied
	red_on.visible = past_here
	red_off.visible = not past_here
	blue_on.visible = future_here
	blue_off.visible = not future_here


func reset_level():
	if multiplayer.is_server():
		occupied = false
