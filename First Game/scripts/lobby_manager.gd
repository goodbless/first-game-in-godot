extends Node

## Start screen / lobby: players connect here, the host picks a level,
## then both enter it together. Levels are auto-discovered from
## scenes/Levels/ — drop a .tscn there and it appears in the picker.

const START_DELAY := 1.2  # seconds between "both connected" and the level switch

var _starting := false

@onready var host_button = %HostGame
@onready var join_button = %JoinGame
@onready var status_label = %StatusLabel
@onready var level_select = %LevelSelect


func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	level_select.item_selected.connect(_on_level_selected)

	multiplayer.connected_to_server.connect(
		func(): _set_status("Connected — waiting for the past player..."))
	multiplayer.connection_failed.connect(
		func(): _set_status("Could not connect. Is the past player hosting?"))
	multiplayer.peer_connected.connect(_on_peer_connected)

	if OS.has_feature("dedicated_server"):
		MultiplayerManager.become_host()

	MultiplayerManager.refresh_levels()
	_populate_levels()


func _populate_levels() -> void:
	level_select.clear()
	for path in MultiplayerManager.levels:
		level_select.add_item(path.get_file().get_basename())
	if MultiplayerManager.levels.size() > 0:
		level_select.select(MultiplayerManager.selected_level())


## Host authority: once connected, only the server's pick counts — the
## client's dropdown is locked and mirror-synced via rpc.
func _on_level_selected(index: int) -> void:
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		level_select.select(MultiplayerManager.selected_level())
		return
	MultiplayerManager.select_level(index)
	if multiplayer.multiplayer_peer != null:
		_sync_level_select.rpc(index)


func _on_host_pressed() -> void:
	_hide_buttons()
	_set_status("Waiting for the future player...")
	MultiplayerManager.become_host()


func _on_join_pressed() -> void:
	_hide_buttons()
	level_select.disabled = true
	_set_status("Connecting...")
	MultiplayerManager.join_as_player_2()


func _on_peer_connected(_id: int) -> void:
	if not multiplayer.is_server() or _starting:
		return
	_starting = true
	var level_name := MultiplayerManager.levels[MultiplayerManager.selected_level()].get_file().get_basename()
	_set_status.rpc("Both eras connected — starting %s..." % level_name)
	await get_tree().create_timer(START_DELAY).timeout
	MultiplayerManager.start_game()


func _hide_buttons() -> void:
	host_button.hide()
	join_button.hide()


@rpc("authority", "call_local", "reliable")
func _set_status(text: String) -> void:
	status_label.text = text


@rpc("authority", "call_local", "reliable")
func _sync_level_select(index: int) -> void:
	level_select.select(index)
