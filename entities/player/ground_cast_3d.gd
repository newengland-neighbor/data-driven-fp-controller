class_name GroundCast3D extends RayCast3D

@warning_ignore("unused_signal")
signal send_message_to_router(msg:Message)

func _ready() -> void:
	var msg_id : int = -1
	# If generated ID exists in the message router's registry, keep generating a new ID until
	# a free spot for that key is found.
	while (MessageRouter.registry_has_key(msg_id) or msg_id == -1): msg_id = randi()
	MessageRouter.register_client(msg_id, handle_message)

func _physics_process(_delta: float) -> void:
	if !self.is_colliding(): return
	#var collision_msg : Message = Message.new(
		#self.get_meta("msg_id",-1),
		#get_parent().get_meta("msg_id",-1),
		#Message.MessageTypes.SEND_DATA,
		#{"collision_data":get_collision_data()}
		#)
	#var sound_msg : Message = Message.new(
		#self.get_meta("msg_id",-1),
		# eventual Footstep Sound Manager?
		# send_data
		#null if !col_ref.has_meta("material") else col_ref.get_meta("material")
		#)
	

func get_collision_data() -> Dictionary:
	var output : Dictionary = {}
	output["position"] = self.get_collision_point()
	output["normal"] = self.get_collision_normal()
	output["slope"] = Vector3.UP.angle_to(self.get_collision_normal())
	return output

func handle_message() -> void: pass
