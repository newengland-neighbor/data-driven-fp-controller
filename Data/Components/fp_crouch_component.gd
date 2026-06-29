class_name FPCrouchComponent extends ComponentCore

##Dictionary of values used to modify FPController's collision shape.
@export var collider_dimensions : Dictionary = {
	"Stand" : {
		"Height" : 1.7,
		"Y-Position" : 0.85,
		"CamY-Pos" : 1.5
	},
	"Crouch" : {
		"Height" : 1.0,
		"Y-Position" : 0.5,
		"CamY-Pos" : 0.8
	}
}

enum Stances {
	STANDING, 
	CROUCHING
	}
var curr_stance : Stances = Stances.STANDING

signal stance_changed(new:int)
signal send_col_shape_data(data:Dictionary)

var character_body_ref : FPController

func bind(new_owner:Node) -> void:
	super.bind(new_owner)
	character_body_ref = owner
	send_col_shape_data.connect(owner.set_cylinder_shape_dimensions)

func ready() -> void: pass
func update(_delta:float) -> void: pass
func physics_update(_delta:float) -> void: pass

func handle_input(_event:InputEvent) -> void: 
	if _event.is_action_pressed("crouch"): handle_stance()

##Function used to handle the 'stance' of the player, and changes to it.
func handle_stance() -> void:
	print("\nCurrent Stance: %s. Transitioning..." % (
		"Standing" if curr_stance == 0 else "Crouching")
		)
	match curr_stance:
		Stances.STANDING: curr_stance = Stances.CROUCHING
		Stances.CROUCHING: 
			## If player would collide with the ceiling by standing, exit function.
			var move_comp : FPMovementComponent = owner.get_component(FPMovementComponent)
			if !move_comp: printerr("Absent FPMovementComponent.")
			if !move_comp.ceiling_check(0.75): 
				printerr("Stance change cancelled. Ceiling detected.")
				return
			curr_stance = Stances.STANDING
	
	var shape_data_to_send : Dictionary = (
		collider_dimensions["Crouch"]
		if curr_stance == Stances.CROUCHING
		else collider_dimensions["Stand"]
	)
	send_col_shape_data.emit(shape_data_to_send)
	stance_changed.emit(curr_stance)

print("New Stance: %s" % ("Standing" if curr_stance == 0 else "Crouching"))
