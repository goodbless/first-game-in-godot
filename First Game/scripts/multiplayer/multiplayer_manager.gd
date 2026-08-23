extends Node

enum Era { NONE = 0, PAST = 1, FUTURE = 2 }
enum Existence { BOTH, PAST_ONLY, FUTURE_ONLY }  # scope: which timelines an object functionally occupies


## Collision layer for a solid body scoped to an existence range.
func existence_layer(existence: int) -> int:
	match existence:
		Existence.PAST_ONLY:
			return 8
		Existence.FUTURE_ONLY:
			return 16
		_:
			return 1


## Detection mask for a trigger scoped to an existence range.
func existence_trigger_mask(existence: int) -> int:
	match existence:
		Existence.PAST_ONLY:
			return 2
		Existence.FUTURE_ONLY:
			return 4
		_:
			return 6


## owner_era must stay within exists_in — clamp and warn on bad configs.
func clamp_owner(existence: int, owner_era: int, object_name: String) -> int:
	match existence:
		Existence.PAST_ONLY:
			if owner_era != Era.PAST:
				push_warning("%s: owner_era %d outside PAST_ONLY existence — clamped to past" % [object_name, owner_era])
				return Era.PAST
		Existence.FUTURE_ONLY:
			if owner_era != Era.FUTURE:
				push_warning("%s: owner_era %d outside FUTURE_ONLY existence — clamped to future" % [object_name, owner_era])
				return Era.FUTURE
	return owner_era

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1"
const LOBBY_SCENE := "res://scenes/lobby.tscn"

## Configured level list — edit res://config/level_list.tres in the Inspector
## to reorder, rename, add or remove levels. The list is the single source of
## truth for the lobby picker and the next-level progression.
const LEVEL_LIST: LevelList = preload("res://config/level_list.tres")

## Level scene paths in configured order, plus their display names.
var levels: Array[String] = []
var level_names: Array[String] = []
var _selected_level := 0


func _ready() -> void:
	_load_levels()


func _load_levels() -> void:
	levels.clear()
	level_names.clear()
	for def in LEVEL_LIST.levels:
		if def == null or def.scene == null:
			push_warning("LevelList entry without a scene — skipped")
			continue
		levels.append(def.scene.resource_path)
		level_names.append(def.display_name())
	_selected_level = clampi(_selected_level, 0, maxi(levels.size() - 1, 0))


var past_player_scene: PackedScene = preload("res://scenes/multiplayer_player.tscn")
var future_player_scene: PackedScene = preload("res://scenes/multiplayer_player_2.tscn")
var loading_scene = preload("res://scenes/ui/loading_screen.tscn")

const PAST_PLAYER_UID := "uid://u6e7d34la27u"
const FUTURE_PLAYER_UID := "uid://co6alg6cmej5s"

var _player_spawn_node: Node2D
var host_mode_enabled := false
var multiplayer_mode_enabled := false
var my_era: Era = Era.NONE
var _current_level := 0
var _last_scene_path := ""


## Auto-setup watch: on entering a level scene, ensure the structural nodes
## exist (Players + MultiplayerSpawner + loading screen + respawn schedule).
## Levels with their own game_manager script keep the old explicit flow.
## Pure-content levels need none of this — drop them in Levels/ and they work.
func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path == _last_scene_path:
		return
	_last_scene_path = scene.scene_file_path
	if levels.has(scene.scene_file_path):
		_on_level_scene_loaded(scene)


func _on_level_scene_loaded(scene: Node) -> void:
	# Runs for every level — including game_manager ones — because both player
	# scenes must be spawnable wherever a spawner exists.
	var spawner := scene.get_node_or_null("MultiplayerSpawner")
	if spawner is MultiplayerSpawner:
		_ensure_spawnable_scenes(spawner as MultiplayerSpawner)

	var root_script: Script = scene.get_script()
	if root_script != null and root_script.resource_path == "res://scripts/game_manager.gd":
		return  # explicit per-level flow — leave it alone

	if not scene.has_node("Players"):
		var players := Node2D.new()
		players.name = "Players"
		players.position = Vector2(60, 40)
		scene.add_child(players)
	if not scene.has_node("MultiplayerSpawner"):
		var new_spawner := MultiplayerSpawner.new()
		new_spawner.name = "MultiplayerSpawner"
		new_spawner.spawn_limit = 2
		scene.add_child(new_spawner)
		new_spawner.spawn_path = NodePath("../Players")
		_ensure_spawnable_scenes(new_spawner)

	if multiplayer_mode_enabled:
		scene.add_child(loading_scene.instantiate())
		if multiplayer.is_server():
			await get_tree().create_timer(1.0).timeout
			respawn_all_players()


