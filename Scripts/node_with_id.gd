extends Node
class_name NodeWithID

@export var id : int = 1
@export var box : BoxInterfaceGridContainer
@export var collision_2d : Array[Node2D]

func _physics_process(_delta: float) -> void:
	_update()

func _update() -> void:
	if box.child_ids.find(id) != -1:
		for child in collision_2d:
			child.disabled = true
		for child : Node2D in get_children():
			child.visible = false
		if "freeze" in self:
			self.freeze = true
	else:
		for child in collision_2d:
			child.disabled = false
		for child : Node2D in get_children():
			child.visible = true
		if "freeze" in self:
			self.freeze = false
