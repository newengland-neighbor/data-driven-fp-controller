class_name PhysOps3D

## Function used to quickly creates test parameters for motion testing functions. 
## Returns a PhysicsTestMotionParameters3D object.
static func create_test_params(start:Transform3D,motion:Vector3,_col_count:int=1) -> PhysicsTestMotionParameters3D:
	var check_params : PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
	check_params.from = start
	check_params.motion = motion
	check_params.max_collisions = _col_count
	return check_params

## Function used to test predicted body movements.
## Outputs a dictionary containing a bool (accessible with key "result")
## and a PhysicsTestMotionResult3D instance (accessible with key "result_details")
static func run_test_motion(body:RID,params:PhysicsTestMotionParameters3D) -> Dictionary:
	var result_details : PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
	var result : bool = PhysicsServer3D.body_test_motion(body, params, result_details)
	return {
		"result" : result,
		"result_details" : result_details
	}

## Function used to iteratively test predicted body movements.
## Outputs a dictionary containing subdictionaries each containing a bool (accessible with key "result")
## and a PhysicsTestMotionResult3D instance (accessible with key "result_details")
static func run_iter_test_motion(body:RID,params:PhysicsTestMotionParameters3D,_iter:int=2,_flat_vec:Vector3=Vector3.ONE) -> Dictionary:
	var output : Dictionary = {}
	for i in _iter:
		var result_details : PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
		var result : bool = PhysicsServer3D.body_test_motion(body, params, result_details)
		output[i] = {"result":result, "result_details":result_details}
		if !result: break
		params.from = params.from.translated(result_details.get_travel())
		params.motion = params.motion.slide(result_details.get_collision_normal()) * _flat_vec
	return output

##Returns the result of a direct ray cast.
static func shoot_ray_3d(space:PhysicsDirectSpaceState3D,from:Vector3,to:Vector3,_col_mask:int=1,_exclusions:Array[RID]=[]) -> Dictionary:
	# use global coordinates, not local to node
	var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from,to,_col_mask,_exclusions)
	var result : Dictionary = space.intersect_ray(query)
	return result
