class_name Interactable extends Node

enum IC_InputTypes {PRESS, HOLD, RELEASE}

@export var accepted_input_types : Array[IC_InputTypes]
@export var interact_icon : Texture2D = null

##Returns true if the passed integer is included within the accepted_input_types array.
##Otherwise, returns false.
func is_acceptable(type:int) -> bool:
	for it in accepted_input_types:
		if it == type: return true
	return false

#func _parse_input_received(it:int) -> void:
	#if is_acceptable(it): 
		#print("Acceptable input received!")
		#interact_begin()
		#return

var is_interacted : bool = false

func interact_begin() -> void: 
	is_interacted = true

func _process(_delta: float) -> void: 
	if !is_interacted: return

func _physics_process(_delta: float) -> void: 
	if !is_interacted: return

func _unhandled_input(_event: InputEvent) -> void: 
	if !is_interacted: return

func interact_end() -> void: 
	is_interacted = false

func handle_message(_new_msg:Message) -> void: pass

#func interact_begin() -> void: pass
#func interact_update(_delta:float) -> void: pass
#func interact_physics_update(_delta:float) -> void: pass
#func interact_handle_input(_event:InputEvent) -> void: pass
#func interact_end() -> void: is_interacted = false
