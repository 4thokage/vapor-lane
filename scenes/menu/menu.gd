extends Node3D

const target_scene_path = "res://procedural_generator.tscn"

var loading_status : int

@onready var fade_rect = $CanvasLayer/FadeRect  # Ensure you have a ColorRect node for the fade effect

func _ready() -> void:
	# Request to load the target scene in the background
	ResourceLoader.load_threaded_request(target_scene_path)
	
	# Initially hide the button until loading is finished
	$CanvasLayer/VBoxContainer/Button.visible = false
	
	# Make sure the fade effect is invisible at first
	fade_rect.visible = true
	fade_rect.color.a = 0

func _process(_delta: float) -> void:
	# Update the loading status:
	loading_status = ResourceLoader.load_threaded_get_status(target_scene_path)
	
	# Check the loading status:
	if loading_status == ResourceLoader.THREAD_LOAD_LOADED:
		# When done loading, show the button to change scenes
		$CanvasLayer/VBoxContainer/Button.visible = true

func _on_button_pressed() -> void:
	# Ensure the scene is fully loaded before changing
	var packed_scene = ResourceLoader.load_threaded_get(target_scene_path)
	if packed_scene:
		# Start fade-out effect
		get_tree().change_scene_to_packed(packed_scene)
