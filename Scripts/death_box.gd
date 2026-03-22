extends Area2D
class_name DeathBox

func _on_body_entered(body: Player) -> void:
	body.change_state(body.GET_DEADED)
	SwitchScene.reset()
