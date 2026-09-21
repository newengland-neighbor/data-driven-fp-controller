class_name FPMoveState extends StateResource

## Value used to control how fast the player's velocity interpolates to the desired movement direction.
@export var move_acceleration : float = 1.0
## Value used to control the speed at which the player stops moving once no input is being registered.
@export var move_drag : float = 1.0

const ON_GROUND : String = "OnGround"
const IN_AIR : String = "InAir"
const FROZEN : String = "Frozen"

func bind(new:StateMachineComponent) -> void:
	super.bind(new)

func handle_input(_event:InputEvent) -> void: pass

func get_state_name() -> String:
	if self is FPMS_OnGround: return ON_GROUND
	elif self is FPMS_InAir: return IN_AIR
	elif self is FPMS_IsFrozen: return FROZEN
	return "Nil"