func _refresh_era_visuals():
	for node in get_tree().get_nodes_in_group("interactables"):
		node.apply_era_visibility()


func is_past() -> bool:
	return my_era == Era.PAST


func is_future() -> bool:
	return my_era == Era.FUTURE


## Host (peer 1) is always the past player; joined peers are future players.
## Client peer ids are random in Godot 4, so "id == 2" is never a valid check.
func era_of(peer_id: int) -> Era:
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

	if not multiplayer.peer_connected.is_connected(_add_player_to_game):
		multiplayer.peer_connected.connect(_add_player_to_game)
	if not multiplayer.peer_disconnected.is_connected(_del_player):
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


## Both player scenes must be registered on any level's spawner — scene-authored
## spawners predate the future player, so top up their lists at runtime.
func _ensure_spawnable_scenes(spawner: MultiplayerSpawner) -> void:
	for uid in [PAST_PLAYER_UID, FUTURE_PLAYER_UID]:
		var present := false
		for i in spawner.get_spawnable_scene_count():
			if spawner.get_spawnable_scene(i) == uid:
				present = true
				break
		if not present:
			spawner.add_spawnable_scene(uid)


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


## World position where a peer's player (re)spawns: the era's spawn marker
## if the level has one, else the Players node origin.
func spawn_position_for_peer(peer_id: int) -> Vector2:
	var wanted_era := era_of(peer_id)
	for point in get_tree().get_nodes_in_group("spawn_points"):
		if point.spawn_era == wanted_era:
			return point.global_position
	if _player_spawn_node != null:
		return _player_spawn_node.global_position
	return Vector2.ZERO


func _add_player_to_game(id):
	print("Player joined: " + str(id))
	# Lobby / mid-scene-switch: no Players node yet — respawn_all_players()
	# spawns everyone when the level scene is ready.
	if _player_spawn_node == null or not is_instance_valid(_player_spawn_node):
		return

	var scene := future_player_scene if era_of(id) == Era.FUTURE else past_player_scene
	var player_to_add = scene.instantiate()
	player_to_add.player_id = id
	player_to_add.name = "Player_" + str(id)

	_player_spawn_node.add_child(player_to_add, true)
	player_to_add.global_position = spawn_position_for_peer(id)


func _del_player(id):
	print("Player left: " + str(id))
	if _player_spawn_node == null:
		return
	for player in _player_spawn_node.get_children():
		if player.player_id == id:
			player.queue_free()
			break


## --- Level flow (server-authoritative) ---

func selected_level() -> int:
	return _selected_level


func select_level(index: int) -> void:
	_selected_level = clampi(index, 0, maxi(levels.size() - 1, 0))


## Lobby entry point: the server calls this once both players are connected.
func start_game() -> void:
	if not multiplayer.is_server() or levels.is_empty():
		return
	_goto_level.rpc(_selected_level)


## Physics tick of the last level fail — several traps can kill in the same
## tick (both players, overlapping traps, visibility sweeps); reset once.
var _last_fail_frame := -1


func notify_level_failed():
	if multiplayer.is_server():
		var frame := Engine.get_physics_frames()
		if frame == _last_fail_frame:
			return
		_last_fail_frame = frame
		_reset_level.rpc()


func notify_level_complete():
	if multiplayer.is_server():
		var next := _current_level + 1
		if next < levels.size():
			_goto_level.rpc(next)
		else:
			_return_to_lobby.rpc()


@rpc("call_local", "reliable")
func _reset_level():
	for node in get_tree().get_nodes_in_group("players"):
		if node.has_method("reset_level"):
			node.reset_level()
	for node in get_tree().get_nodes_in_group("level_resettable"):
		if node.has_method("reset_level"):
			node.reset_level()


## All levels done: drop the connection and reset state so the lobby's
## host/join flow starts fresh on both peers. The server keeps its peer
## alive for a moment so the reliable rpc flushes to clients before close.
@rpc("call_local", "reliable")
func _return_to_lobby() -> void:
	host_mode_enabled = false
	multiplayer_mode_enabled = false
	my_era = Era.NONE
	_player_spawn_node = null
	get_tree().change_scene_to_file.call_deferred(LOBBY_SCENE)

	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.is_server():
		await get_tree().create_timer(1.0).timeout
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null


@rpc("call_local", "reliable")
func _goto_level(level_index: int) -> void:
	_current_level = level_index
	get_tree().change_scene_to_file.call_deferred(levels[level_index])
