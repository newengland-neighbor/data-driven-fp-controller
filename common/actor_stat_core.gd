class_name ActorStats extends Resource

@export var actor_name : String = "Default"
@export var actor_attributes : Dictionary[String,Variant]

func get_attribute_by_key(query:String) -> Variant:
	if !actor_attributes.has(query): return null
	return actor_attributes[query]
