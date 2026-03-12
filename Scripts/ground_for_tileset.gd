extends StaticBody2D
class_name GroundTileset

@export var sprite : Sprite2D

func _ready() -> void:
	var parent : TileMapLayer= get_parent()
	material = parent.material
	sprite.material = material
