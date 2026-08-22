extends AnimatableBody2D

## Moving platform, code-driven — no AnimationPlayer wiring needed.
## Inspector: move_distance (0 = static), move_axis, cycle_time, phase.
## The sine curve eases at both ends so riders are never flung.
##
## Server-side only: clients get the position via the MultiplayerSynchronizer.
## Legacy: an externally wired AnimationPlayer still works if provided.

@export var move_distance := 0.0        ## px; 0 = static (unmoved)
@export var cycle_time := 4.0           ## seconds per full back-and-forth
@export var move_axis := Vector2.RIGHT  ## travel direction
@export var phase := 0.0                ## 0..1, stagger multiple platforms

@export var animation_player_optional: AnimationPlayer

var _origin: Vector2
var _t := 0.0


func _ready() -> void:
	_origin = position
	if not multiplayer.is_server():
		if animation_player_optional != null:
			animation_player_optional.stop()
			animation_player_optional.active = false
		set_physics_process(false)  # position arrives via sync


func _physics_process(delta: float) -> void:
	if animation_player_optional != null or move_distance <= 0.0 or cycle_time <= 0.0:
		return
	_t = fmod(_t + delta / cycle_time, 1.0)
	position = _origin + move_axis * (move_distance * sin(TAU * (_t + phase)))
