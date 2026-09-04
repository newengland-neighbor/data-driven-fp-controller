class_name FPController extends CharacterBody3D

@export var debug : bool = false
@export_group("Node References")
@export var col_shape : CollisionShape3D
@export var camera_ref : FPCamera
@export var sound_player : AudioLibraryPlayer3D

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
@export var max_step_height : float = 0.25
##The minimum depth a step must have for the player to be able to step onto it.
@export var min_step_depth : float = 0.2
@warning_ignore("unused_signal")
const STEP_CLEARANCE : float = 0.05
# signal step_performed(lerp_target:Vector3)

@export_group("Rigidbody Interaction")
##The mass of the player body itself.
@export var player_mass : float = 80.0
##The force at which rigidbody objects should be pushed away from the player's moving body.
@export var push_force : float = 2.5
@export_group("Components")
##Array of Resource-based components used to modify base controller's behavior.
@export var components: Array[ComponentCore]

func _ready() -> void:
	%GroundCast3D.global_position = self.get_global_foot_pos()
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
	state_machine.physics_update(delta)
	for comp in components:
		comp.physics_update(delta)

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
	var data_check : bool = (
		data.has("Height")
		and data.has("Y-Position") 
		and data.has("CamY-Pos")
	)
	if !data_check: 
		printerr("Insufficient data provided.")
		return
	
	col_shape.shape.height = data["Height"]
	col_shape.position.y = data["Y-Position"]
	camera_ref._set_lerp_pt_coord(1,data["CamY-Pos"])

func _on_modifier_received(key:String,remove:bool=false,val:float=0.0) -> void:
	if remove: 
		move_speed_mods.erase(key)
		print(move_speed_mods)
		return
	move_speed_mods[key] = val

func has_modifier(key:String) -> Variant:
	@warning_ignore("incompatible_ternary")
	return null if !move_speed_mods.has(key) else move_speed_mods[key]

func get_cam_ref() -> FPCamera: return camera_ref

################
# MOVEMENT LOGIC
################
##Returns the player's direct input vector.
func get_input() -> Vector2:
	return Input.get_vector(
		"strafe_left", "strafe_right", 
		"move_forward", "move_backwards")

func get_basis_from_euler(euler:Vector3, flat_vec:Vector3 = Vector3.ONE) -> Basis:
	return Basis.from_euler(euler * flat_vec)

##Returns the player's desired, normalized movement vector.
func get_desired_direction() -> Vector3:
	var _basis : Basis = get_basis_from_euler(
		%CameraTarget.transform.basis.get_euler(),
		Vector3(0.0, 1.0, 0.0) )
	return (_basis * Vector3(get_input().x, 0.0, get_input().y) ).normalized()

##Returns the player's movement speed, including any applied modifiers.
func get_total_speed() -> float:
	var mod_avg : float = (
		1.0 if move_speed_mods.is_empty()
		else 0.0 )
	for m in move_speed_mods:
		mod_avg += move_speed_mods[m]
	return base_move_speed * mod_avg

##Global position vector value used for downward raycasting from the player.
func get_global_foot_pos() -> Vector3:
	return self.global_position + (Vector3.UP * STEP_CLEARANCE)

