class_name InteractRayComponent extends ComponentCore

@export var ray_range : float = 2.5
@export_flags_3d_physics var collision_mask : int

var raycast_ref : RayCast3D
var camera_ref : FPCameraComponent

var current_interactable : Interactable = null

signal request_node(new:Node)
signal send_input_type(val:int)

func bind(new_owner:Node) -> void:
	super.bind(new_owner)
	
	var interact_ray : RayCast3D = RayCast3D.new()
	interact_ray.debug_shape_custom_color = Color.DARK_ORCHID
	interact_ray.target_position = Vector3.FORWARD * ray_range
	interact_ray.top_level = true
	interact_ray.collision_mask = self.collision_mask
	
	request_node.connect(owner._on_request_node, ConnectFlags.CONNECT_ONE_SHOT)
	request_node.emit(interact_ray)
	
	raycast_ref = interact_ray
	camera_ref = owner.get_component(FPCameraComponent)

var prev_type : int = -1
var input_type : int = 0:
	set(new):
		if new == prev_type: return 
		prev_type = new
		_prep_input_request(new)

var register_hold : bool = false
var input_event_completed : bool = false
func update(_delta:float) -> void: 
	if Input.is_action_just_released("interact"):
		register_hold = false
		input_event_completed = false
	
	if input_event_completed: return
	if Input.is_action_pressed("interact") and register_hold:
		input_type = 1
		input_event_completed = true
		return
	elif Input.is_action_just_pressed("interact"):
		register_hold = true
		input_event_completed = false
		input_type = 0

func physics_update(_delta:float) -> void: 
	if !raycast_ref or !camera_ref: return
	raycast_ref.global_position = camera_ref.get_camera_node().global_position
	raycast_ref.global_rotation = camera_ref.get_camera_node().global_rotation

func _get_potential_interactable() -> Variant:
	if !raycast_ref: return null
	if raycast_ref.is_colliding():
		var col : Object = raycast_ref.get_collider()
		return col
	return null

func _prep_input_request(in_type:int) -> void:
	var pot_int_ref : Variant = _get_potential_interactable()
	if pot_int_ref is not Interactable: 
		printerr("Error: No potential interactable found.")
		return
	
	if pot_int_ref == current_interactable:
		printerr("Error: Trying to connect to an already-connected instance.")
		return
	
	var interactcomp : InteractComponent = (pot_int_ref as Interactable).get_interact_comp()
	
	if interactcomp.accepted_input_type != in_type: 
		printerr("Error: Wrong input type")
		return
	
	send_input_type.connect(interactcomp._on_interact_request_received, ConnectFlags.CONNECT_ONE_SHOT)
	send_input_type.emit(in_type)
	current_interactable = pot_int_ref
	interactcomp.end_interaction.connect(_clear_curr_interactable, ConnectFlags.CONNECT_ONE_SHOT)
	pot_int_ref.set_interact_status(true)

func _signal_test(val:int) -> void:
	var translate_to_string : Callable = (
		func(new_val:int) -> String:
			match new_val:
				0: return "press"
				1: return "hold"
				_: return "null"
			)
	print("Input type: %s" % [translate_to_string.call(val)])

func _clear_curr_interactable() -> void:
	current_interactable = null
	print(current_interactable)
