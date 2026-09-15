class_name FPMS_InAir extends FPMoveState

##The strength of the player's jump. Higher values => higher jumps.
@export var jump_force : float = 7.5
##The amount of downward velocity needed for a landing signal-emission.
@export var fall_threshold : float = -7.0

var character_body_ref : FPController

var lerped_velo : Vector3 = Vector3.ZERO
var jumped : bool

signal has_landed(fall_velocity:float,fall_threshold:float)
signal has_jumped
signal request_sound(key:String)

func bind(new:ComponentCore,indx:int) -> void:
	super.bind(new,indx)
	character_body_ref = new.owner
	request_sound.connect(character_body_ref.sound_player.play_sound_from_key)

func enter(_prev_state:int,_data:={}) -> void: 
	if !_data.is_empty():
		var prev_velocity = _data["prev_velocity"]
		lerped_velo = prev_velocity * Vector3(1.0, 0.0, 1.0)
		if _prev_state != MoveStates.FROZEN and _data["has_jumped"]: 
			character_body_ref.velocity.y = jump_force
			jumped = _data["has_jumped"]
			has_jumped.emit()
			request_sound.emit("jump")
			# Send message to whatever sound system we'll use to play sounds made by the player.
	else: lerped_velo = Vector3.ZERO

func handle_input(_event:InputEvent) -> void: pass
func update(_delta:float) -> void: pass

func physics_update(_delta:float) -> void:
	var wish_dir : Vector3 = (
		character_body_ref.get_desired_direction() 
		if character_body_ref.get_input() != Vector2.ZERO 
		else Vector3.ZERO )
	
	if character_body_ref.get_desired_direction().length() > 0:
		lerped_velo = MathPlus.v3_exp_decay(lerped_velo,wish_dir,move_acceleration,_delta)
	else: lerped_velo = MathPlus.v3_exp_decay(lerped_velo,wish_dir,move_drag,_delta)
	
	character_body_ref.velocity.x = lerped_velo.x * character_body_ref.get_total_speed()
	character_body_ref.velocity.z = lerped_velo.z * character_body_ref.get_total_speed()
	character_body_ref.velocity.y += -9.8 * 3.0 * _delta
	var downward_velocity : float = snappedf(character_body_ref.velocity.y,0.01)
	
	character_body_ref.move_and_slide()
	
	var emit_landing : bool = downward_velocity <= fall_threshold or jumped
	
	if character_body_ref.is_on_floor(): 
		if emit_landing:
			print("fall threshold breached!")
			has_landed.emit(downward_velocity,fall_threshold)
			request_sound.emit("landing")
		finished.emit(MoveStates.ON_GROUND,{"prev_velocity":lerped_velo})

func exit() -> void: 
	jumped = false
