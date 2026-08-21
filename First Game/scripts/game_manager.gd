extends Node

## Per-level flow controller: HUD wiring, respawn scheduling, win/lose.

const PLAYER_RESPAWN_DELAY := 1.0

@onready var multiplayer_hud = %MultiplayerHUD


func _ready() -> void:
	_connect_hud()

	if OS.has_feature("dedicated_server"):
		print("Running as dedicated server")
		MultiplayerManager.become_host()

	if MultiplayerManager.multiplayer_mode_enabled:
		MultiplayerManager._remove_single_player()
		if multiplayer.is_server():
			await get_tree().create_timer(PLAYER_RESPAWN_DELAY).timeout
			MultiplayerManager.respawn_all_players()


func _connect_hud() -> void:
	if multiplayer_hud == null:
		return
	multiplayer_hud.get_node("Panel/VBoxContainer/HostGame").pressed.connect(become_host)
	multiplayer_hud.get_node("Panel/VBoxContainer/JoinAsPlayer2").pressed.connect(join_as_player_2)


func become_host():
	multiplayer_hud.hide()
	MultiplayerManager.become_host()


func join_as_player_2():
	multiplayer_hud.hide()
	MultiplayerManager.join_as_player_2()
