class_name FPCrouchComponent extends ComponentCore

##Modifier value used to augment FPController's movement speed.
@export_range(0.5, 1.0, 0.05) var speed_mod = 0.65

##Dictionary of values used to modify FPController's collision shape.
@export var collider_dimensions : Dictionary = {
	"Stand" : {
		"Height" : 1.8,
		"Y-Position" : 0.9,
		"CamY-Pos" : 1.5
	},
	"Crouch" : {
		"Height" : 0.9,
		"Y-Position" : 0.45,
		"CamY-Pos" : 0.7
	}
}
##Db value used to interact with the footstep audio system. 
@export_range(-6.0, 0.0, 1.0) var step_volume_modifier : float = -6.0

enum Stances {STANDING, CROUCHING}
var curr_stance : Stances = Stances.STANDING

signal stance_changed(new:int)
signal send_move_speed_mod(key:String,val:float,remove:bool)
signal send_col_shape_data(data:Dictionary)
signal send_step_volume_data(val:float)

var character_body_ref : FPController

func bind(new_owner:Node) -> void:
	if new_owner is not FPController:
		printerr("FPCrouchComponent requires owner to be of type FPController")
		return
	
	super.bind(new_owner)
	character_body_ref = get_owner()
	
	send_col_shape_data.connect(character_body_ref.set_cylinder_shape_dimensions)
	send_move_speed_mod.connect(character_body_ref._on_modifier_received)
	
	var cam_effect_comp : FPCameraEffectComponent = character_body_ref.get_cam_ref().get_component(FPCameraEffectComponent)
	if !cam_effect_comp: return
	send_step_volume_data.connect(cam_effect_comp.set_step_volume)

func handle_input(_event:InputEvent) -> void:
	if !character_body_ref: return 
	if _event.is_action_pressed("crouch"): 
		handle_stance()

##Function used to handle the 'stance' of the player, and changes to it.
func handle_stance() -> void:
	print("\nCurrent Stance: %s. Transitioning..." % (
		"Standing" if curr_stance == 0 else "Crouching")
		)
	
	if character_body_ref.has_modifier("sprint"):
		send_move_speed_mod.emit(
			"sprint",
			true)
		send_step_volume_data.emit(6.0)
	
	match curr_stance:
		Stances.STANDING: 
			curr_stance = Stances.CROUCHING
		Stances.CROUCHING: 
			## If player would collide with the ceiling by standing, exit function.
			if !character_body_ref.ceiling_check(0.75): 
				printerr("Stance change cancelled. Ceiling detected.")
				return
			curr_stance = Stances.STANDING
	
	var shape_data_to_send : Dictionary = (
		collider_dimensions["Crouch"]
		if curr_stance == Stances.CROUCHING
		else collider_dimensions["Stand"]
	)
	send_col_shape_data.emit(shape_data_to_send)
	send_move_speed_mod.emit(
		"crouch",
		(curr_stance==Stances.STANDING),
		speed_mod
		)
	stance_changed.emit(curr_stance)
	send_step_volume_data.emit(0.0 if curr_stance == Stances.STANDING else step_volume_modifier)
	
	
	print("New Stance: %s" % ("Standing" if curr_stance == 0 else "Crouching"))
