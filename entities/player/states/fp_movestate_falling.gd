class_name FPMS_Falling extends FPMoveState

##The amount of downward velocity needed for a landing signal-emission.
@export var fall_threshold : float = -7.0

var direction : Vector3 = Vector3.ZERO
var prev_state : int = -1
var character_body_ref : FPController

signal has_landed(fall_velocity:float,fall_threshold:float)

func bind(new:ComponentCore,indx:int) -> void:
	super.bind(new,indx)
	character_body_ref = new.owner

func enter(_prev_state:int,_data:={}) -> void: 
	if !_data.is_empty():
		var prev_velocity = _data["prev_velocity"]
		prev_state = _prev_state
		direction = Vector3(prev_velocity.x,direction.y,prev_velocity.z)
	else: direction = Vector3.ZERO

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
	var downward_velocity : float = snappedf(character_body_ref.velocity.y,0.01)
	
	character_body_ref.move_and_slide()
	
	var emit_landing : bool = (
		downward_velocity <= fall_threshold
		or prev_state == MoveStates.JUMPING
		)
	
	if character_body_ref.is_on_floor(): 
		if emit_landing:
			print("fall threshold breached!")
			has_landed.emit(downward_velocity,fall_threshold)
		
		if character_body_ref.get_desired_direction(): 
			finished.emit(MoveStates.MOVING,{"prev_velocity":direction})
		else: finished.emit(MoveStates.IDLE)

func exit() -> void: pass
