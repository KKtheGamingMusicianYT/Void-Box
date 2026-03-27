extends Area2D
class_name DeathBox

@export var level : PackedScene

func _ready() -> void:
	level = load(get_tree().current_scene.scene_file_path)

func _on_body_entered(body: Player) -> void:
	body.change_state(body.GET_DEADED)
	SwitchScene.switch_to(level.resource_path, 3)
