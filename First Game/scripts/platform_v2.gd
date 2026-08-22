@tool
extends AnimatableBody2D

## Platform v2 — destination-offset movement + touch-triggered crumble.
##
## Movement: set "target_offset" in the Inspector to where the platform should
## travel (relative to its placed position). The editor viewport previews the
## destination as a ghost sprite with a guide line — no editable-children
## needed. At runtime the platform ping-pongs between its spawn position and
## spawn position + target_offset. Vector2.ZERO (or a tiny offset) means
## static.
##
## Crumble: touching the platform ONCE starts an unstoppable countdown.
## Leaving early no longer pauses it — it breaks when the timer runs out.
## crumble_time = 0 (default) keeps the platform solid forever.

@export var cycle_time := 4.0           ## seconds per full back-and-forth
@export var phase := 0.0                ## 0..1, stagger multiple platforms
@export var target_offset := Vector2(300, 0):  ## travel destination relative to spawn; ZERO = static
	set(value):
		target_offset = value
		if Engine.is_editor_hint() and is_inside_tree():
			queue_redraw()
@export var crumble_time := 0.0         ## countdown length after first touch; 0 = solid
@export var respawn_time := 3.0         ## seconds before a broken platform returns; <= 0 = only level reset restores it

const PHASE_SYNC_INTERVAL := 0.5
const STATIC_EPSILON := 1.0  ## px; travel shorter than this counts as static

var _t := 0.0
var _sync_accum := 0.0
var _crumble_accum := 0.0
var _respawn_accum := 0.0
var _flicker_t := 0.0
var _triggered := false
var _is_moving := false

var _origin: Vector2

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
	if Engine.is_editor_hint():
		return
	add_to_group("level_resettable")
	_origin = position
	_is_moving = target_offset.length() > STATIC_EPSILON and cycle_time > 0.0


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var sprite := get_node_or_null("PastVisual/Sprite2D") as Sprite2D
	if sprite != null and sprite.texture != null:
		var tex_size: Vector2 = sprite.texture.get_size()
		draw_texture_rect(sprite.texture, Rect2(target_offset - tex_size * 0.5, tex_size), false, Color(1.0, 1.0, 1.0, 0.35))
	draw_line(Vector2.ZERO, target_offset, Color(0.55, 0.75, 1.0, 0.5), 1.5)
	# Draggable handle (see addons/platform_target_handle) — draw a bright dot
	# in unscaled screen-ish size by compensating the view zoom.
	var handle_radius := 10.0 / maxf(get_viewport_transform().get_scale().x, 0.001)
	draw_circle(target_offset, handle_radius, Color(0.35, 0.65, 1.0, 0.9))
	draw_circle(target_offset, handle_radius * 0.45, Color.WHITE)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _is_moving:
		_t = fmod(_t + delta / cycle_time, 1.0)
		# 0 at t=0 (spawn), 1 at half a cycle (target), back to 0.
		var factor := 0.5 - 0.5 * cos(TAU * (_t + phase))
		position = _origin + target_offset * factor

	_update_flicker(delta)

	if not multiplayer.is_server():
		return

	if multiplayer.multiplayer_peer != null and _is_moving:
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
			_triggered = false
			warning = false
			broken = false
	elif _triggered:
		# Countdown runs to completion even if the rider hops off.
		_crumble_accum += delta
		if _crumble_accum >= crumble_time:
			_crumble_accum = 0.0
			_respawn_accum = 0.0
			warning = false
			broken = true
		else:
			warning = _crumble_accum > crumble_time * 0.5
	else:
		_triggered = _has_rider()


func reset_level() -> void:
	# Local sim state — reset identically on every peer, no sync conflict.
	_t = 0.0
	_crumble_accum = 0.0
	_respawn_accum = 0.0
	_triggered = false
	if _is_moving:
		position = _origin
	# Synced state — server only; ON_CHANGE rebroadcasts to clients.
	if multiplayer.is_server():
		warning = false
		broken = false
		_t_sync = _t


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
