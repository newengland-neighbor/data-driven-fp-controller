class_name FPMS_Idle extends FPMoveState

var character_body_ref : FPController

func bind(new:ComponentCore,indx:int) -> void:
	super.bind(new,indx)
	character_body_ref = new.owner

func enter(_prev_state:int,_data:={}) -> void: 
	character_body_ref.velocity.x = 0.0
	character_body_ref.velocity.z = 0.0

func handle_input(_event:InputEvent) -> void: 
	if _event .is_action_pressed("jump"):
		if !character_body_ref.ceiling_check(0.5): return
		finished.emit(MoveStates.JUMPING, {"prev_velocity":Vector3.ZERO})
		#else: if player.debug: print("\nCeiling detected above player. Cancelling jump...")

func update(_delta:float) -> void: 
	if character_body_ref.get_input() != Vector2.ZERO: finished.emit(MoveStates.MOVING)
	if !character_body_ref.is_on_floor(): finished.emit(MoveStates.FALLING)
	#if Input.is_action_just_pressed("ui_cancel"): finished.emit(IN_MENU)

func physics_update(_delta:float) -> void: pass
	#character_body_ref.handle_ground_hover(_delta)
	#character_body_ref.move_and_slide()
	#print(character_body_ref.velocity)
func exit() -> void: pass
