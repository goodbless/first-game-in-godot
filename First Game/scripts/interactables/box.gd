extends "res://scripts/interactables/interactable_body.gd"

## Pushable crate. Server-authoritative physics; clients render the synced
## position — the future player sees it move "on its own".

const PUSH_SPEED := 40.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var push_left := $PushLeft
@onready var push_right := $PushRight


func _ready() -> void:
	super()
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	var push := 0
	for body in push_left.get_overlapping_bodies():
		if _can_interact(body):
			push = 1
	for body in push_right.get_overlapping_bodies():
		if _can_interact(body):
			push = -1

	velocity.x = push * PUSH_SPEED if push != 0 else 0.0

	move_and_slide()
