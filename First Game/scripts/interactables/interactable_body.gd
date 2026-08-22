extends CharacterBody2D

## Physics-body base for era-aware interactables: era ownership checks,
## level reset and server-side gravity helpers. Era visuals are delegated to
## a dynamically added EraVisuals child (composition) so the same logic
## stays reusable on non-CharacterBody2D nodes.

const EraVisualsScript := preload("res://scripts/era_visuals.gd")

@export var owner_era := 1  ## 1 = past player, 2 = future player

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var _initial_position: Vector2


func _ready() -> void:
	add_to_group("level_resettable")
	_initial_position = position
	var era_visuals := Node.new()
	era_visuals.name = "EraVisuals"
	era_visuals.set_script(EraVisualsScript)
	add_child(era_visuals)


## Server-side gravity (velocity only — caller decides when to slide).
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0


## Server-side gravity + move, for static objects that just settle on the
## floor. Clients never call this (position syncs instead).
func _settle(delta: float) -> void:
	_apply_gravity(delta)
	move_and_slide()


func _hide_hint() -> void:
	var hint := get_node_or_null("Hint")
	if hint != null:
		hint.visible = false


## Show/hide the "[E]" hint: visible only when the LOCAL player (this
## machine's own character) is inside the sensor and may interact.
func _update_hint(sensor_bodies: Array) -> void:
	var hint := get_node_or_null("Hint")
	if hint == null:
		return
	var show_hint := false
	for body in sensor_bodies:
		if _can_interact(body) and body.player_id == multiplayer.get_unique_id():
			show_hint = true
			break
	hint.visible = show_hint


func _can_interact(body) -> bool:
	return body is CharacterBody2D and "player_id" in body \
		and MultiplayerManager.era_of(body.player_id) == owner_era


func reset_level() -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		position = _initial_position
		velocity = Vector2.ZERO
