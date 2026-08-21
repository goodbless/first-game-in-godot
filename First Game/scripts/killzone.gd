extends Area2D

func _on_body_entered(body):
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		print("Player died: ", body.name, " — level failed for both")
		MultiplayerManager.notify_level_failed()
