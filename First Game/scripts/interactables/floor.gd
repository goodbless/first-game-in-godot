extends StaticBody2D

## Static floor tile with era skins (EraVisuals child). exists_in scopes it
## to one timeline for era-exclusive terrain — e.g. a bridge that only
## exists in the future: the past player falls right through it.
## No sync needed: scene-placed identically on every peer.

enum Existence { BOTH, PAST_ONLY, FUTURE_ONLY }

@export var exists_in := Existence.BOTH:
	set(value):
		exists_in = value
		_apply_existence()


func _ready() -> void:
	_apply_existence()


func _apply_existence() -> void:
	collision_layer = MultiplayerManager.existence_layer(exists_in)
	var era_visuals := get_node_or_null("EraVisuals")
	if era_visuals != null:
		era_visuals.apply_era_visibility()
