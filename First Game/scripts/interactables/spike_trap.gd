extends Area2D

## Spike trap: touching it kills — level fails for BOTH players (killzone
## semantics, server-side trigger). Skins differ per era via EraVisuals.
##
## exists_in scopes the trap to one timeline (synced, runtime-changeable):
## single-era traps are invisible AND intangible to the other era's player.
enum Existence { BOTH, PAST_ONLY, FUTURE_ONLY }

@export var exists_in := Existence.BOTH:
	set(value):
		exists_in = value
		_apply_existence()


func _ready() -> void:
	_apply_existence()
	body_entered.connect(_on_body_entered)


func _apply_existence() -> void:
	collision_mask = MultiplayerManager.existence_trigger_mask(exists_in)
	var era_visuals := get_node_or_null("EraVisuals")
	if era_visuals != null:
		era_visuals.apply_era_visibility()


func _on_body_entered(body) -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		print("Spike trap hit: ", body.name, " — level failed for both")
		MultiplayerManager.notify_level_failed()
