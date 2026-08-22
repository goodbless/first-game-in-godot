extends Sprite2D

enum Existence { BOTH, PAST_ONLY, FUTURE_ONLY }

@export var exists_in := Existence.BOTH:
	set(value):
		exists_in = value
		_update_state()

func _update_state() -> void:
	if self.exists_in == Existence.BOTH:
		self.visible = true
	elif self.exists_in == MultiplayerManager.my_era:
		self.visible = true
	else:
		self.visible = false 
		
