extends Node

## Per-level flow controller: loading screen, respawn scheduling, win/lose.

const PLAYER_RESPAWN_DELAY := 1.0

var loading_scene = preload("res://scenes/ui/loading_screen.tscn")

@onready var multiplayer_hud = get_node_or_null("%MultiplayerHUD")


func _ready() -> void:
	_connect_hud()
	_spawn_loading_screen()

	if OS.has_feature("dedicated_server"):
		print("Running as dedicated server")
		MultiplayerManager.become_host()

	if MultiplayerManager.multiplayer_mode_enabled and multiplayer.is_server():
		await get_tree().create_timer(PLAYER_RESPAWN_DELAY).timeout
		MultiplayerManager.respawn_all_players()


func _connect_hud() -> void:
	if multiplayer_hud == null:
		return
	multiplayer_hud.get_node("Panel/VBoxContainer/HostGame").pressed.connect(become_host)
	multiplayer_hud.get_node("Panel/VBoxContainer/JoinAsPlayer2").pressed.connect(join_as_player_2)


## Full-screen cover shown on level entry; the player controller hides it
## (group "loading_screen") the instant the local player spawns.
func _spawn_loading_screen() -> void:
	if not MultiplayerManager.multiplayer_mode_enabled:
		return
	get_tree().current_scene.add_child(loading_scene.instantiate())


func become_host():
	multiplayer_hud.hide()
	MultiplayerManager.become_host()


func join_as_player_2():
	multiplayer_hud.hide()
	MultiplayerManager.join_as_player_2()
