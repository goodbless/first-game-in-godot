extends Node2D
class_name ResetGroup

var _initial_visible := true
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("level_resettable")
	_initial_visible = visible


## Restore the state the trap spawned with — a switch may have hidden it
## mid-run (e.g. retracting spikes), and a failed level must bring it back.
func reset_level() -> void:
	visible = _initial_visible
