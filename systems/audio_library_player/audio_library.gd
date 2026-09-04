class_name AudioLibrary extends Resource

@export var streams : Dictionary[String,AudioStream]
 
func get_sound_by_key(key:String) -> AudioStream:
	if !streams.has(key): return null
	return streams[key]
