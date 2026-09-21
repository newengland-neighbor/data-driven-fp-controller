class_name StateMachineComponent extends ComponentCore

## Array of states that the StateMachineComponent uses.
@export var states : Dictionary[String, StateResource]

var current_state : StateResource

func bind(new_owner:Node) -> void:
	super.bind(new_owner)

func get_state(query:Object) -> StateResource:
	for state in states:
		if is_instance_of(states[state],query): return states[state]
	return null

func on_state_transition(target_state:String,data:Dictionary={}) -> void:
	if !states.has(target_state): 
		printerr("FSM does not contain state.")
		return
	
	var prev_state : String = current_state.get_state_name()
	current_state.exit()
	current_state = states[target_state]
	current_state.enter(prev_state,data)

func ready() -> void: 
	for s in states: 
		states[s].bind(self)
	current_state = states[states.keys()[0]]

func update(_delta:float) -> void: current_state.update(_delta)
func physics_update(_delta:float) -> void: current_state.physics_update(_delta)
func handle_input(_event:InputEvent) -> void: current_state.handle_input(_event)
