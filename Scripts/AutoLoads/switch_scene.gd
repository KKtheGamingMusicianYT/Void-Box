extends Node

func switch_to(scene : StringName) -> void:
	var timer = get_tree().create_timer(3.0)
	await timer.timeout
	get_tree().change_scene_to_file.call_deferred(scene)

func reset() -> void:
	var timer = get_tree().create_timer(3.0)
	await timer.timeout
	get_tree().reload_current_scene.call_deferred()
