extends AnimatableBody2D

## Moving platform, code-driven and simulated IDENTICALLY on every peer.
## The sine formula is deterministic, so clients run it locally (smooth,
## zero-latency) and only receive a low-frequency phase correction from
## the server — this mirrors the host's rendering setup, which tests showed
## is the artifact-free configuration.
##
## Optional crumbling: after a player stands on it for crumble_time, the
## platform breaks and disappears, then respawns after respawn_time.
## crumble_time = 0 (default) keeps the platform solid forever.

@export var move_distance := 0.0        ## px; 0 = static
@export var cycle_time := 4.0           ## seconds per full back-and-forth
@export var move_axis := Vector2.RIGHT  ## travel direction
@export var phase := 0.0                ## 0..1, stagger multiple platforms
@export var crumble_time := 0.0         ## seconds standing before breaking; 0 = solid
@export var respawn_time := 3.0         ## seconds before a broken platform returns; <= 0 = only level reset restores it

const PHASE_SYNC_INTERVAL := 0.5
const COOLDOWN_RATE := 2.0  ## how much faster the crumble timer cools than it fills

var _origin: Vector2
var _t := 0.0
var _sync_accum := 0.0
var _crumble_accum := 0.0
var _respawn_accum := 0.0
var _flicker_t := 0.0

## Synced (ON_CHANGE) from the server as a drift correction; clients snap
## their local _t to it on receive.
var _t_sync := 0.0:
	set(value):
		_t_sync = value
		_correct_phase(value)

## Synced crumble state — server decides, everyone applies locally.
var broken := false:
	set(value):
		if broken == value:
			return
		broken = value
		_apply_broken()

## Synced pre-break warning — clients flicker their sprites while true.
var warning := false:
	set(value):
		if warning == value:
			return
		warning = value


@onready var rider_sensor := $RiderSensor


func _ready() -> void:
	add_to_group("level_resettable")
	_origin = position


func _physics_process(delta: float) -> void:
	if move_distance > 0.0 and cycle_time > 0.0:
		_t = fmod(_t + delta / cycle_time, 1.0)
		position = _origin + move_axis * (move_distance * sin(TAU * (_t + phase)))

	_update_flicker(delta)

	if not multiplayer.is_server():
		return

	if multiplayer.multiplayer_peer != null:
		_sync_accum += delta
		if _sync_accum >= PHASE_SYNC_INTERVAL:
			_sync_accum = 0.0
			_t_sync = _t

	if crumble_time <= 0.0:
		return

	if broken:
		if respawn_time <= 0.0:
			return  # stays broken until the level resets
		_respawn_accum += delta
		if _respawn_accum >= respawn_time:
			_respawn_accum = 0.0
			_crumble_accum = 0.0
			warning = false
			broken = false
	elif _has_rider():
		_crumble_accum += delta
		if _crumble_accum >= crumble_time:
			_crumble_accum = 0.0
			_respawn_accum = 0.0
			warning = false
			broken = true
		else:
			warning = _crumble_accum > crumble_time * 0.5
	else:
		_crumble_accum = max(_crumble_accum - delta * COOLDOWN_RATE, 0.0)
		warning = false


func reset_level() -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		_crumble_accum = 0.0
		_respawn_accum = 0.0
		warning = false
		broken = false


func _has_rider() -> bool:
	for body in rider_sensor.get_overlapping_bodies():
		if body is CharacterBody2D and "player_id" in body:
			return true
	return false


func _apply_broken() -> void:
	collision_layer = 0 if broken else 1
	for sprite in [get_node_or_null("PastVisual/Sprite2D"), get_node_or_null("FutureVisual/Sprite2D")]:
		if sprite != null:
			sprite.visible = not broken


func _update_flicker(delta: float) -> void:
	if warning and not broken:
		_flicker_t += delta * 25.0
		var alpha := 0.55 + 0.45 * sin(_flicker_t)
		for sprite in [get_node_or_null("PastVisual/Sprite2D"), get_node_or_null("FutureVisual/Sprite2D")]:
			if sprite != null:
				sprite.self_modulate.a = alpha
	else:
		_flicker_t = 0.0
		for sprite in [get_node_or_null("PastVisual/Sprite2D"), get_node_or_null("FutureVisual/Sprite2D")]:
			if sprite != null:
				sprite.self_modulate.a = 1.0


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
