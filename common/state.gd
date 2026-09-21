class_name StateResource extends Resource

var state_owner : StateMachineComponent

signal finished(new_state:int,data:Dictionary)

func enter(_prev_state:String,_data:={}) -> void: pass
func handle_input(_event:InputEvent) -> void: pass
func update(_delta:float) -> void: pass
func physics_update(_delta:float) -> void: pass
func exit() -> void: pass

func bind(new:StateMachineComponent) -> void:
	finished.connect(new.on_state_transition)
	state_owner = new
