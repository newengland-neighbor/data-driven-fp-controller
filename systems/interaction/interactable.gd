class_name Interactable extends Node

enum IC_InputTypes {
	PRESS,
	HOLD
}

@export var accepted_input_type : IC_InputTypes = IC_InputTypes.PRESS
@export var interact_icon : Texture2D = null

var is_interacted : bool = false

func _ready() -> void:
	print()

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

#func interact_begin() -> void: pass
#func interact_update(_delta:float) -> void: pass
#func interact_physics_update(_delta:float) -> void: pass
#func interact_handle_input(_event:InputEvent) -> void: pass
#func interact_end() -> void: is_interacted = false
