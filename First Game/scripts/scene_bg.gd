extends Sprite2D
const SCENE_LAB_UID := "uid://fsyoba3sfmwd"
const SCENE_LAB_02_UID := "uid://c4hxvsu2aguig"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if MultiplayerManager.my_era == MultiplayerManager.Era.PAST:
		texture = load(SCENE_LAB_UID)
	else:
		texture = load(SCENE_LAB_02_UID)
