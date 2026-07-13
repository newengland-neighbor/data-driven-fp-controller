class_name FPController extends CharacterBody3D

@export_group("Movement")
##The base speed that the player is able to move at.
@export var base_move_speed : float = 5.0
##The speed at which linear interpolation should be performed by attached components.
@export var lerp_speed : float = 15.0

##State machine used to handle player movement logic.
@export var state_machine : StateMachineComponent
##List of modifiers received from components used to modify the player's movement speed.
var move_speed_mods : Dictionary[String,float]

@export_group("Step Climbing")
##The maximum value the player can move up (or down) when attempting to move along an uneven surface.
@export var max_step_height : float = 0.5
##The minimum depth a step must have for the player to be able to step onto it.
@export var min_step_depth : float = 0.25
@warning_ignore("unused_signal")
signal step_performed(lerp_target:Vector3)

@export_group("Rigidbody Interaction")
@export var player_mass : float = 80.0
@export var push_force : float = 2.5
@export_group("Components")
##Array of Resource-based components used to modify base controller's behavior.
@export var components: Array[ComponentCore]

func _ready() -> void:
	state_machine.bind(self)
	state_machine.ready()
	
	for comp in components:
		comp.bind(self)
		comp.ready()

func _process(delta: float) -> void:
	state_machine.update(delta)
	for comp in components:
		comp.update(delta)

func _physics_process(delta: float) -> void:
	#handle_ground_hover(delta)
	state_machine.physics_update(delta)
	for comp in components:
		comp.physics_update(delta)
	#%CollisionShape3D.global_rotation = Vector3.ZERO

# NOTE TO SELF:
# The docs state that, for key input(s), using _unhandled_key_input() would be more performant.
# Consider expanding component / move state behavior to receive such a function.
func _unhandled_input(_event:InputEvent):
	state_machine.handle_input(_event)
	for comp in components:
		comp.handle_input(_event)

##Returns reference of component matching query's type if it's found in the player's component array.
##Otherwise returns null.
func get_component(query:Object) -> ComponentCore:
	for comp in components:
		if is_instance_of(comp,query): return comp
	return null

##Some components will require certain nodes to exist for their functionality.
##They call this function via signal to spawn said node as a child of the player.
func _on_request_node(new:Node) -> void:
	self.add_child(new)

func set_cylinder_shape_dimensions(data:Dictionary) -> void:	
	if !%CollisionShape3D.shape is CylinderShape3D:
		printerr("CollisionShape isn't a cylinder.")
		return
	
	var data_check : bool = (
		data.has("Height")
		and data.has("Y-Position") 
		and data.has("CamY-Pos")
	)
	if !data_check: 
		printerr("Insufficient data provided.")
		return
	
	%CollisionShape3D.shape.height = data["Height"]
	%CollisionShape3D.position.y = data["Y-Position"]
	%PlayerCamera._set_lerp_pt_coord(1,data["CamY-Pos"])

func _on_modifier_received(key:String,remove:bool=false,val:float=0.0) -> void:
	if remove: 
		move_speed_mods.erase(key)
		print(move_speed_mods)
		return
	move_speed_mods[key] = val
	print(move_speed_mods)

func has_modifier(key:String) -> Variant:
	@warning_ignore("incompatible_ternary")
	return null if !move_speed_mods.has(key) else move_speed_mods[key]

################
# MOVEMENT LOGIC
################
func get_input() -> Vector2:
	return Input.get_vector(
		"strafe_left", "strafe_right", 
		"move_forward", "move_backwards"
		)

func get_basis_from_euler(euler:Vector3, flat_vec:Vector3 = Vector3.ONE) -> Basis:
	return Basis.from_euler(euler * flat_vec)

# Since the CameraTarget node is what's *actually* affected by mouse movement input,
# we want to base the actual movement vector off of it's horizontal basis.
func get_desired_direction() -> Vector3:
	var _basis : Basis = get_basis_from_euler(
		%CameraTarget.transform.basis.get_euler(),
		Vector3(0.0, 1.0, 0.0)
	)
	return (_basis * Vector3(get_input().x, 0, get_input().y)).normalized()

func get_total_speed() -> float:
	var mod_avg : float = (
		1.0 if move_speed_mods.is_empty()
		else 0.0
	)
	for m in move_speed_mods:
		mod_avg += move_speed_mods[m]
	return base_move_speed * mod_avg

func get_cam_ref() -> Camera3D: return %PlayerCamera

# Step-Climbing functions
func _on_step_requested(direction:int, step_height:float) -> void:
	#var cam_comp : FPCameraComponent = self.get_component(FPCameraComponent)
	match direction:
		# Step down
		-1: (func() -> void:
			self.global_position.y += step_height
			self.apply_floor_snap()
			%CameraTarget.global_position.y -= step_height
			#print("Stepping down...")
			).call()
		# Step up
		1: (func() -> void:
			self.velocity.y = 0.0
			self.global_position.y += step_height
			%CameraTarget.global_position.y -= step_height
			#print("Stepping up...")
			).call()
		# Any value whose absolute value isn't 1.
		_: 
			printerr("Function expects an integer value of either 1 or -1.")
			return

func step_down() -> void: 
	# If player is on the ground, exit function.
	if self.is_on_floor(): return
	
	# Initialize physics-testing variables.
	var check_params : PhysicsTestMotionParameters3D = _create_test_params(
		self.global_transform,
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
		self.global_transform,
		get_desired_direction() * 0.1
	)
	
	# If the physics tests doesn't collide with anything, exit function.
	var test : Dictionary = _run_test_motion(check_params)
	if !test["result"]: return
	if test["result_details"].get_collider() is RigidBody3D: return
	
	# Step depth test
	var pos_w_step_height : Vector3 = Vector3(self.global_position + (Vector3.UP * max_step_height))
	var transform_from : Transform3D = Transform3D(Basis.IDENTITY, pos_w_step_height)
	var collision_normal : Vector3 = -test["result_details"].get_collision_normal()
	collision_normal.y = roundf(collision_normal.y)
	var test_motion : Vector3 = (
		collision_normal * min_step_depth
		if is_zero_approx(collision_normal.y)
		else (get_desired_direction() * (0.1 + self.safe_margin))
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
	if (floor_slope > self.floor_max_angle): return
	
	# Execute step up.
	var new_y : float = absf(self.global_position.y - transform_from.origin.y)
	_on_step_requested(1, new_y)

# PhysicsServer Testing Methods
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
	var result : bool = PhysicsServer3D.body_test_motion(self.get_rid(), params, result_details)
	return {
		"result" : result,
		"result_details" : result_details
	}

func ceiling_check(_range:float) -> bool:
	var check_params : PhysicsTestMotionParameters3D = _create_test_params(
		self.global_transform,
		Vector3.UP * _range
	)
	var test : Dictionary = _run_test_motion(check_params)
	return !test["result"]

#######################
# Rigidbody interaction
#######################
func handle_physics_collision() -> void:
	var col : KinematicCollision3D = self.get_last_slide_collision()
	if !col: return
	
	var col_obj : RigidBody3D = col.get_collider() as RigidBody3D
	if !col_obj: return
	
	#var mass_ratio : float = snappedf(min(player_mass / col_obj.mass, 1.0), 0.01)
	
	var push_direction : Vector3 = -col.get_normal()
	#var pf : float = (
		#owner.velocity.dot(push_direction)
		#- col_obj.linear_velocity.dot(push_direction)
	#)
	
	col_obj.apply_impulse(
		push_direction * push_force,
		col.get_position() - col_obj.global_position
	)
