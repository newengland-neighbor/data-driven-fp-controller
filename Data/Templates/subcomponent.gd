class_name Subcomponent extends Resource

var component_owner : ComponentCore

func ready() -> void: pass
func handle_input(_event:InputEvent) -> void: pass
func update(_delta:float) -> void: pass
func physics_update(_delta:float) -> void: pass

func bind(new:ComponentCore) -> void:
	component_owner = new
