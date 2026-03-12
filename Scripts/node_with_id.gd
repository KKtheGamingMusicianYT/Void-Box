extends Node
class_name NodeWithID

@export var id : int = 1
@export var box : BoxInterfaceGridContainer
@export var collision_2d : Node2D
@export var sprite_2d: Node2D

func _process(_delta: float) -> void:
	if box.child_ids.find(id) != -1:
		collision_2d.disabled = true
		sprite_2d.visible = false
		if "freeze" in self:
			self.freeze = true
	else:
		collision_2d.disabled = false
		sprite_2d.visible = true
		if "freeze" in self:
			self.freeze = false
