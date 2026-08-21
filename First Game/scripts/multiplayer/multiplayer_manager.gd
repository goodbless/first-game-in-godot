extends Node

enum Era { NONE = 0, PAST = 1, FUTURE = 2 }

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1"
const LEVELS := ["res://scenes/test_room.tscn"]

var multiplayer_scene = preload("res://scenes/multiplayer_player.tscn")

var _player_spawn_node: Node2D
var host_mode_enabled := false
var multiplayer_mode_enabled := false
var my_era: Era = Era.NONE
var _current_level := 0


func _refresh_era_visuals():
	for node in get_tree().get_nodes_in_group("interactables"):
		node.apply_era_visibility()


func is_past() -> bool:
	return my_era == Era.PAST


func is_future() -> bool:
	return my_era == Era.FUTURE


## Host (peer 1) is always the past player; joined peers are future players.
## Client peer ids are random in Godot 4, so "id == 2" is never a valid check.
static func era_of(peer_id: int) -> Era:
	return Era.PAST if peer_id == 1 else Era.FUTURE


func become_host():
	print("Starting host (PAST era)")

	my_era = Era.PAST
	_refresh_era_visuals()
	host_mode_enabled = !OS.has_feature("dedicated_server")
	multiplayer_mode_enabled = true

	var server_peer = ENetMultiplayerPeer.new()
	var err := server_peer.create_server(SERVER_PORT)
	if err != OK:
		push_error("Failed to create server on port %d: %s — is another instance hosting?" % [SERVER_PORT, error_string(err)])
		return

	multiplayer.multiplayer_peer = server_peer

	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)

	respawn_all_players()


func join_as_player_2():
	print("Player 2 join (FUTURE era)")

	my_era = Era.FUTURE
	_refresh_era_visuals()
	multiplayer_mode_enabled = true
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(SERVER_IP, SERVER_PORT)

	multiplayer.multiplayer_peer = client_peer


func respawn_all_players():
	if not multiplayer.is_server():
		return
	if not get_tree().current_scene.has_node("Players"):
		return

	_player_spawn_node = get_tree().current_scene.get_node("Players")

	var present := {}
	for child in _player_spawn_node.get_children():
		if "player_id" in child:
			present[child.player_id] = true

	if host_mode_enabled and not present.has(1):
		_add_player_to_game(1)
	for peer_id in multiplayer.get_peers():
		if not present.has(peer_id):
			_add_player_to_game(peer_id)


func _add_player_to_game(id):
	print("Player joined: " + str(id))
	# Lobby / mid-scene-switch: no Players node yet — respawn_all_players()
	# spawns everyone when the level scene is ready.
	if _player_spawn_node == null or not is_instance_valid(_player_spawn_node):
		return

	var player_to_add = multiplayer_scene.instantiate()
	player_to_add.player_id = id
	player_to_add.name = "Player_" + str(id)

	_player_spawn_node.add_child(player_to_add, true)


func _del_player(id):
	print("Player left: " + str(id))
	if _player_spawn_node == null:
		return
	for player in _player_spawn_node.get_children():
		if player.player_id == id:
			player.queue_free()
			break


## --- Level flow (server-authoritative) ---

## Lobby entry point: the server calls this once both players are connected.
func start_game() -> void:
	if not multiplayer.is_server():
		return
	_goto_level.rpc(0)


func notify_level_failed():
	if multiplayer.is_server():
		_reset_level.rpc()


func notify_level_complete():
	if multiplayer.is_server():
		var next := _current_level + 1
		if next >= LEVELS.size():
			next = 0
		_goto_level.rpc(next)


@rpc("call_local", "reliable")
func _reset_level():
	for node in get_tree().get_nodes_in_group("players"):
		if node.has_method("reset_level"):
			node.reset_level()
	for node in get_tree().get_nodes_in_group("level_resettable"):
		if node.has_method("reset_level"):
			node.reset_level()


@rpc("call_local", "reliable")
func _goto_level(level_index: int) -> void:
	_current_level = level_index
	get_tree().change_scene_to_file.call_deferred(LEVELS[level_index])
