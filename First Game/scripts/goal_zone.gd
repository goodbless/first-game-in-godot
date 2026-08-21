extends Area2D

# Goal zone: one per era. Level completes when both are occupied.

@export var goal_era: MultiplayerManager.Era = MultiplayerManager.Era.PAST

var _occupied := false

func _ready() -> void:
	add_to_group("goal_zones")
	collision_mask = 2 if goal_era == MultiplayerManager.Era.PAST else 4

func _on_body_entered(body):
	if _is_era_player(body):
		_occupied = true
		_check_win()

func _on_body_exited(body):
	if _is_era_player(body):
		_occupied = false

func _is_era_player(body) -> bool:
	return body is CharacterBody2D and "player_id" in body \
		and MultiplayerManager.era_of(body.player_id) == goal_era

func _check_win():
	if not multiplayer.is_server():
		return
	for zone in get_tree().get_nodes_in_group("goal_zones"):
		if not zone._occupied:
			return
	print("Both players reached their goals — level complete!")
	MultiplayerManager.notify_level_complete()

func reset_level():
	_occupied = false
