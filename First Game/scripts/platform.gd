extends AnimatableBody2D

@export var animation_player_optional: AnimationPlayer

func _on_player_connected(id: int) -> void:
    if not multiplayer.is_server():
        animation_player_optional.stop()
        animation_player_optional.active = false

func _ready() -> void:
    if animation_player_optional:
        multiplayer.peer_connected.connect(_on_player_connected)