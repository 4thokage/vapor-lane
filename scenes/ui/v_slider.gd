extends HSlider


@export var audio_bus_name := "Music"

@onready var _bus := AudioServer.get_bus_index(audio_bus_name)


func _ready() -> void:
	value = db_to_linear(AudioServer.get_bus_volume_db(_bus))


func _on_value_changed(val: float) -> void:
	AudioServer.set_bus_volume_db(_bus, linear_to_db(val))
