class_name FPMoveState extends StateResource

enum MoveStates {
	IDLE,
	MOVING,
	JUMPING,
	FALLING,
	FROZEN
}

func bind(new:ComponentCore,indx:int) -> void:
	var movement_comp = new as FPMovementComponent
	state_owner = movement_comp
	assert(
		state_owner != null, 
		"FPS Move State requires its' owner to be of type FPMovementComponent."
		)
	finished.connect(movement_comp.on_state_transition)
	index = indx

func handle_input(_event:InputEvent) -> void: pass
