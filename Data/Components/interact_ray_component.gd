class_name InteractRayComponent extends ComponentCore

@export var ray_range : float = 2.5
@export_flags_3d_physics var collision_mask : int = 1

var raycast_ref : RayCast3D
var camera_ref : FPCameraComponent

signal request_node(new:Node)

func bind(new_owner:Node) -> void:
	super.bind(new_owner)
	
	var interact_ray : RayCast3D = RayCast3D.new()
	interact_ray.debug_shape_custom_color = Color.DARK_ORCHID
	interact_ray.target_position = Vector3.FORWARD * ray_range
	interact_ray.top_level = true
	
	request_node.connect(owner._on_request_node, ConnectFlags.CONNECT_ONE_SHOT)
	request_node.emit(interact_ray)
	
	raycast_ref = interact_ray
	camera_ref = owner.get_component(FPCameraComponent)

func ready() -> void: pass
func update(_delta:float) -> void: pass

func physics_update(_delta:float) -> void: 
	if !raycast_ref or !camera_ref: return
	raycast_ref.global_position = camera_ref.get_camera_node().global_position
	raycast_ref.global_rotation = camera_ref.get_camera_node().global_rotation
	var potential_interact = _get_potential_interactable()

func _get_potential_interactable() -> Variant:
	if !raycast_ref: return null
	if raycast_ref.is_colliding():
		var col := raycast_ref.get_collider()
		return col
	return null

var input_type : int = -1
func handle_input(_event:InputEvent) -> void: 
	if _get_potential_interactable() == null: return
	if _event.is_action("interact") and _event.is_echo():
		print("a hold is happening")
		input_type = 0
		return
	elif _event.is_action_released("interact"):
		input_type = 1
		print("a press happened")
