class_name SwitchListener extends Node

func _on_switch_signal_received(val:bool) -> void:
	var p := self.get_parent()
	if p is Light3D: (p as Light3D).visible = val
