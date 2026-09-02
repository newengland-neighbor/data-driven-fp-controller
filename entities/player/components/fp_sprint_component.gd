class_name FPSprintComponent extends ComponentCore

##Modifier value used to augment FPController's movement speed.
@export_range(1.0, 2.0, 0.05) var speed_modifier : float = 2.0
##If true, the player will be able to sprint in all horizontal directions.
##If false, the player will only be able to sprint if moving forward.
@export var omni_directional : bool = true

var character_body_ref : FPController
signal send_move_speed_mod(key:String,val:float,remove:bool)

func bind(new_owner:Node) -> void:
	if new_owner is not FPController:
		printerr("FPCrouchComponent requires owner to be of type FPController")
		return
	
	super.bind(new_owner)
	character_body_ref = get_owner()
	send_move_speed_mod.connect(character_body_ref._on_modifier_received)

# We want to continuously check if the sprint key is behind held.
# Therefore the logic is in process() over unhandled_input() like usual.
func update(_delta:float) -> void:
	if !character_body_ref: return
	if Input.is_action_just_released("sprint"):
		if !character_body_ref.has_modifier("sprint"): return
		send_move_speed_mod.emit("sprint",true,speed_modifier)
		return
	
	if Input.is_action_pressed("sprint"):
		# If player is crouching, exit function.
		var check : Variant = character_body_ref.has_modifier("crouch")
		if check != null: return
		# If omni-directional sprint isn't allowed, check for forward movement
		# before sending speed modifier off.
		if !omni_directional and !Input.is_action_pressed("move_forward"): 
			if character_body_ref.has_modifier("sprint"): 
				send_move_speed_mod.emit("sprint",true,speed_modifier)
			return
		send_move_speed_mod.emit("sprint",false,speed_modifier)
