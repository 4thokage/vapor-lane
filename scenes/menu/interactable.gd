extends StaticBody3D

const MainScene:PackedScene = preload("res://scenes/main.tscn")

@export var tooltipText := "Press 'F' to start focus!"

func interact() -> void:
	if MainScene:
		get_tree().change_scene_to_packed(MainScene)
