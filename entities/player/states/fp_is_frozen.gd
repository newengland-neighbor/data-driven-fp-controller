class_name FPMS_IsFrozen extends FPMoveState

var character_body_ref : FPController = null
var character_cam_ref : FPCamera = null

func bind(new:ComponentCore,indx:int) -> void:
	super.bind(new,indx)
	character_body_ref = new.owner
	character_cam_ref = character_body_ref.get_cam_ref()

func enter(_prev_state:int,_data:={}) -> void:
	character_cam_ref.set_frozen_status(true) 
	character_body_ref.velocity = Vector3.ZERO

func exit() -> void:
	character_cam_ref.set_frozen_status(false) 
