class_name DoorState extends StateResource

enum DoorStates {CLOSED, OPEN}

func bind(new:ComponentCore,indx:int) -> void:
	super.bind(new,indx)

func on_input_received() -> void: pass
