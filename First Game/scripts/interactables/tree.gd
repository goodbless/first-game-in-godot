extends AnimatableBody2D

## Decorative climbable tree with era skins (EraVisuals child). exists_in
## scopes it to one timeline for era-exclusive terrain — a past-only tree
## is intangible and invisible to the future player.

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

func play() -> void:
	var anim : AnimationPlayer = get_node_or_null("AnimationPlayer")
	anim.play("up")
