class_name MathPlus

const DECAY : float = 16.0
static func v3_exp_decay(a:Vector3,b:Vector3,decay:float,time:float) -> Vector3:
	return Vector3(b+(a-b)*exp(-decay*time))
