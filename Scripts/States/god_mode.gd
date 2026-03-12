extends State
class_name GodMode

var parent : CharacterBody

func enter() -> void:
	enter_ran = true

func exit() -> void:
	pass
	
func update() -> void:
	parent.velocity = parent.properties.VELOCITY

func recieve_state_machine(reference: StateMachine) -> void:
	parent = reference.parent
