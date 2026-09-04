class_name FPMoveState extends StateResource

enum MoveStates {
	ON_GROUND,
	IN_AIR,
	FROZEN
}

func bind(new:StateMachineComponent,indx:int) -> void:
	super.bind(new,indx)

func handle_input(_event:InputEvent) -> void: pass

func get_state_name() -> String:
	match index:
		MoveStates.ON_GROUND: return "OnGround"
		MoveStates.IN_AIR: return "InAir"
		MoveStates.FROZEN: return "Frozen"
		_: return "Nil"
