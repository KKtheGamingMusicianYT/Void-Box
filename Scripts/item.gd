extends Button
class_name Item
@export var item : ItemData
@export var id : int = 0
@export var object : NodeWithID
@onready var point_light_2d: PointLight2D = $PointLight2D
var parent : BoxInterfaceGridContainer
var hidden_icon : Texture2D
var mouse_down : bool

func _ready() -> void:
	mouse_down = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	icon = item.icon
	expand_icon = true
	hidden_icon = icon

func _process(_delta: float) -> void:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		mouse_down = false
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		self_modulate.a = 100
		icon = hidden_icon
	if icon == null:
		point_light_2d.visible = false
	else:
		point_light_2d.visible = true

func recieve_parent(reference: BoxInterfaceGridContainer) -> void:
	parent = reference

func _get_drag_data(_at_position: Vector2) -> Variant:
	# If there is no item, do not drag
	if item == null or item.icon == null:
		return
	_create_preview()
	icon = null
	return self

func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	if mouse_down == true:
		return false
	return true

func _drop_data(_at_position: Vector2, Data: Variant) -> void:
	var data : Item = Data
	if parent != data.parent:
		if parent.get_volume_of_children() + data.item.volume - item.volume > parent.volume_limit:
			return
		if data.parent.get_volume_of_children() + item.volume - data.item.volume > data.parent.volume_limit:
			return
	data.parent.get_id_of_children()
	_swap_properties(data)
func _create_preview() -> void:
	var preview : Button = duplicate()
	var control_for_preview = Control.new()
	# Add the preview to the control node's tree
	control_for_preview.add_child(preview)
	# Adjust the position
	preview.position = Vector2(-64, -64)
	set_drag_preview(control_for_preview)
	
func _swap_properties(data : Item) -> void:
	# Swap the properties
	var item_swapped = item
	item = data.item
	data.item = item_swapped
	
	var id_swapped = id
	id = data.id
	data.id = id_swapped
	
	icon = item.icon
	data.icon = data.item.icon
	
	var material_swapped = material
	material = data.material
	data.material = material_swapped
	
	var hidden_icon_swapped = hidden_icon
	hidden_icon = data.hidden_icon
	data.hidden_icon = hidden_icon_swapped
	
	parent.get_id_of_children()
	data.parent.get_id_of_children()
