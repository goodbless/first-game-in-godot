extends CanvasLayer

## Full-screen cover shown on level entry until the local player spawns.
## game_manager instantiates this; multiplayer_controller hides it via the
## "loading_screen" group.


func _ready() -> void:
	add_to_group("loading_screen")
	$Label.text = _era_text()


func _era_text() -> String:
	if MultiplayerManager.is_past():
		return "Rewinding to the past..."
	elif MultiplayerManager.is_future():
		return "Fast-forwarding to the future..."
	return "Synchronizing timelines..."
