extends Node

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1"

var multiplayer_scene = preload("res://scenes/multiplayer_player.tscn")

var _player_spawn_node: Node2D
var host_mode_enabled := false
var multiplayer_mode_enabled := false

func become_host():
	print("Starting host")

	_player_spawn_node = get_tree().current_scene.get_node("Players")

	host_mode_enabled = !OS.has_feature("dedicated_server")
	multiplayer_mode_enabled = true

	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)

	multiplayer.multiplayer_peer = server_peer

	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)

	_remove_single_player()
	if host_mode_enabled:
		_add_player_to_game(1)

func join_as_player_2():
	print("Player 2 join")

	multiplayer_mode_enabled = true
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(SERVER_IP, SERVER_PORT)

	multiplayer.multiplayer_peer = client_peer

	_remove_single_player()

func _add_player_to_game(id):
	print("Player joined: " + str(id))

	var player_to_add = multiplayer_scene.instantiate()
	player_to_add.player_id = id
	player_to_add.name = "Player_" + str(id)

	_player_spawn_node.add_child(player_to_add, true)

func _del_player(id):
	print("Player left: " + str(id))
	for player in _player_spawn_node.get_children():
		if player.player_id == id:
			player.queue_free()
			break

func _remove_single_player():
	print("remove single player")
	var player_to_remove = get_tree().current_scene.get_node("Player")
	player_to_remove.queue_free()