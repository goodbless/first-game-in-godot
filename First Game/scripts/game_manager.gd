extends Node

const PLAYER_RESPAWN_DELAY := 1.0

@onready var multiplayer_hud = %MultiplayerHUD


func _ready() -> void:
	if OS.has_feature("dedicated_server"):
		print("Running as dedicated server")
		MultiplayerManager.become_host()

	if MultiplayerManager.multiplayer_mode_enabled:
		MultiplayerManager._remove_single_player()
		if multiplayer.is_server():
			await get_tree().create_timer(PLAYER_RESPAWN_DELAY).timeout
			MultiplayerManager.respawn_all_players()


func become_host():
	multiplayer_hud.hide()
	MultiplayerManager.become_host()


func join_as_player_2():
	multiplayer_hud.hide()
	MultiplayerManager.join_as_player_2()
