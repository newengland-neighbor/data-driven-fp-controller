class_name AudioLibraryPlayer3D extends AudioStreamPlayer3D

@export var audio_library : AudioLibrary

func _ready() -> void:
	self.stream = AudioStreamPolyphonic.new()

func play_sound_from_key(key:String,_db:float=0.0) -> void:
	var stream_to_play : AudioStream = audio_library.get_sound_by_key(key)
	if stream_to_play == null: 
		printerr("%s's Audio Library does not contain %s." % [get_parent().name,key])
		return
	
	if !playing: self.play()
	var playback := self.get_stream_playback() as AudioStreamPlaybackPolyphonic
	playback.play_stream(
		stream_to_play,
		0.0,
		_db,
		1.0,
		AudioServer.PlaybackType.PLAYBACK_TYPE_DEFAULT,
		&"SoundEffects")
	
