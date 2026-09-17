class_name StateMachineComponent extends ComponentCore

## Array of states that the StateMachineComponent uses.
@export var states : Array[StateResource]
## Value used to determine the initial state of the StateMachineComponent.
@export_range(0,100,1) var init_state_index : int = 0

var current_state : StateResource

func bind(new_owner:Node) -> void:
	super.bind(new_owner)

func get_state(query:Object) -> StateResource:
	for state in states:
		if is_instance_of(state,query): return state
	return null

func on_state_transition(target_state_index:int,data:Dictionary={}) -> void:
	if target_state_index >= states.size(): 
		printerr("Player Movement FSM does not contain state index.")
		return
	
	var prev_state : int = current_state.get_index()
	current_state.exit()
	current_state = states[target_state_index]
	current_state.enter(prev_state,data)

func ready() -> void: 
	var state_index : int = 0
	for s in states:
		s.bind(self,state_index)
		state_index += 1
	current_state = states[init_state_index]

func update(_delta:float) -> void: current_state.update(_delta)
func physics_update(_delta:float) -> void: current_state.physics_update(_delta)
func handle_input(_event:InputEvent) -> void: current_state.handle_input(_event)
