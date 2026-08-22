extends Node2D

## Debug harness: run test_room offline with one local player (offline peer
## counts as server, so server-side physics reproduce solo).

func _ready() -> void:
	var level = load("res://scenes/Levels/test_room.tscn").instantiate()
	add_child(level)
	await get_tree().process_frame
	var player = load("res://scenes/multiplayer_player.tscn").instantiate()
	player.player_id = 1
	player.name = "Player_1"
	level.get_node("Players").add_child(player, true)
	player.global_position = MultiplayerManager.spawn_position_for_peer(1)
