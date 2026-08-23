extends Node2D
class_name ResetGroup

var initial_active := true
@export var active := true:
 set(value):
    active = value
    _update_state()
    
func set_active(value: bool):
    active = value
    
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    add_to_group("level_resettable")
    initial_active = active
    _update_state()


## Restore the state the trap spawned with — a switch may have hidden it
## mid-run (e.g. retracting spikes), and a failed level must bring it back.
func reset_level() -> void:
    active = initial_active
    
func _update_state() -> void:
    for child in self.get_children():
        if child is Area2D:
            child.set_deferred("monitoring", active)
            child.set_deferred("visible", active)
