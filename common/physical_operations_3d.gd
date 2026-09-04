class_name PhysOps3D

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

## Runs a body test motion on the Physics Server. If any remaining movement is present after the first test,
## the remainder is projected along the surface the body collided with. This is done until the remainder's length
## is 0.0. Returns a dictionary containing the data from each recorded collision.
static func run_test_motion_recursive(body:RID,params:PhysicsTestMotionParameters3D,_project_mod:Vector3 = Vector3(1,1,1),_prev_results:Dictionary={}) -> Dictionary:
	var result_details : PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
	var result : bool = PhysicsServer3D.body_test_motion(body, params, result_details)
	var output : Dictionary = _prev_results
	
	var index : int = output.size()
	output[index] = {"result" : result, "result_details" : result_details}
	
	if result and result_details.get_remainder().length() > 0.0:
		var new_params : PhysicsTestMotionParameters3D = create_test_params(
			params.from.translated(params.motion.normalized() * result_details.get_travel()),
			result_details.get_remainder().slide(
				(result_details.get_collision_normal() * _project_mod).normalized()
				))
		run_test_motion_recursive(body,new_params,_project_mod,output)
	
	return output

static func run_test_move_iter(body:PhysicsBody3D,from:Transform3D,motion:Vector3,result:KinematicCollision3D=KinematicCollision3D.new(),iterations:int=4) -> Dictionary:
	var output : Dictionary = {}
	for i in iterations:
		var test : bool = body.test_move(from,motion,result)
		from = from.translated(result.get_travel())
		if !test: break
		output[i] = {
			"position":from.origin,
			"motion":motion,
			"travel":result.get_travel(),
			"collided?":test,
			"normal":Vector3.ZERO if !test else result.get_normal() 
			}
		motion = motion.slide(result.get_normal())
	return output

##Returns the result of a direct ray cast.
static func shoot_ray_3d(space:PhysicsDirectSpaceState3D,from:Vector3,to:Vector3,_col_mask:int=1,_exclusions:Array[RID]=[]) -> Dictionary:
	# use global coordinates, not local to node
	var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from,to,_col_mask,_exclusions)
	var result : Dictionary = space.intersect_ray(query)
	return result
