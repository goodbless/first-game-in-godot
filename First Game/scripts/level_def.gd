class_name LevelDef
extends Resource

## One entry in the level list config: display name + level scene.
## Name falls back to the scene's filename when left empty.

@export var level_name: String = ""
@export var scene: PackedScene


func display_name() -> String:
	if level_name != "":
		return level_name
	if scene != null:
		return scene.resource_path.get_file().get_basename()
	return "Unnamed level"
