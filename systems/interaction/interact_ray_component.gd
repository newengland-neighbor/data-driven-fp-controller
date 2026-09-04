class_name InteractRayComponent extends ComponentCore

@export var ray_range : float = 2.5
@export_flags_3d_physics var collision_mask : int = 1

var camera_ref : FPCamera
var raycast_ref : RayCast3D

signal request_node(new:Node)
signal send_message_to_router(msg:Message)

func bind(new_owner:Node) -> void:
	if new_owner is not FPController:
		printerr("FPCrouchComponent requires owner to be of type FPController")
		return
	
	super.bind(new_owner)
	
	var interact_ray : RayCast3D = RayCast3D.new()
	interact_ray.debug_shape_custom_color = Color.DARK_ORCHID
	interact_ray.target_position = Vector3.FORWARD * ray_range
	interact_ray.top_level = true
	interact_ray.collision_mask = self.collision_mask
	
	request_node.connect(owner._on_request_node, ConnectFlags.CONNECT_ONE_SHOT)
	request_node.emit(interact_ray)
	
	send_message_to_router.connect(MessageRouter._on_message_received)
	
	raycast_ref = interact_ray
	camera_ref = owner.get_cam_ref()

var prev_type : int = -1
var input_type : int = 0:
	set(new):
		if new == prev_type: return 
		prev_type = new
		_prep_interact_request(new)

var hold_timer : float = 0.0
const HOLD_MAX : float = 0.25
func update(_delta:float) -> void: 
	if Input.is_action_just_pressed("interact"):
		hold_timer = 0
		input_type = 0
	
	if Input.is_action_pressed("interact"):
		hold_timer = snappedf(clampf(hold_timer + _delta, 0.0, HOLD_MAX), 0.01)
		if hold_timer >= HOLD_MAX:
			input_type = 1
	
	if Input.is_action_just_released("interact"):
		input_type = 2

func physics_update(_delta:float) -> void: 
	if !raycast_ref: return
	raycast_ref.global_position = camera_ref.global_position
	raycast_ref.global_rotation = camera_ref.global_rotation

func _get_potential_interactable() -> Interactable:
	if !raycast_ref: return null
	var col : Interactable = (raycast_ref.get_collider() as Interactable)
	if !col: return null
	return col

func _prep_interact_request(in_type:int) -> void:
	var pot_int_ref : Interactable = _get_potential_interactable()
	if !pot_int_ref: 
		printerr("Error: No potential interactable found.")
		return
	
	if pot_int_ref.is_interacted:
		printerr("Error: Trying to interact with something that's being interacted with.")
		return
	
	var msg : Message = Message.new(
		get_owner().get_meta("msg_id",-1),
		pot_int_ref.get_meta("msg_id",-1),
		Message.MessageTypes.BEGIN_INTERACT,
		{"input_type":in_type}
	)
	send_message_to_router.emit(msg)

func _signal_test(val:int) -> void:
	var translate_to_string : Callable = (
		func(new_val:int) -> String:
			match new_val:
				0: return "press"
				1: return "hold"
				_: return "null"
			)
	print("Input type: %s" % [translate_to_string.call(val)])