############################
# Physics Sweeping functions
############################
func handle_step_up(delta:float) -> bool:
	# Prerequisites.
	if (get_input() == Vector2.ZERO 
	or get_desired_direction().length() <= 0.1
	or !self.is_on_wall() ):
		return false
	
	# Sweep testing variable initialization
	var t_start : Transform3D = self.global_transform
	var t_motion : Vector3 = Vector3.UP * (max_step_height + STEP_CLEARANCE)
	var t_params : PhysicsTestMotionParameters3D = PhysOps3D.create_test_params(t_start,t_motion)
	var test : Dictionary = {}
	
	# Ceiling check: 
	# If one is collided with, the step is cancelled to prevent geometry clipping.
	test = PhysOps3D.run_test_motion(self.get_rid(),t_params)
	if test["result"]: return false
	
	# Collision sweep
	# We collect collision normals from potential "steps" with this test, then 
	# iterate through the list for the upcoming depth sweep.
	t_motion = self.get_desired_direction() * (delta * 10.0)
	t_params = PhysOps3D.create_test_params(t_start,t_motion)
	test = PhysOps3D.run_iter_test_motion(self.get_rid(),t_params)

	var col_normals : Array[Vector3]
	for i in test:
		if !test[i]["result"]: continue
		col_normals.append(test[i]["result_details"].get_collision_normal())
	
	# Step depth sweep.
	# Using the normals collected from the previous sweep, we can perform
	# further sweeps to check if the detected steps are too narrow to scale.
	# If no valid steps are found using the normals, exit function.
	t_start = t_start.translated(Vector3.UP * (max_step_height + STEP_CLEARANCE))
	var valid_step_found : bool = false
	var total_travel : Vector3 = Vector3.ZERO
	for v in col_normals:
		var m : Vector3 = -v * ((min_step_depth * 2.0) + STEP_CLEARANCE)
		t_params = PhysOps3D.create_test_params(t_start,m)
		test = PhysOps3D.run_iter_test_motion(self.get_rid(),t_params)
		for i in test:
			total_travel += test[i]["result_details"].get_travel()
		var l : float = total_travel.length()
		if l >= min_step_depth: 
			valid_step_found = true
			break
	if !valid_step_found: return false
	
	# Downward sweep test.
	# We cast down from the end position of the previously validated test.
	# If we collide with the ground, the step is valid and can be stepped up.
	t_start = t_start.translated(total_travel)
	t_motion = Vector3.DOWN * (max_step_height + STEP_CLEARANCE)
	t_params = PhysOps3D.create_test_params(t_start,t_motion)
	test = PhysOps3D.run_test_motion(self.get_rid(),t_params)
	if !test["result"]: return false
	var nrml_angle : float = Vector3.UP.angle_to(test["result_details"].get_collision_normal())
	if nrml_angle > floor_max_angle: return false
	
	# If all the tests validate the step, move the player upward by the height
	# of the step.
	var col_pt : Vector3 = t_start.origin + test["result_details"].get_travel()
	var step_height : float = absf(col_pt.y - self.global_position.y)
	self.global_position.y += step_height
	%CameraTarget.position.y -= step_height 
	return true

func handle_step_down() -> bool:
	if self.is_on_floor(): return false
	# If the ground cast doesn't hit anything, or if the distance between the collision's 
	# and the player's global positions exceeds max_step_height, exit function.
	%GroundCast3D.force_raycast_update()
	var ground_cast_check : bool = (func() -> bool:
		return true if %GroundCast3D.is_colliding() else false
		).call()
	if !ground_cast_check: return false
	
	# If collision happens, but the surface normal is too steep, exit.
	var floor_angle_deg : float = Vector3.UP.angle_to(%GroundCast3D.get_collision_normal())
	if floor_angle_deg > self.floor_max_angle: return false
	
	# Use downward shapecast to determine real step position.
	var check_params : PhysicsTestMotionParameters3D = PhysOps3D.create_test_params(
		self.global_transform,
		Vector3.DOWN * (max_step_height + STEP_CLEARANCE))
	
	# If the physics test collides with the ground, execute a downward step.
	var test : Dictionary = PhysOps3D.run_test_motion(self.get_rid(),check_params)
	if !test["result"]: return false
	
	var step_height : float = test["result_details"].get_travel().y
	self.global_position.y += step_height
	%CameraTarget.position.y -= step_height
	self.apply_floor_snap()
	return true

func ceiling_check(_range:float) -> bool:
	var check_params : PhysicsTestMotionParameters3D = PhysOps3D.create_test_params(
		self.global_transform,
		Vector3.UP * _range)
	var test : Dictionary = PhysOps3D.run_test_motion(self.get_rid(),check_params)
	return !test["result"]

#######################
# Rigidbody interaction
#######################
func handle_physics_collision() -> void:
	var col : KinematicCollision3D = self.get_last_slide_collision()
	if !col: return
	
	var col_obj : RigidBody3D = col.get_collider() as RigidBody3D
	if !col_obj: return
	
	# If the collided object's mass is equal to, or exceeds, the player's mass, cancel the push.
	var mass_ratio : float = snappedf(min(col_obj.mass / player_mass, 1.0), 0.01)
	if mass_ratio >= 1.0: return
	
	var push_direction : Vector3 = -col.get_normal()
	col_obj.apply_impulse(
		push_direction * push_force,
		col.get_position() - col_obj.global_position
	)
