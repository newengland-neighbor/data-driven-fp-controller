class_name FPCameraComponent extends ComponentCore

##The maximum value the camera should be able to rotate along its x-axis.
@export var max_pitch : float = 90.0
##The minimum value the camera should be able to rotate along its x-axis.
@export var min_pitch : float = -75.0
##The base speed at which the camera is moved towards it's lerp target.
##Total is modified by the player's MovementComponent, if it's present.
@export var cam_lerp_speed : float = 5.0
##The speed at which the camera rotates as a result from mouse movement.
@export_range(0.1, 1.0, 0.1) var mouse_sensitivity : float = 1.0

##Array of subcomponents that modify CameraComponent behavior.
@export var subcomponents : Array[Subcomponent]

var is_frozen : bool = false
var desired_rotation : Vector2

var camera_ref : Node3D = null
var lerp_target : Marker3D = null
var character_body_ref : FPController

var _target_lerp_pos : Vector3 = Vector3(0.0, 1.5, 0.0)
var _cam_pos_mod : Vector3 = Vector3.ZERO
var _cam_rot_mod : Vector3 = Vector3.ZERO

signal request_node(new:Node)

func bind(new_owner:Node) -> void:
	super.bind(new_owner)
	character_body_ref = owner
	
	request_node.connect(owner._on_request_node)
	
	var lerp_pt : Marker3D = Marker3D.new()
	lerp_pt.name = "LerpTarget"
	request_node.emit(lerp_pt)
	lerp_target = lerp_pt
	lerp_target.position = _target_lerp_pos
	
	var cam : Camera3D = Camera3D.new()
	cam.name = "FPCamera"
	request_node.emit(cam)
	camera_ref = cam
	camera_ref.top_level = true
	camera_ref.global_position = lerp_target.global_position
	
	for subcomp in subcomponents:
		subcomp.bind(self)

func ready() -> void: 
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for subcomp in subcomponents:
		subcomp.ready()

func update(_delta:float) -> void: 
	var move_comp : FPMovementComponent = owner.get_component(FPMovementComponent)
	if !move_comp:
		printerr("Error: FPMovementComponent required!")
		return
	
	var speed_mod : float = move_comp.get_total_speed() 
	lerp_target.position = lerp(
		lerp_target.position,
		_target_lerp_pos,
		_delta * speed_mod * cam_lerp_speed
	)

	for subcomp in subcomponents:
		subcomp.update(_delta)

var lerped_rot_mods : Vector3 = Vector3.ZERO
func physics_update(_delta:float) -> void: 
	character_body_ref.rotate_y(desired_rotation.y)
	lerp_target.rotate_x(desired_rotation.x)
	lerp_target.rotation.x = clamp(lerp_target.rotation.x,deg_to_rad(min_pitch),deg_to_rad(max_pitch))
	desired_rotation = Vector2.ZERO
	
	const CAM_LERP_SPEED : float = 50.0
	var lerp_with_mods : Vector3 = lerp_target.position + _cam_pos_mod
	
	camera_ref.global_position = lerp(
		camera_ref.global_position,
		owner.to_global(lerp_with_mods),
		_delta * CAM_LERP_SPEED
		)
	
	lerped_rot_mods = lerp(lerped_rot_mods, _cam_rot_mod, _delta * CAM_LERP_SPEED / 2.0)
	camera_ref.global_rotation = Vector3(
		lerp_target.global_rotation.x + lerped_rot_mods.x,
		lerp_target.global_rotation.y + lerped_rot_mods.y,
		lerp_target.global_rotation.z + lerped_rot_mods.z + lean_rot_z
		)
	
	for subcomp in subcomponents:
		subcomp.physics_update(_delta)

func handle_input(_event:InputEvent) -> void: 
	if is_frozen: return
	if _event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Polling rate cap to avoid choppy camera movement.
		if abs(_event.screen_relative.x) + abs(_event.screen_relative.y) > 500.0: return
		# Add event values to desired_rotation Vector2.
		desired_rotation.x += deg_to_rad(-_event.screen_relative.y * 0.085 * mouse_sensitivity)
		desired_rotation.y += deg_to_rad(-_event.screen_relative.x * 0.085 * mouse_sensitivity)
	
	if _event.is_action("ui_cancel") and _event.is_pressed():
		Input.mouse_mode = (
			Input.MOUSE_MODE_CAPTURED
			if !Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_VISIBLE
		)
	
	for subcomp in subcomponents:
		subcomp.handle_input(_event)

func get_camera_node() -> Node3D: return camera_ref
func get_lerp_target() -> Marker3D: return lerp_target

##Method used to modify values of the camera's lerp target.
##(0 = x-axis, 1 = y-axis, 2 = z-axis)
func set_lerp_pt_coord(axis:int,val:float) -> void:
	match axis:
		0: _target_lerp_pos.x = val
		1: _target_lerp_pos.y = val
		2: _target_lerp_pos.z = val
		_: pass

func override_cam_lerp_vertical(new:Vector3) -> void: 
	var move_comp : FPMovementComponent = owner.get_component(FPMovementComponent)
	# We want to clamp new.y so that the camera doesn't lerp too far in one 
	# direction or the other - it would make for weird movement up steeper 
	# slopes.
	new.y = clampf(
		new.y,
		owner.to_global(_target_lerp_pos).y - move_comp.max_step_height,
		owner.to_global(_target_lerp_pos).y + move_comp.max_step_height
	)
	lerp_target.global_position.y = new.y

func set_frozen_status(new:bool) -> void: is_frozen = new

func _on_cam_modifier_received(pos:Vector3, rot:Vector3) -> void:
	_cam_pos_mod = pos
	_cam_rot_mod = rot

var lean_rot_z : float = 0.0
func _on_lean_modifier_received(val:float) -> void:
	lean_rot_z = val
