extends Area2D

## Spike trap: touching it kills — level fails for BOTH players (killzone
## semantics, server-side trigger). Skins differ per era via EraVisuals:
## gleaming spikes in the past, rusted jagged debris in the future.
## Scene-placed: set Y flush on the floor.

func _ready() -> void:
	collision_mask = 6
	body_entered.connect(_on_body_entered)


func _on_body_entered(body) -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		print("Spike trap hit: ", body.name, " — level failed for both")
		MultiplayerManager.notify_level_failed()