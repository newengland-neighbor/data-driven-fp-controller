class_name GroundCast3D extends RayCast3D

func _ready() -> void: pass

func _physics_process(_delta: float) -> void:
	if !self.is_colliding(): return

func get_collision_data() -> Dictionary:
	var output : Dictionary = {}
	output["position"] = self.get_collision_point()
	output["normal"] = self.get_collision_normal()
	output["slope"] = Vector3.UP.angle_to(self.get_collision_normal())
	return output
