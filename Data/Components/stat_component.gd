class_name StatComponent extends ComponentCore

@export var stat_block : ActorStats

var curr_health : float 
var curr_stamina : float

signal stat_updated(data:Dictionary)

func bind(new_owner:Node) -> void:
	super.bind(new_owner)
	
	curr_health = stat_block.get_attribute_by_key("max_health")
	
	var has_stamina : Variant = stat_block.get_attribute_by_key("max_stamina")
	if has_stamina is float: curr_stamina = has_stamina 
	
	var move_comp : FPMovementComponent = owner.get_component(FPMovementComponent)
	if move_comp: 
		var fall_state : FPMS_Falling = move_comp.get_state(FPMS_Falling)
		if fall_state: fall_state.has_landed.connect(_on_fall_damage_received)

func ready() -> void: pass
func update(_delta:float) -> void: pass
func physics_update(_delta:float) -> void: pass
func handle_input(_event:InputEvent) -> void: pass

func get_stat_from_block(query:String) -> Variant:
	return stat_block.get_attribute_by_key(query)

func _modify_current_health(mod:float) -> void:
	curr_health = clampf(curr_health + mod, 0.0, stat_block.get_attribute_by_key("max_health"))
	stat_updated.emit({"max_health": curr_health})
	print("Current Health: %d" % curr_health)

const DAMAGE_THRESHOLD : float = -10.0
func _on_fall_damage_received(fall_velocity:float,fall_threshold:float) -> void:
	if fall_velocity < fall_threshold:
		var fall_dmg : float = -snappedf(
			absf((fall_velocity / fall_threshold) ** 3),
			0.1
		)
		if fall_dmg >= DAMAGE_THRESHOLD : return
		print("Fall damage received! Value: %.2f" % fall_dmg)
		_modify_current_health(fall_dmg)


	
