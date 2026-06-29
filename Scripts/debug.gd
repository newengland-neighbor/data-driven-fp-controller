extends CanvasLayer

@export var player_ref : FPSPlayer
var camera_effects : FPSCameraEffects

@onready var debug_label = $VBoxContainer/DebugLabel

@onready var camera_tilt = $VBoxContainer/CameraTilt
@onready var cam_tilt_intensity = $VBoxContainer/CamTiltIntensity
@onready var tilt_slider = $VBoxContainer/CamTiltIntensity/HSlider

@onready var headbob = $VBoxContainer/Headbob
@onready var headbob_intensity = $VBoxContainer/HeadbobIntensity
@onready var bob_slider = $VBoxContainer/HeadbobIntensity/HSlider

func _ready() -> void:
	if !player_ref: return
	camera_effects = player_ref.find_child("PlayerCamera")
	
	headbob.toggled.connect(camera_effects.set_headbob_enabled)
	bob_slider.value_changed.connect(camera_effects.set_headbob_intensity)
	headbob.button_pressed = camera_effects.get_headbob_enabled()
	bob_slider.value = camera_effects.headbob_intensity
	set_bob_slider_visibility(headbob.button_pressed)
	
	camera_tilt.toggled.connect(camera_effects.set_camtilt_enabled)
	tilt_slider.value_changed.connect(camera_effects.set_camtilt_intensity)
	camera_tilt.button_pressed = camera_effects.get_camtilt_enabled()
	tilt_slider.value = camera_effects.tilt_intensity
	set_tilt_slider_visibility(camera_tilt.button_pressed)

func _process(_delta:float) -> void:
	if !player_ref: return
	if player_ref.debug: 
		self.visible = true
		_update_debug_label()
	else: 
		self.visible = false

# Debug function(s)
func _update_debug_label() -> void:
	var psm : FiniteStateMachine = player_ref.find_child("PlayerStateMachine")
	debug_label.text = "FPS: %d\nCurr. State: %s\nCurr. Stance: %s\nIs Grounded: %s" % [
		Engine.get_frames_per_second(), 
		psm.current_state.name,
		"Standing" if player_ref.curr_stance == 0 else "Crouching",
		str(player_ref.is_on_floor())
		]

func remove_focus() -> void:
	headbob.release_focus()
	camera_tilt.release_focus()

func set_bob_slider_visibility(new:bool) -> void:
	headbob_intensity.visible = new

func set_tilt_slider_visibility(new:bool) -> void:
	cam_tilt_intensity.visible = new
