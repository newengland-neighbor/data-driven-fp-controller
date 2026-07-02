class_name Interactable extends Node

@export var interact_component : InteractComponent

var is_interacted : bool = false

func get_interact_comp() -> InteractComponent: return interact_component

func _ready() -> void:
	interact_component.bind(self)

func _process(delta: float) -> void:
	interact_component.update(delta)

func _physics_process(delta: float) -> void:
	interact_component.physics_update(delta)

func _unhandled_input(_event: InputEvent) -> void:
	interact_component.handle_input(_event)

func get_interact_status() -> bool: return is_interacted
func set_interact_status(new:bool) -> void: is_interacted = new
