class_name FPController extends CharacterBody3D

##Array of Resource-based components powering various mechanics.
@export var components: Array[ComponentCore]

func _ready() -> void:
	for comp in components:
		comp.bind(self)
		comp.ready()

func _process(delta: float) -> void:
	for comp in components:
		comp.update(delta)

func _physics_process(delta: float) -> void:
	for comp in components:
		comp.physics_update(delta)
	%CollisionShape3D.global_rotation = Vector3.ZERO

func _unhandled_input(_event:InputEvent):
	for comp in components:
		comp.handle_input(_event)

func get_component(query:Object) -> ComponentCore:
	for comp in components:
		if is_instance_of(comp,query): return comp
	return null

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
	var cam_comp : FPCameraComponent = get_component(FPCameraComponent)
	if cam_comp: cam_comp.set_lerp_pt_coord(1,data["CamY-Pos"])
