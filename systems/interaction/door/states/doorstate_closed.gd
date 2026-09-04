class_name DoorStateClosed extends DoorState

@export var can_open : bool = true
@export var is_locked : bool = false

func enter(_prev_state:int,_data:={}) -> void: pass
#func handle_input(_event:InputEvent) -> void: pass
#func update(_delta:float) -> void: pass
#func physics_update(_delta:float) -> void: pass
func exit() -> void: pass

func set_lock_status(l:bool) -> void: is_locked = l
