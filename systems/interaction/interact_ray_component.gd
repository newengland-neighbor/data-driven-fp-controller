class_name InteractRayComponent extends ComponentCore

@export var ray_range : float = 2.5
@export_flags_3d_physics var collision_mask : int = 1

var raycast_ref : RayCast3D
var camera_ref : FPCameraComponent

var current_interactable : Interactable = null

signal request_node(new:Node)
signal send_input_type(it:int)

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
		print(new)
		_prep_interact_request(new)

#var register_hold : bool = false
#var input_event_completed : bool = false
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
	
	#if Input.is_action_just_released("interact"):
		#if current_interactable: 
			#current_interactable.interact_end()
			#_clear_curr_interactable()
		#register_hold = false
		#input_event_completed = false
	#
	#if input_event_completed: return
	#
	#if Input.is_action_pressed("interact") and register_hold:
		#input_type = 1
		#input_event_completed = true
		#return
	#
	#elif Input.is_action_just_pressed("interact"):
		#register_hold = true
		#input_event_completed = false
		#input_type = 0

func physics_update(_delta:float) -> void: 
	if !raycast_ref or !camera_ref: return
	raycast_ref.global_position = camera_ref.get_camera_node().global_position
	raycast_ref.global_rotation = camera_ref.get_camera_node().global_rotation

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
	#
	#if pot_int_ref.is_acceptable(in_type): 
		#printerr("Error: Wrong input type")
		#return
	
	if pot_int_ref == current_interactable:
		printerr("Error: Trying to connect to an already-connected instance.")
		return
	
	send_input_type.connect(pot_int_ref._parse_input_received, ConnectFlags.CONNECT_ONE_SHOT)
	send_input_type.emit(in_type)
	
	#pot_int_ref.interact_begin()
	#current_interactable = pot_int_ref

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
	#print(current_interactable)
