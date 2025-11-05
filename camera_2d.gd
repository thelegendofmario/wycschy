extends Camera2D

func _process(delta: float) -> void:
	if get_multiplayer_authority() == multiplayer.get_unique_id(): make_current()
