class_name FPLeanComponent extends ComponentCore

##The amount that the camera's lerp target will move (along x-axis)
##when a lean is performed.
@export var lean_amnt_pos : float = 0.5
##The amount (in degrees) that the camera will rotate along its z-axis
##when a lean is performed.
@export var lean_amnt_angle : float = 10.0

var curr_lean_pos : float = 0.0
var curr_lean_rot : float = 0.0

var lean_sensor : ShapeCast3D = null
var character_body_ref : FPController = null

signal request_node(new:Node)
signal send_rot_modifier(rot_z:float)
signal send_pos_modifier(axis:int,val:float)

func bind(new_owner:Node) -> void:
	if new_owner is not FPCamera:
		printerr("FPLeanComponent requires owner to be of type FPCameraComponent")
		return
	
	super.bind(new_owner)
	character_body_ref = get_owner().get_parent() as FPController
	
	# Lean collision sensor-node spawning
	var shape_cast : ShapeCast3D = ShapeCast3D.new()
	shape_cast.name = "LeanSensor"
	var shape : Shape3D = SphereShape3D.new()
	shape.radius = 0.2
	shape_cast.shape = shape
	shape_cast.target_position = Vector3(1.0, 0.0, 0.0)
	
	(func() -> void:
		request_node.connect(character_body_ref._on_request_node, ConnectFlags.CONNECT_ONE_SHOT)
		request_node.emit(shape_cast)
		lean_sensor = shape_cast
		).call_deferred()
	
	send_pos_modifier.connect(get_owner()._set_lerp_pt_coord)
	send_rot_modifier.connect(get_owner()._on_lean_modifier_received)

func update(_delta:float) -> void: 
	if !lean_sensor or !get_owner(): return

func physics_update(_delta:float) -> void: 
	if !lean_sensor or !get_owner(): return
	lean_sensor.position.y = get_owner().get_lerp_target().position.y
	lean_sensor.rotation.y = get_owner().get_lerp_target().rotation.y
	_handle_lean(_delta)

func _get_lean_direction() -> int:
	# If the player isn't trying to move, don't allow a lean.
	if (!character_body_ref 
	or !character_body_ref.get_input() == Vector2.ZERO 
	or !character_body_ref.is_on_floor()): 
		return 0
	
	# If the camera is frozen, don't allow a lean.
	if get_owner().is_frozen: return 0
	
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
		curr_lean_pos = 0.0
	else:
		lean_sensor.debug_shape_custom_color = Color.GREEN
		curr_lean_pos = _get_lean_direction() * lean_amnt_pos
	
	var target_rot : float = (
		0.0 if lean_sensor.is_colliding()
		else deg_to_rad(-_get_lean_direction() * lean_amnt_angle)
		)
	
	curr_lean_rot = MathPlus.f_exp_decay(
		curr_lean_rot,
		target_rot,
		MathPlus.DECAY,
		delta
		)
	
	send_pos_modifier.emit(0, snappedf(curr_lean_pos,0.001))
	send_rot_modifier.emit(snappedf(curr_lean_rot,0.001))
