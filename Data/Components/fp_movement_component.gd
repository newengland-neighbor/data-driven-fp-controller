class_name FPMovementComponent extends StateMachineComponent

##The base speed that the player is able to move at.
@export var base_move_speed : float = 5.0
##The speed at which linear interpolation should be performed by attached components.
@export var lerp_speed : float = 15.0
##The maximum value the player can move up (or down) when attempting to move along an uneven surface.
@export var max_step_height : float = 0.5
##The minimum depth a step must have for the player to be able to step onto it.
@export var min_step_depth : float = 0.25

signal step_performed(lerp_target:Vector3)

func bind(new_owner:Node) -> void:
	super.bind(new_owner)
	var cam_comp : FPCameraComponent = owner.get_component(FPCameraComponent)
	if cam_comp: step_performed.connect(cam_comp.override_cam_lerp_vertical)
	
	var stat_comp : StatComponent = owner.get_component(StatComponent)
	if stat_comp: base_move_speed = stat_comp.get_stat_from_block("move_speed")

func get_input() -> Vector2:
	return Input.get_vector(
		"strafe_left", "strafe_right", 
		"move_forward", "move_backwards"
		)

func get_desired_direction() -> Vector3:
	return (owner.transform.basis * Vector3(get_input().x, 0, get_input().y)).normalized()

func get_total_speed() -> float:
	var crouch_component : FPCrouchComponent = owner.get_component(FPCrouchComponent)
	if crouch_component:
		var stance : int = crouch_component.curr_stance
		if stance == FPCrouchComponent.Stances.CROUCHING:
			return base_move_speed * 0.65
	
	if !is_sprinting(): return base_move_speed
	else: return base_move_speed * 2.0

func is_sprinting() -> bool: 
	return (
		Input.is_action_pressed("sprint") 
		and current_state is FPMS_Moving
		)

func _on_step_requested(direction:int, step_height:float) -> void:
	var cam_comp : FPCameraComponent = owner.get_component(FPCameraComponent)
	var prev_pos : Vector3 = cam_comp.get_lerp_target().global_position
	match direction:
		# Step down
		-1: (func() -> void:
			owner.global_position.y += step_height
			owner.apply_floor_snap()
			#print("Stepping down...")
			).call()
		# Step up
		1: (func() -> void:
			owner.velocity.y = 0.0
			owner.global_position.y += step_height
			#print("Stepping up...")
			).call()
		# Any value whose absolute value isn't 1.
		_: 
			printerr("Function expects an integer value of either 1 or -1.")
			return
	step_performed.emit(prev_pos)

# Step-Climbing functions
func step_down() -> void: 
	# If player is on the ground, exit function.
	if owner.is_on_floor(): return
	
	# Initialize physics-testing variables.
	var check_params : PhysicsTestMotionParameters3D = _create_test_params(
		owner.global_transform,
		Vector3.DOWN * (max_step_height + 0.1)
	)
	
	# If the physics test collides with the ground, execute a downward step.
	var test : Dictionary = _run_test_motion(check_params)
	if test["result"]: 
		var y_translate : float = test["result_details"].get_travel().y
		_on_step_requested(-1, y_translate)

func step_up() -> void: 
	# If player isn't trying to moving, exit function.
	if get_desired_direction() == Vector3.ZERO: return
	
	# Initialize physics-testing variables. 
	var check_params : PhysicsTestMotionParameters3D = _create_test_params(
		owner.global_transform,
		get_desired_direction() * 0.1
	)
	
	# If the physics tests doesn't collide with anything, exit function.
	var test : Dictionary = _run_test_motion(check_params)
	if !test["result"]: return
	
	# Step depth test
	var pos_w_step_height : Vector3 = Vector3(owner.global_position + (Vector3.UP * max_step_height))
	var transform_from : Transform3D = Transform3D(Basis.IDENTITY, pos_w_step_height)
	var collision_normal : Vector3 = -test["result_details"].get_collision_normal()
	collision_normal.y = roundf(collision_normal.y)
	var test_motion : Vector3 = (
		collision_normal * min_step_depth
		if is_zero_approx(collision_normal.y)
		else (get_desired_direction() * (0.1 + owner.safe_margin))
	)
	check_params = _create_test_params(transform_from, test_motion)
	test = _run_test_motion(check_params)
	# If the test collides with geometry (the step depth is too small), exit function.
	if test["result"]: return
	
	# Ground check test
	transform_from = transform_from.translated(test_motion)
	check_params = _create_test_params(transform_from, Vector3.DOWN * max_step_height)
	test = _run_test_motion(check_params)
	# If the test doesn't collide with the ground, exit function.
	if !test["result"]: return
	
	# If floor normal exceeds floor_max_angle, exit out of function.
	collision_normal = test["result_details"].get_collision_normal()
	var floor_slope : float = snappedf(collision_normal.angle_to(Vector3.UP), 0.001)
	if (floor_slope > owner.floor_max_angle): return
	
	# Execute step up.
	var new_y : float = absf(owner.global_position.y - transform_from.origin.y)
	_on_step_requested(1, new_y)

###############################
# PhysicsServer Testing Methods
###############################
func _create_test_params(start:Transform3D,motion:Vector3) -> PhysicsTestMotionParameters3D:
	var check_params : PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
	check_params.from = start
	check_params.motion = motion
	return check_params

## Function used to test predicted body movements.
## Outputs a dictionary containing a bool (accessible with key "result")
## and a PhysicsTestMotionResult3D instance (accessible with key "result_details")
func _run_test_motion(params:PhysicsTestMotionParameters3D) -> Dictionary:
	var result_details = PhysicsTestMotionResult3D.new()
	var result : bool = PhysicsServer3D.body_test_motion(owner.get_rid(), params, result_details)
	return {
		"result" : result,
		"result_details" : result_details
	}

func ceiling_check(_range:float) -> bool:
	var check_params : PhysicsTestMotionParameters3D = _create_test_params(
		owner.global_transform,
		Vector3.UP * _range
	)
	var test : Dictionary = _run_test_motion(check_params)
	return !test["result"]
