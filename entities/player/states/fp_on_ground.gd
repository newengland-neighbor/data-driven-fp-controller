class_name FPMS_OnGround extends FPMoveState

##The maximum time (in seconds) that the player's coyote time should last after leaving the ground.
@export var coyote_timer_max : float = 0.15

var coyote_timer : float = 0.0
var lerped_velo : Vector3 = Vector3.ZERO

var character_body_ref : FPController

func bind(new:ComponentCore,indx:int) -> void:
	super.bind(new,indx)
	character_body_ref = new.owner

func enter(_prev_state:int,_data:={}) -> void: 
	if !_data.is_empty():
		var prev_velocity = _data["prev_velocity"]
		lerped_velo = prev_velocity
	else: lerped_velo = Vector3.ZERO
	coyote_timer = 0.0

func handle_input(_event:InputEvent) -> void:
	if _event .is_action_pressed("jump"):
		if !character_body_ref.ceiling_check(0.5): return
		finished.emit(MoveStates.IN_AIR, {
			"prev_velocity":lerped_velo,
			"has_jumped":true
			})

func update(_delta:float) -> void: pass

func physics_update(_delta:float) -> void: 
	var wish_dir : Vector3 = (
		character_body_ref.get_desired_direction() 
		if character_body_ref.get_input() != Vector2.ZERO 
		else Vector3.ZERO )
	
	if character_body_ref.get_desired_direction().length() > 0:
		lerped_velo = MathPlus.v3_exp_decay(lerped_velo,wish_dir,move_acceleration,_delta)
	else: lerped_velo = MathPlus.v3_exp_decay(lerped_velo,wish_dir,move_drag,_delta)
	
	var was_on_floor : bool = character_body_ref.is_on_floor()
	
	var has_snapped : bool = character_body_ref.handle_step_up(_delta)
	
	character_body_ref.velocity = lerped_velo * character_body_ref.get_total_speed() * Vector3(1,0,1)
	character_body_ref.handle_physics_collision()
	character_body_ref.move_and_slide()
	
	if !has_snapped: has_snapped = character_body_ref.handle_step_down()
	
	if !character_body_ref.is_on_floor():
		if has_snapped: return
		coyote_timer += _delta
		if was_on_floor: 
			character_body_ref.apply_floor_snap()
			coyote_timer = 0.0
			return
		# If coyote_timer has reached max, transition to FALLING state.
		if !_in_coyote_time(): 
			finished.emit(MoveStates.IN_AIR,{
				"prev_velocity":wish_dir,
				"has_jumped":false
				})

func exit() -> void: pass

func _in_coyote_time() -> bool: return coyote_timer < coyote_timer_max
