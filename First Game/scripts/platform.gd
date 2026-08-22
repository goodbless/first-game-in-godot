extends AnimatableBody2D

@export var animation_player_optional: AnimationPlayer


func _ready() -> void:
	# Levels load after the lobby handshake, so peer state is already settled
	# here: the server keeps animating (position syncs to clients), clients
	# kill their local animation immediately.
	if animation_player_optional != null and not multiplayer.is_server():
		animation_player_optional.stop()
		animation_player_optional.active = false
