class_name FPLeanComponent extends Subcomponent

##The amount that the camera's lerp target will move (along x-axis)
##when a lean is performed.
@export var lean_amnt_pos : float = 0.5
##The amount (in degrees) that the camera will rotate along its z-axis
##when a lean is performed.
@export var lean_amnt_angle : float = 10.0

var lean_sensor : ShapeCast3D = null

signal request_node(new:Node)
signal send_modifier(rot_z:float)

func bind(new:ComponentCore) -> void:
	if new is not FPCameraComponent:
		printerr("FPLeanComponent requires owner to be of type FPCameraComponent")
		return
	super.bind(new)
	
	# Lean collision sensor-node spawning
	var shape_cast : ShapeCast3D = ShapeCast3D.new()
	shape_cast.name = "LeanSensor"
	var shape : Shape3D = SphereShape3D.new()
	shape.radius = 0.25
	shape_cast.shape = shape
	shape_cast.target_position = Vector3(1.0, 0.0, 0.0)
	
	request_node.connect(component_owner.get_owner()._on_request_node, ConnectFlags.CONNECT_ONE_SHOT)
	request_node.emit(shape_cast)
	lean_sensor = shape_cast
	
	send_modifier.connect(component_owner._on_lean_modifier_received)

func ready() -> void: pass
func handle_input(_event:InputEvent) -> void: pass

func update(_delta:float) -> void: 
	if !lean_sensor: return
	lean_sensor.position.y = component_owner.get_lerp_target().position.y

func physics_update(_delta:float) -> void: 
	_handle_lean(_delta)

##############
# Lean Methods
##############
var curr_lean_rot : float = 0.0
func _get_lean_direction() -> int:
	# If the player isn't idle, don't allow a lean.
	var move_comp : FPMovementComponent = component_owner.get_owner().get_component(FPMovementComponent)
	if !move_comp or move_comp.current_state.get_index() != FPMoveState.MoveStates.IDLE:
		return 0
	# If the player is sprinting, don't allow a lean.
	if move_comp.is_sprinting(): return 0
	# If the camera is frozen, don't allow a lean.
	if component_owner.is_frozen: return 0
	# Otherwise...
	return int(Input.get_action_strength("lean_right") - Input.get_action_strength("lean_left"))

func _handle_lean(delta:float) -> void:
	lean_sensor.target_position = Vector3(
		_get_lean_direction() * 0.35,
		0.0,
		0.0
	)
	lean_sensor.force_shapecast_update()
	
	if lean_sensor.is_colliding(): 
		lean_sensor.debug_shape_custom_color = Color.RED
		component_owner.set_lerp_pt_coord(0, 0.0)
		curr_lean_rot = lerpf(
			component_owner.get_camera_node().rotation.z,
			deg_to_rad(0.0),
			delta * 15.0
		)
	else:
		lean_sensor.debug_shape_custom_color = Color.GREEN
		component_owner.set_lerp_pt_coord(0, _get_lean_direction() * lean_amnt_pos)
		curr_lean_rot = lerpf(
			component_owner.get_camera_node().rotation.z,
			deg_to_rad(-_get_lean_direction() * lean_amnt_angle),
			delta * 15.0
		)
	send_modifier.emit(curr_lean_rot)
