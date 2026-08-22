extends Marker2D

## Era spawn marker: where the era's player (re)spawns. Place one per era
## per level; falls back to the Players node when absent.
## The editor hint label hides at runtime — markers are invisible in-game.
## If several markers share an era, the first one found wins.

@export var spawn_era := 1  ## 1 = past player, 2 = future player


func _ready() -> void:
	add_to_group("spawn_points")
	if not Engine.is_editor_hint():
		var hint := get_node_or_null("EditorHint")
		if hint != null:
			hint.hide()
