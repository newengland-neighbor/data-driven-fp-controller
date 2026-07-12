class_name FPCamera extends Camera3D

##The maximum value the camera should be able to rotate along its x-axis.
@export var max_pitch : float = 90.0
##The minimum value the camera should be able to rotate along its x-axis.
@export var min_pitch : float = -75.0

##The base speed at which the camera is moved towards it's lerp target.
##Total is modified by the player's MovementComponent, if it's present.
@export var cam_lerp_speed : float = 5.0

##The speed at which the camera rotates as a result from mouse movement.
@export_range(0.1, 1.0, 0.1) var mouse_sensitivity : float = 1.0

##The target position that the camera should attempt to lerp towards.
@export var camera_target : Marker3D
var _target_lerp_pos : Vector3 = Vector3(0.0, 1.5, 0.0)

##Array of components that modify FPCamera's behavior.
@export var components : Array[ComponentCore]

var player_ref : FPController = null
var is_frozen : bool = false

var _cam_pos_mod : Vector3 = Vector3.ZERO
var _cam_rot_mod : Vector3 = Vector3.ZERO

func _ready() -> void: 
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	self.global_position = camera_target.global_position
	
	player_ref = get_parent() as FPController
	if !player_ref: 
		printerr("FPCamera requires parent node to be of type FPController.")
		return
	
	for comp in components:
		comp.bind(self)
		comp.ready()

func _physics_process(_delta: float) -> void: 
	if !player_ref: return
	
	handle_mouse_rotation.call_deferred(_delta)
	for comp in components:
		comp.physics_update(_delta)

func _process(_delta: float) -> void: 
	if !player_ref: return
	for comp in components:
		comp.update(_delta)

var desired_rotation : Vector2
func _unhandled_input(_event: InputEvent) -> void: 
	if is_frozen or !player_ref: return
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
	
	for comp in components:
		comp.handle_input(_event)

const DECAY : float = 25.0
var lerped_rot_mods : Vector3 = Vector3.ZERO
func handle_mouse_rotation(_delta:float) -> void:
	# Mouse rotation
	camera_target.rotate_y(desired_rotation.y)
	camera_target.rotation.x = clampf(
		camera_target.rotation.x + desired_rotation.x,
		deg_to_rad(min_pitch),
		deg_to_rad(max_pitch)
	)
	desired_rotation = Vector2.ZERO
	
	var _basis : Basis = player_ref.get_basis_from_euler(
		camera_target.transform.basis.get_euler(),
		Vector3(0.0, -1.0, 0.0)
	)
	
	# 1st smoothing layer
	# Camera target position travels to provided local vector
	camera_target.position = MathPlus.v3_exp_decay(
		camera_target.position,
		(_target_lerp_pos + _cam_pos_mod) * _basis,
		DECAY,
		_delta
	)
	
	# 2nd smoothing layer
	# Camera global position travels to camera_target's.
	self.global_position = MathPlus.v3_exp_decay(
		self.global_position,
		camera_target.global_position,
		DECAY,
		_delta
	)
	
	# Camera rotation matches the camera target's (along with added modifiers)
	# Since we don't want the rotation itself to be lerped, we instead lerp the 
	# modifier array to ensure smooth effects.
	lerped_rot_mods = lerp(lerped_rot_mods, _cam_rot_mod, _delta * cam_lerp_speed / 2.2)
	self.global_rotation = Vector3(
		camera_target.global_rotation.x + lerped_rot_mods.x,
		camera_target.global_rotation.y + lerped_rot_mods.y,
		camera_target.global_rotation.z + lerped_rot_mods.z + lean_rot_z
		)

func get_lerp_target() -> Marker3D: return camera_target

##Method used to modify values of the camera's lerp target.
##(0 = x-axis, 1 = y-axis, 2 = z-axis)
func _set_lerp_pt_coord(axis:int,val:float) -> void:
	match axis:
		0: _target_lerp_pos.x = val
		1: _target_lerp_pos.y = val
		2: _target_lerp_pos.z = val
		_: pass

func override_cam_target_y(new:float) -> void: camera_target.position.y = new

func set_frozen_status(new:bool) -> void: is_frozen = new

func _on_cam_modifier_received(pos:Vector3, rot:Vector3) -> void:
	_cam_pos_mod = pos
	_cam_rot_mod = rot

var lean_rot_z : float = 0.0
func _on_lean_modifier_received(val:float) -> void:
	lean_rot_z = val
