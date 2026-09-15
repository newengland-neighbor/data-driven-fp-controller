class_name FPMoveState extends StateResource

##Value used to control how fast the player's velocity interpolates to the desired movement direction.
@export var move_acceleration : float = 1.0
##Value used to control the speed at which the player stops moving once no input is being registered.
@export var move_drag : float = 1.0

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
