extends AnimatableBody2D

## Moving platform, code-driven and simulated IDENTICALLY on every peer.
## The sine formula is deterministic, so clients run it locally (smooth,
## zero-latency) and only receive a low-frequency phase correction from
## the server — this mirrors the host's rendering setup, which tests showed
## is the artifact-free configuration.

@export var move_distance := 0.0        ## px; 0 = static
@export var cycle_time := 4.0           ## seconds per full back-and-forth
@export var move_axis := Vector2.RIGHT  ## travel direction
@export var phase := 0.0                ## 0..1, stagger multiple platforms

const PHASE_SYNC_INTERVAL := 0.5

var _origin: Vector2
var _t := 0.0
var _sync_accum := 0.0

## Synced (ON_CHANGE) from the server as a drift correction; clients snap
## their local _t to it on receive.
var _t_sync := 0.0:
	set(value):
		_t_sync = value
		_correct_phase(value)


func _ready() -> void:
	_origin = position


func _physics_process(delta: float) -> void:
	if move_distance <= 0.0 or cycle_time <= 0.0:
		return
	_t = fmod(_t + delta / cycle_time, 1.0)
	position = _origin + move_axis * (move_distance * sin(TAU * (_t + phase)))
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		_sync_accum += delta
		if _sync_accum >= PHASE_SYNC_INTERVAL:
			_sync_accum = 0.0
			_t_sync = _t


func _correct_phase(server_t: float) -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		return
	var diff := server_t - _t
	if diff > 0.5:
		diff -= 1.0  # shortest path around the cycle
	elif diff < -0.5:
		diff += 1.0
	if abs(diff) < 0.001:
		return
	_t = fmod(_t + diff, 1.0)
