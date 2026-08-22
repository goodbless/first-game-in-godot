extends StaticBody2D

## Static floor tile with era skins (EraVisuals child). exists_in scopes it
## to one timeline for era-exclusive terrain — e.g. a bridge that only
## exists in the future: the past player falls right through it.
##
## The collision shape auto-fits the PastVisual sprite's texture size and
## scale — resize the sprite however you like (editable children) and the
## collision follows. No footgun of visible-vs-physical mismatch.
## FutureVisual should keep the same size as PastVisual.

enum Existence { BOTH, PAST_ONLY, FUTURE_ONLY }

@export var exists_in := Existence.BOTH:
	set(value):
		exists_in = value
		_apply_existence()


func _ready() -> void:
	_fit_collision_to_sprite()
	_apply_existence()


func _apply_existence() -> void:
	collision_layer = MultiplayerManager.existence_layer(exists_in)
	var era_visuals := get_node_or_null("EraVisuals")
	if era_visuals != null:
		era_visuals.apply_era_visibility()


func _fit_collision_to_sprite() -> void:
	var sprite := get_node_or_null("PastVisual/Sprite2D")
	var collision := get_node_or_null("CollisionShape2D")
	if sprite == null or collision == null or sprite.texture == null:
		return
	var shape := RectangleShape2D.new()
	shape.size = sprite.texture.get_size() * sprite.scale
	collision.shape = shape
	collision.position = sprite.position
