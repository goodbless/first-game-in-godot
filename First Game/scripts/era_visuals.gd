extends Node

## Attach as a child node to give the parent era-filtered visuals.
## Expects sibling nodes named "PastVisual" / "FutureVisual" under the parent;
## each is shown only to its own era (both shown before anyone connects).
## Works on ANY parent node type — era skins without inheriting from a
## specific body base class.

func _ready() -> void:
	add_to_group("interactables")
	apply_era_visibility()


func apply_era_visibility() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var past_visual := parent.get_node_or_null("PastVisual")
	var future_visual := parent.get_node_or_null("FutureVisual")
	if MultiplayerManager.my_era == MultiplayerManager.Era.FUTURE:
		if past_visual != null:
			past_visual.visible = false
		if future_visual != null:
			future_visual.visible = true
	else:
		if past_visual != null:
			past_visual.visible = true
		if future_visual != null:
			future_visual.visible = false
