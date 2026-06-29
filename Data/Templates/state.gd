class_name StateResource extends Resource

var state_owner : ComponentCore
var index : int

@warning_ignore("unused_signal")
signal finished(new_state:int,data:Dictionary)

func enter(_prev_state:int,_data:={}) -> void: pass
func handle_input(_event:InputEvent) -> void: pass
func update(_delta:float) -> void: pass
func physics_update(_delta:float) -> void: pass
func exit() -> void: pass

func bind(new:ComponentCore,indx:int) -> void:
	state_owner = new
	index = indx

func get_index() -> int: return index
