class_name ICSwitch extends Interactable

@export var starting_status: bool = true
@export var affected_nodes: Array[Node]

var switch_status: bool = false

signal send_message_to_router(msg:Message)

func _ready() -> void:
	switch_status = starting_status
	
	# Registry in Message system.
	var msg_id : int = -1
	# If generated ID exists in the message router's registry, keep generating a new ID until
	# a free spot for that key is found.
	while (MessageRouter.registry_has_key(msg_id) or msg_id == -1): msg_id = randi()
	MessageRouter.register_client(msg_id, handle_message)
	send_message_to_router.connect(MessageRouter._on_message_received)
	_message_affected_nodes.call_deferred(switch_status)

func _message_affected_nodes(override_val:bool) -> void:
	for n in affected_nodes:
		if !n.has_meta("msg_id"): continue
		var msg : Message = Message.new(
			self.get_meta("msg_id",-1),
			n.get_meta("msg_id",-1),
			Message.MessageTypes.TOGGLE_VALUE,
			{"value_override":override_val}
			)
		send_message_to_router.emit(msg)

func interact_begin() -> void: 
	switch_status = !switch_status
	_message_affected_nodes(switch_status)
	interact_end()

func interact_end() -> void: super.interact_end()

func handle_message(new_msg:Message) -> void: 
	var msg_details : Array[Variant] = new_msg.get_var_list()
	var msg_data : Dictionary = msg_details[3]
	match msg_details[2]:
		Message.MessageTypes.BEGIN_INTERACT: 
			if !is_acceptable(msg_data["input_type"]):
				printerr("From %s: invalid input received." % self.name)
				return
			interact_begin()
		_: pass
