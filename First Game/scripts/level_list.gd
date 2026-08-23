class_name LevelList
extends Resource

## Configurable level order for the lobby picker and level progression.
## Edit res://config/level_list.tres in the Inspector: reorder, rename,
## add or remove LevelDef entries.

@export var levels: Array[LevelDef] = []
