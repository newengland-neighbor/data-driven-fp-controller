extends CanvasLayer

@export var player_ref : FPController
@onready var debug_label = $VBoxContainer/DebugLabel

func _ready() -> void:
	if !player_ref: return

func _process(_delta:float) -> void:
	if !player_ref: return
	if player_ref.debug: 
		self.visible = true
		_update_debug_label()
	else: 
		self.visible = false

# Debug function(s)
func _update_debug_label() -> void:
	var psm : StateMachineComponent = player_ref.state_machine
	debug_label.text = "FPS: %d\nCurr. State: %s\nIs Grounded: %s" % [
		Engine.get_frames_per_second(), 
		psm.current_state.get_state_name(),
		str(player_ref.is_on_floor())
		]
