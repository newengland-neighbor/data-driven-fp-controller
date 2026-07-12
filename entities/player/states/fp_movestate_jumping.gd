class_name FPMS_Jumping extends FPMoveState

##The strength of the player's jump. Higher values => higher jumps.
@export var jump_force : float = 7.5

var direction : Vector3 = Vector3.ZERO
var character_body_ref : FPController

signal has_jumped

func bind(new:ComponentCore,indx:int) -> void:
	super.bind(new,indx)
	character_body_ref = new.owner

func enter(_prev_state:int,_data:={}) -> void: 
	# Receive previous velocity data (if any) to influence the horizontal movement of the jump.
	if !_data.is_empty():
		var prev_velocity = _data["prev_velocity"]
		direction = Vector3(prev_velocity.x,direction.y,prev_velocity.z)
	if _prev_state != MoveStates.FROZEN: character_body_ref.velocity.y = jump_force
	has_jumped.emit()

func handle_input(_event:InputEvent) -> void: pass
func update(_delta:float) -> void: pass

func physics_update(_delta:float) -> void:
	direction = MathPlus.v3_exp_decay(
		direction,
		character_body_ref.get_desired_direction(),
		MathPlus.DECAY,
		_delta
		)
	
	if direction:
		character_body_ref.velocity.x = direction.x * character_body_ref.get_total_speed()
		character_body_ref.velocity.z = direction.z * character_body_ref.get_total_speed()
	
	character_body_ref.velocity.y += -9.8 * 3.0 * _delta
	character_body_ref.move_and_slide()
	
	if character_body_ref.velocity.y <= 0.0: 
		finished.emit(MoveStates.FALLING,{"prev_velocity":direction})

func exit() -> void: pass
