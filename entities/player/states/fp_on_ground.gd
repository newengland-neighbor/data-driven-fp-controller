class_name FPMS_OnGround extends FPMoveState

##The maximum time (in seconds) that the player's coyote time should last after leaving the ground.
@export var coyote_timer_max : float = 0.15

var coyote_timer : float = 0.0
var wish_dir : Vector3 = Vector3.ZERO

var character_body_ref : FPController

func bind(new:ComponentCore,indx:int) -> void:
	super.bind(new,indx)
	character_body_ref = new.owner

func enter(_prev_state:int,_data:={}) -> void: 
	if !_data.is_empty():
		var prev_velocity = _data["prev_velocity"]
		wish_dir = prev_velocity
	else: wish_dir = Vector3.ZERO
	coyote_timer = 0.0
	#print("Entering on_ground state...")

func handle_input(_event:InputEvent) -> void:
	if _event .is_action_pressed("jump"):
		if !character_body_ref.ceiling_check(0.5): return
		finished.emit(MoveStates.IN_AIR, {
			"prev_velocity":wish_dir,
			"has_jumped":true
			})

func update(_delta:float) -> void: pass

func physics_update(_delta:float) -> void: 
	var target_vector : Vector3 = (
		character_body_ref.get_desired_direction()
		if character_body_ref.get_input() != Vector2.ZERO
		else Vector3.ZERO )
	
	wish_dir = MathPlus.v3_exp_decay(wish_dir,target_vector,MathPlus.DECAY,_delta)
	var was_on_floor : bool = character_body_ref.is_on_floor()
	
	var has_snapped : bool = character_body_ref.handle_step_up(_delta)
	
	character_body_ref.velocity = wish_dir * character_body_ref.get_total_speed() * Vector3(1,0,1)
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

func exit() -> void: 
	pass
	#print("Exiting on_ground state...")

func _in_coyote_time() -> bool: return coyote_timer < coyote_timer_max
