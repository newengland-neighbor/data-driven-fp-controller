class_name Message

enum MessageTypes {
	TOGGLE_VALUE,
	OVERRIDE_FSM_STATE,
	BEGIN_INTERACT,
	SEND_DATA
}

# ID of the object sending the message.
var from : int
# ID of the message's recipient.
var to : int
# The message's contents.
var msg : MessageTypes
# Any additional data a message might need to contain.
var data : Dictionary[String,Variant]

func _init(sender:int,receiver:int,message:MessageTypes,_data:Dictionary[String,Variant]={}) -> void:
	from = sender
	to = receiver
	msg = message
	data = _data

##Array containing the message's contents.
##Index 0 = message sender ID, 1 = message recipient ID, 2 = the message itself, 3 = additional provided data
func get_var_list() -> Array[Variant]: return [from, to, msg, data]
