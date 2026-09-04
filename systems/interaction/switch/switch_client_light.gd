class_name SwitchClientLight extends Light3D

func _ready() -> void:
	var msg_id : int = -1
	# If generated ID exists in the message router's registry, keep generating a new ID until
	# a free spot for that key is found.
	while (MessageRouter.registry_has_key(msg_id) or msg_id == -1): msg_id = randi()
	MessageRouter.register_client(msg_id, on_message_received)

func on_message_received(new_msg:Message) -> void:
	var msg_details : Array[Variant] = new_msg.get_var_list()
	var msg_data : Dictionary = msg_details[3]
	match msg_details[2]:
		Message.MessageTypes.TOGGLE_VALUE: 
			if !msg_data.has("value_override"): return
			self.visible = msg_data["value_override"]
		_: pass
