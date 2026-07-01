class_name InteractComponent extends ComponentCore

@export var can_interact : bool = true
enum IC_InputTypes {
	PRESS,
	HOLD
}
@export var accepted_input_type : IC_InputTypes = IC_InputTypes.PRESS

var is_interacted : bool = false

func bind(new_owner:Node) -> void:
	super.bind(new_owner)

func ready() -> void: pass

func update(_delta:float) -> void: 
	if is_interacted: _interact_update(_delta)
func physics_update(_delta:float) -> void: 
	if is_interacted: _interact_physics_update(_delta)
func handle_input(_event:InputEvent) -> void: 
	if is_interacted: _interact_handle_input(_event)

func _interact_begin() -> void: pass
func _interact_update(_delta:float) -> void: pass
func _interact_physics_update(_delta:float) -> void: pass
func _interact_handle_input(_event:InputEvent) -> void: pass

func set_interact_status(new:bool) -> void: is_interacted = new
