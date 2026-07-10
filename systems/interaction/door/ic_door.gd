class_name ICDoor extends Interactable

var is_held_received : bool = false

# Overriden from parent class function.
func _parse_input_received(it:int) -> void:
	if it == IC_InputTypes.PRESS: 
		is_held_received = false
		return
	
	if !is_acceptable(it): return
	
	match it:
		IC_InputTypes.HOLD:
			print("Hold signal received. Opening door slowly...")
			is_held_received = true
		
		IC_InputTypes.RELEASE:
			if is_held_received:
				print("Release signal received. Ending interaction...")
			else: 
				print("Release signal received. Opening door normally...")
			interact_end()

func _ready() -> void: pass
	#state_machine.bind(self)
	#state_machine.ready()

func interact_begin() -> void: 
	super.interact_begin()
	#print(state_machine.current_state.can_open)

func _physics_process(_delta: float) -> void: 
	super._physics_process(_delta)
	#print(snappedf(rad_to_deg(self.rotation.y), 0.01))

func interact_end() -> void: 
	super.interact_end()
