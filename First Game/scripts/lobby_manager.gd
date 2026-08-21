extends Node

## Start screen / lobby: players connect here, then both enter level 1 together.

const START_DELAY := 1.2  # seconds between "both connected" and the level switch

var _starting := false

@onready var host_button = %HostGame
@onready var join_button = %JoinGame
@onready var status_label = %StatusLabel


func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)

	multiplayer.connected_to_server.connect(
		func(): _set_status("Connected — waiting for the past player..."))
	multiplayer.connection_failed.connect(
		func(): _set_status("Could not connect. Is the past player hosting?"))
	multiplayer.peer_connected.connect(_on_peer_connected)

	if OS.has_feature("dedicated_server"):
		MultiplayerManager.become_host()


func _on_host_pressed() -> void:
	_hide_buttons()
	_set_status("Waiting for the future player...")
	MultiplayerManager.become_host()


func _on_join_pressed() -> void:
	_hide_buttons()
	_set_status("Connecting...")
	MultiplayerManager.join_as_player_2()


func _on_peer_connected(_id: int) -> void:
	if not multiplayer.is_server() or _starting:
		return
	_starting = true
	_set_status.rpc("Both eras connected — starting level 1...")
	await get_tree().create_timer(START_DELAY).timeout
	MultiplayerManager.start_game()


func _hide_buttons() -> void:
	host_button.hide()
	join_button.hide()


@rpc("authority", "call_local", "reliable")
func _set_status(text: String) -> void:
	status_label.text = text
