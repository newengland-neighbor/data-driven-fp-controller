class_name FPMoveState extends StateResource

enum MoveStates {
	ON_GROUND,
	IN_AIR,
	FROZEN
}

func bind(new:StateMachineComponent,indx:int) -> void:
	super.bind(new,indx)

func handle_input(_event:InputEvent) -> void: pass
