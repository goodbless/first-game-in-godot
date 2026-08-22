@tool
extends EditorPlugin

## Lets you drag a node's "target_offset" property directly in the 2D
## viewport — a small handle is hit-tested at (node.position + target_offset).
## Works for any Node2D-based component that exposes target_offset (platforms,
## doors, whatever comes next). Visuals are drawn by each node's own _draw.
##
## Coordinate note: the 2D editor's pan/zoom lives in the SubViewport's
## VIEWPORT transform, not its canvas transform (which stays identity in the
## editor). Both screen->world and world->screen go through it.

const HANDLE_HIT_RADIUS := 12.0  # screen px, generous for fat-finger zooms

var _dragging := false


func _handles(object) -> bool:
	# Claim the object so the editor treats us as its active plugin —
	# 2D canvas input forwarding normally only reaches active plugins.
	return object is Node2D and "target_offset" in object


func _enter_tree() -> void:
	# Belt and suspenders with _handles: always receive forwarded input.
	set_input_event_forwarding_always_enabled()


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	var node := _selected_draggable()
	if node == null:
		_dragging = false
		return false

	var xf := node.get_viewport_transform()
	if xf == null:
		return false

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var handle_screen: Vector2 = xf * _target_world_pos(node)
			if event.position.distance_to(handle_screen) <= HANDLE_HIT_RADIUS:
				_dragging = true
				return true  # consumed — don't let the editor pick what's behind
		elif _dragging:
			_dragging = false
			return true
	elif event is InputEventMouseMotion and _dragging:
		var world: Vector2 = xf.affine_inverse() * event.position
		node.target_offset = _to_parent_space(node, world) - node.position
		return true

	return false


func _selected_draggable() -> Node2D:
	var selected := EditorInterface.get_selection().get_selected_nodes()
	if selected.is_empty():
		return null
	var node = selected[0]
	if node is Node2D and "target_offset" in node:
		return node
	return null


func _target_world_pos(node: Node2D) -> Vector2:
	var parent := node.get_parent()
	if parent is Node2D:
		return (parent as Node2D).global_transform * (node.position + node.target_offset)
	return node.global_position + node.target_offset


func _to_parent_space(node: Node2D, world: Vector2) -> Vector2:
	var parent := node.get_parent()
	if parent is Node2D:
		return (parent as Node2D).global_transform.affine_inverse() * world
	return world
