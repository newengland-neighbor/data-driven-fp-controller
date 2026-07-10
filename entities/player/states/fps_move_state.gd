class_name FPMoveState extends StateResource

enum MoveStates {
	IDLE,
	MOVING,
	JUMPING,
	FALLING,
	FROZEN
}

func bind(new:StateMachineComponent,indx:int) -> void:
	super.bind(new,indx)

func handle_input(_event:InputEvent) -> void: pass
