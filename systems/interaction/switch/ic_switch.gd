class_name ICSwitch extends Interactable

@export var starting_status: bool = true
@export var affected_nodes: Array[Node]

var switch_status: bool = false

signal update_affected_nodes

func _ready() -> void:
	switch_status = starting_status
	for node in affected_nodes:
		var switch_listener: SwitchListener = node.find_child("SwitchListener")
		if !switch_listener: continue
		update_affected_nodes.connect(switch_listener._on_switch_signal_received)

func interact_begin() -> void: 
	switch_status = !switch_status
	update_affected_nodes.emit(switch_status)
	interact_end()

func interact_end() -> void: super.interact_end()
