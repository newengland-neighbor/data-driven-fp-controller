class_name FPCameraEffectComponent extends ComponentCore

##If false, the camera tilt effect will not be used.
@export var enable_tilt : bool = true
##The base amount (in degrees) that the camera should roll when moving horizontally.
@export var tilt_amnt : float = 0.5
##Modifier value used to scale the camera tilt effect.
@export_range(0.1, 1.0, 0.1) var tilt_intensity : float = 0.5

##If false, the head bob  effect will not be used.
@export var enable_headbob : bool = true
##Curves used to smoothly animate a headbob effect. Expects at least two defined curve elements.
@export var headbob_curves : Array[Curve]
##The minimum velocity magnitude the player should be moving until headbobbing begins.
@export_range(0.0, 1.0, 0.05) var speed_gate : float = 0.1
##Modifier value used to scale the head bob effect.
@export_range(0.1, 1.0, 0.1) var headbob_intensity : float = 0.5
##How fast should the headbob effect be? (Higher values = faster effect)
@export_range(0.1, 1.0, 0.05) var headbob_frequency : float = 0.25
##The base amount that the camera should move and rotate when headbobbing.
@export_range(0.0, 0.1, 0.05) var headbob_amount : float = 0.04
var step_timer : float = 0.0
var sway_timer : float = 0.0
signal request_step_sound(key:String,volume:float)
var step_volume : float = 0.0

##Modifier value used to scale the fall kick effect.
@export_range(1.0, 3.0, 0.5) var fallkick_intensity : float = 1.5
##Curve used to smoothly animate the fall kick.
@export var fall_kick_curve : Curve
##The maximum time (in seconds) a fall kick should last for
@export var max_fall_time : float = 0.5
var fall_timer : float = 0.0

var player_ref : FPController = null

signal send_modifiers(pos:Vector3, rot:Vector3)

func bind(new_owner:Node) -> void:
	if new_owner is not FPCamera:
		printerr("FPLeanComponent requires owner to be of type FPCameraComponent")
		return
	super.bind(new_owner)
	
	player_ref = new_owner.get_owner()
	if player_ref: 
		var air_state : FPMS_InAir = player_ref.state_machine.get_state(FPMS_InAir)
		if air_state: air_state.has_landed.connect(_on_landing_received)
	
	send_modifiers.connect(new_owner._on_cam_modifier_received)
	request_step_sound.connect(player_ref.sound_player.play_sound_from_key)

func ready() -> void:
	# Default curve instantiation
	if !fall_kick_curve:
		push_warning("Fall kick curve undefined.")
	if headbob_curves.is_empty() or headbob_curves.has(null):
		push_warning("Headbob curves undefined.")

func physics_update(_delta:float) -> void: 
	if !get_owner(): return
	
	var cam_pos_modifier : Vector3 = Vector3(
		get_headbob_vector(_delta)[0] # Position data
		+ get_fallkick_vector(_delta)[0]) # More position data
	
	var cam_rot_modifier : Vector3 = Vector3(
		get_tilt_rot()
		+ get_headbob_vector(_delta)[1] # Rotation data
		+ get_fallkick_vector(_delta)[1]) # More rotation data
	
	send_modifiers.emit(cam_pos_modifier, cam_rot_modifier)

func get_tilt_rot() -> Vector3:
	if !enable_tilt: return Vector3.ZERO
	
	var tilt_values : Vector2 = Vector2.ZERO
	# We make tilt independent from player's velocity to provide visual feedback for obstructed movement.
	var v : Vector3 = player_ref.get_desired_direction() * player_ref.get_total_speed()
	var speed : float = snappedf(Vector2(v.x, v.z).length(), 0.01)
	if speed > speed_gate and player_ref.is_on_floor():
		var dots : Vector2 = Vector2(
			v.dot(get_owner().global_basis.x), 
			v.dot(get_owner().global_basis.z))
		tilt_values.x = dots.y * deg_to_rad(tilt_amnt) * tilt_intensity
		tilt_values.y = dots.x * -deg_to_rad(tilt_amnt / 2.0) * tilt_intensity
	else: tilt_values = Vector2.ZERO
	return Vector3(
		snappedf(tilt_values.x, 0.0001),
		0.0, 
		snappedf(tilt_values.y, 0.0001))

var scaled_kick_strength : float = 0.0
func _on_landing_received(val:float,threshold:float) -> void:
	fall_timer = 0.0
	var a : float = clampf(
		val / threshold,
		1.0,
		3.0)
	scaled_kick_strength = snappedf(a,0.1)

func get_fallkick_vector(_delta:float) -> Array[Vector3]:
	if !fall_kick_curve: return [Vector3.ZERO, Vector3.ZERO]
	if fall_timer >= max_fall_time: return [Vector3.ZERO, Vector3.ZERO]
	if fall_timer < max_fall_time: fall_timer += _delta
	return [
		Vector3(
			0.0,
			snappedf(-fall_kick_curve.sample_baked(fall_timer) * 0.1, 0.0001), 
			0.0),
		Vector3(
			snappedf(-deg_to_rad((fall_kick_curve.sample_baked(fall_timer) * fallkick_intensity) * scaled_kick_strength), 0.0001), 
			0.0, 
			0.0)]

func set_step_volume(new:float) -> void:
	step_volume = new

func get_headbob_vector(_delta:float) -> Array[Vector3]:
	var prereq_check : bool = (
		headbob_curves.is_empty()
		or headbob_curves.has(null))
	if prereq_check : return [Vector3.ZERO, Vector3.ZERO]
	
	if Vector2.ZERO.is_equal_approx(player_ref.get_input()): 
		# We set step and sway timers to half their max value so that each step 
		# (including your first) produces a consistent timing to player's steps.
		step_timer = 0.5
		sway_timer = 0.5
		return [Vector3.ZERO, Vector3.ZERO]
	
	var v : Vector3 = player_ref.get_real_velocity()
	var speed : float = snappedf(Vector2(v.x, v.z).length(), 0.01)
	if speed > speed_gate and player_ref.is_on_floor():
		step_timer += _delta * (speed * headbob_frequency)
		sway_timer += _delta * (speed * headbob_frequency) / 2
		
		if step_timer >= 1.0:
			request_step_sound.emit("footsteps",step_volume)
			step_timer = 0.0
		sway_timer = fmod(sway_timer, 1.0)
		
		if !enable_headbob: return [Vector3.ZERO, Vector3.ZERO]
		
		var bob_y : float = snappedf(
			headbob_curves[0].sample_baked(step_timer) * headbob_amount * headbob_intensity,
			0.0001)
		var sway_z : float = snappedf(
			headbob_curves[1].sample_baked(sway_timer) * headbob_amount * headbob_intensity,
			0.0001)
		
		return [Vector3(0.0, bob_y, 0.0), Vector3(0.0, 0.0, sway_z / 4.0)]
	return [Vector3.ZERO, Vector3.ZERO]
