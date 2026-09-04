extends Node

var _clients : Dictionary[int,Callable]

func registry_has_key(query:int) -> bool:
	return true if _clients.has(query) else false

func register_client(id:int,msg_parser:Callable) -> void:
	if _clients.has(id):
		printerr("Message Client ID %s already registered." % str(id))
		return
	_clients[id] = msg_parser
	msg_parser.get_object().set_meta("msg_id",id)
	#print("New ID added to registry at key %s" % str(id))

func unregister_client(id:int) -> void:
	if !_clients.has(id):
		printerr("Message Client to be unregistered isn't registered to begin with.")
		return
	_clients.erase(id)

##Signal listener function for clients to send messages for distribution.
func _on_message_received(new:Message) -> void:
	# Create reference to message's variable list.
	var msg_contents : Array[Variant] = new.get_var_list()
	
	# if the recipient doesn't exist in the client list, exit function.
	if !_clients.has(msg_contents[1]): 
		printerr("Message for Client %s failed to send: Client %s is not registered by Message Router." % [
			str(msg_contents[1]),
			str(msg_contents[1])
		])
		return
	
	# Otherwise, send message to recipient.
	if !_clients[msg_contents[1]].is_valid():
		printerr("Message for Client %s failed to send: Registered callable is not valid." % str(msg_contents[1]))
		return
	
	_clients[msg_contents[1]].call(new)
