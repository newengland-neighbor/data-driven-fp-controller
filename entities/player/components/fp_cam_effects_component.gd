class_name FPCameraEffectComponent extends Subcomponent

@export var enable_tilt : bool = true
@export var tilt_amnt : float = 0.5
@export_range(0.1, 1.0, 0.1) var tilt_intensity : float = 0.5

@export var enable_headbob : bool = true
@export var headbob_curves : Array[Curve]
@export_range(0.1, 1.0, 0.1) var headbob_intensity : float = 0.5
@export_range(0.0, 6.0, 0.01) var headbob_frequency : float = 3.5
@export_range(0.0, 0.1, 0.01) var headbob_amount : float = 0.04
var step_timer : float = 0.0
var sway_timer : float = 0.0
signal request_step_sound

@export var fall_kick_curve : Curve
@export var max_fall_time : float = 0.5
var fall_timer : float = 0.0

var cam_pos_modifier : Vector3 = Vector3.ZERO
var cam_rot_modifier : Vector3 = Vector3.ZERO

signal send_modifiers(pos:Vector3, rot:Vector3)

func bind(new:ComponentCore) -> void:
	if new is not FPCameraComponent:
		printerr("FPLeanComponent requires owner to be of type FPCameraComponent")
		return
	super.bind(new)
	
	var move_comp : FPMovementComponent = component_owner.get_owner().get_component(FPMovementComponent)
	if move_comp: 
		var fall_state : FPMS_Falling = move_comp.get_state(FPMS_Falling)
		if fall_state: fall_state.has_landed.connect(_on_landing_received)
	
	send_modifiers.connect(component_owner._on_cam_modifier_received)

func ready() -> void: pass
func handle_input(_event:InputEvent) -> void: pass

func update(_delta:float) -> void: 
	if !component_owner: return
	
	cam_pos_modifier = (
		get_headbob_vector(_delta)[0] # Position data
		+ get_fallkick_vector(_delta)[0] # More position data
	)
	
	cam_rot_modifier = (
		get_tilt_rot()
		+ get_headbob_vector(_delta)[1] # Rotation data
		+ get_fallkick_vector(_delta)[1] # More rotation data
	)
	
	send_modifiers.emit(cam_pos_modifier, cam_rot_modifier)

func physics_update(_delta:float) -> void: pass

func get_tilt_rot() -> Vector3:
	if !enable_tilt: return Vector3.ZERO
	var tilt_values : Vector2 = Vector2.ZERO
	var player_ref : FPController = component_owner.get_owner()
	var v : Vector3 = player_ref.velocity
	var speed : float = Vector2(v.x, v.z).length()
	if speed > 0.1 and player_ref.is_on_floor():
		var dots : Vector2 = Vector2(
			v.dot(component_owner.get_camera_node().global_basis.x), 
			v.dot(component_owner.get_camera_node().global_basis.z)
			)
		tilt_values.x = dots.y * deg_to_rad(tilt_amnt) * tilt_intensity
		tilt_values.y = dots.x * -deg_to_rad(tilt_amnt / 2.0) * tilt_intensity
	else: tilt_values = Vector2.ZERO
	return Vector3(tilt_values.x, 0.0, tilt_values.y)

var fall_kick_intensity : float = 0.0
func _on_landing_received(val:float,threshold:float) -> void:
	fall_timer = 0.0
	var a : float = clampf(
		val / threshold,
		1.0,
		3.0
	)
	fall_kick_intensity = snappedf(a,0.1)

func get_fallkick_vector(_delta:float) -> Array[Vector3]:
	if fall_timer >= max_fall_time: return [Vector3.ZERO, Vector3.ZERO]
	if fall_timer < max_fall_time: fall_timer += _delta
	return [
		Vector3(0.0, -fall_kick_curve.sample_baked(fall_timer) * 0.1, 0.0),
		Vector3(-deg_to_rad((fall_kick_curve.sample_baked(fall_timer) * 2.5) * fall_kick_intensity), 0.0, 0.0)
	]

func get_headbob_vector(_delta:float) -> Array[Vector3]:
	var player_ref : FPController = component_owner.get_owner()
	var v : Vector3 = player_ref.velocity
	var speed : float = Vector2(v.x, v.z).length()
	#print(speed)
	if speed > 0.1 and player_ref.is_on_floor():
		step_timer += _delta * (speed / headbob_frequency)
		sway_timer += _delta * (speed / headbob_frequency) / 2
		if step_timer >= 1.0:
			request_step_sound.emit()
			step_timer = 0.0
		sway_timer = fmod(sway_timer, 1.0)
		if !enable_headbob: 
			return [Vector3.ZERO, Vector3.ZERO]
		var bob_y : float = headbob_curves[0].sample_baked(step_timer) * headbob_amount * headbob_intensity
		var sway_z : float = headbob_curves[1].sample_baked(sway_timer) * headbob_amount * headbob_intensity
		return [Vector3(0.0, bob_y, 0.0), Vector3(0.0, 0.0, deg_to_rad(sway_z * 2.0))]
	return [Vector3.ZERO, Vector3.ZERO]
