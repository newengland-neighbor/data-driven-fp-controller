class_name InteractComponent extends ComponentCore

enum IC_InputTypes {
	PRESS,
	HOLD
}

@export var accepted_input_type : IC_InputTypes = IC_InputTypes.PRESS
@export var interact_icon : Texture2D = null

@export var interaction_end_flags : Array[String]

signal end_interaction

func bind(new_owner:Node) -> void:
	if new_owner is not Interactable:
		printerr("Error: Component owner is expected to be of type Interactable.")
		return
	super.bind(new_owner)

func ready() -> void: pass

func update(_delta:float) -> void: 
	if owner.get_interact_status(): _interact_update(_delta)
func physics_update(_delta:float) -> void: 
	if owner.get_interact_status(): _interact_physics_update(_delta)
func handle_input(_event:InputEvent) -> void: 
	if owner.get_interact_status(): _interact_handle_input(_event)

func _on_interact_request_received(input_type:int) -> void:
	if input_type != accepted_input_type: 
		printerr("Error: Interaction request made does not match accepted input type.")
		return
	print("Interacting...")

func _interact_begin() -> void: pass
func _interact_update(_delta:float) -> void: pass
func _interact_physics_update(_delta:float) -> void: pass

func _interact_handle_input(_event:InputEvent) -> void: 
	if _event.is_action_released("interact"):
		_interact_end()

func _interact_end() -> void: 
	end_interaction.emit()
