extends Area2D

## Spike trap: touching it kills — level fails for BOTH players (killzone
## semantics, server-side trigger). Skins differ per era via EraVisuals.
##
## exists_in scopes the trap to one timeline: single-era traps are invisible
## AND intangible (wrong mask) to the other era's player.

enum Existence { BOTH, PAST_ONLY, FUTURE_ONLY }

@export var exists_in := Existence.BOTH:
	set(value):
		exists_in = value
		_apply_existence()


func _ready() -> void:
	_apply_existence()
	body_entered.connect(_on_body_entered)


func _apply_existence() -> void:
	match exists_in:
		Existence.PAST_ONLY:
			collision_mask = 2
			_drop_visual("FutureVisual")
		Existence.FUTURE_ONLY:
			collision_mask = 4
			_drop_visual("PastVisual")
		_:
			collision_mask = 6


## Remove the other timeline's visual node entirely — EraVisuals then finds
## nothing to show for that era, so no visibility-fight between the two systems.
func _drop_visual(node_name: String) -> void:
	var visual := get_node_or_null(node_name)
	if visual != null:
		visual.queue_free()


func _on_body_entered(body) -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		print("Spike trap hit: ", body.name, " — level failed for both")
		MultiplayerManager.notify_level_failed()
