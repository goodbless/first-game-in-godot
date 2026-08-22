extends StaticBody2D

## Breakable vase. The past player interacts (E) while nearby — it shatters in
## BOTH eras: the future player sees it "suddenly" explode into debris.
## Scene-placed: set Y flush on the floor. Era visuals via EraVisuals child.
## Static since it never moves; shattering only toggles its collision layer.

@export var owner_era := 1  ## 1 = past player, 2 = future player

var broken := false:
	set(value):
		if broken == value:
			return
		broken = value
		_update_state()

@onready var sensor := $Sensor


func _ready() -> void:
	add_to_group("level_resettable")
	_update_state()


func _process(_delta: float) -> void:
	if broken:
		return
	var bodies: Array = sensor.get_overlapping_bodies()
	_update_hint(bodies)
	for body in bodies:
		if _can_interact(body) and Input.is_action_just_pressed("interact"):
			request_break.rpc()
			return


func _can_interact(body) -> bool:
	return body is CharacterBody2D and "player_id" in body \
		and MultiplayerManager.era_of(body.player_id) == owner_era


func _update_hint(bodies: Array) -> void:
	var hint := get_node_or_null("Hint")
	if hint == null:
		return
	var show_hint := false
	for body in bodies:
		if _can_interact(body) and body.player_id == multiplayer.get_unique_id():
			show_hint = true
			break
	hint.visible = show_hint


func _update_state() -> void:
	for visual in [get_node_or_null("PastVisual"), get_node_or_null("FutureVisual")]:
		if visual == null:
			continue
		if broken:
			visual.modulate = Color(0.35, 0.3, 0.25, 1)
			visual.scale = Vector2(1.0, 0.35)
			visual.position = Vector2(0, 6)
		else:
			visual.modulate = Color(1, 1, 1, 1)
			visual.scale = Vector2(1, 1)
			visual.position = Vector2.ZERO
	collision_layer = 0 if broken else 1
	if broken:
		var hint := get_node_or_null("Hint")
		if hint != null:
			hint.visible = false


@rpc("any_peer", "call_local", "reliable")
func request_break() -> void:
	if not multiplayer.is_server() or broken:
		return
	if MultiplayerManager.era_of(multiplayer.get_remote_sender_id()) != owner_era:
		return
	broken = true


func reset_level() -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		broken = false
