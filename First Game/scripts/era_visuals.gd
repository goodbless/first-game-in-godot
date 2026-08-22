extends Node

## Attach as a child node to give the parent era-filtered visuals.
## Expects sibling nodes named "PastVisual" / "FutureVisual" under the parent;
## each is shown only to its own era (both shown before anyone connects).
## Works on ANY parent node type — era skins without inheriting from a
## specific body base class.
##
## Scope support: if the parent has an "exists_in" property
## (0 = both eras, 1 = past only, 2 = future only), visuals of the
## non-existent era are hidden on EVERY peer — single-era objects are
## invisible to the wrong timeline.

const _SCOPE_PAST_ONLY := 1
const _SCOPE_FUTURE_ONLY := 2

func _ready() -> void:
	add_to_group("interactables")
	apply_era_visibility()


func apply_era_visibility() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var past_visual := parent.get_node_or_null("PastVisual")
	var future_visual := parent.get_node_or_null("FutureVisual")
	if past_visual != null:
		past_visual.visible = _visible_in(parent, MultiplayerManager.Era.PAST)
	if future_visual != null:
		future_visual.visible = _visible_in(parent, MultiplayerManager.Era.FUTURE)


func _visible_in(parent: Node, visual_era: int) -> bool:
	var existence = parent.get("exists_in")
	if existence != null:
		if existence == _SCOPE_PAST_ONLY and visual_era != MultiplayerManager.Era.PAST:
			return false
		if existence == _SCOPE_FUTURE_ONLY and visual_era != MultiplayerManager.Era.FUTURE:
			return false
	if MultiplayerManager.my_era == MultiplayerManager.Era.NONE:
		return true
	return MultiplayerManager.my_era == visual_era
