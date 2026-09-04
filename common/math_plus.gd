class_name MathPlus

const DECAY : float = 16.0
static func v3_exp_decay(a:Vector3,b:Vector3,decay:float,time:float,_clamp_val:float=INF) -> Vector3:
	var offset : Vector3 = a - b
	if _clamp_val != INF: offset = offset.limit_length(_clamp_val)
	return Vector3(b+offset*exp(-decay*time))

static func f_exp_decay(a:float,b:float,decay:float,time:float) -> float:
	return b + (a - b) * exp(-decay * time)

##Returns input vector, whose elements are rounded using amnt.
static func snap_v3(input:Vector3,amnt:float) -> Vector3:
	return Vector3(
		snappedf(input.x,amnt),
		snappedf(input.y,amnt),
		snappedf(input.z,amnt)
		)

const ALIGN_THRESHOLD : float = 0.5
static func check_vector3_alignment(a:Vector3,b:Vector3) -> bool:
	var dot : float = a.dot(b)
	if dot <= ALIGN_THRESHOLD: return false
	return true
