class_name ComponentCore extends Resource

var owner: Node

func ready() -> void: pass
func update(_delta:float) -> void: pass
func physics_update(_delta:float) -> void: pass
func handle_input(_event:InputEvent) -> void: pass

func bind(new_owner:Node) -> void:
	owner = new_owner

## Returns the bound owner of a component.
func get_owner() -> Node: return null if !owner else owner
