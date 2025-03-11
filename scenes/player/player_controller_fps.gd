extends PlayerController

@onready var _player_pcam: PhantomCamera3D = %PlayerPhantomCamera3D

@onready var _player_character: CharacterBody3D = %PlayerCharacterBody3D

@export var mouse_sensitivity: float = 0.06

@export var min_pitch: float = -89.9
@export var max_pitch: float = 50

@export var min_yaw: float = 0
@export var max_yaw: float = 360

@export var run_noise: PhantomCameraNoise3D
@onready var vision_r_cast: RayCast3D = %VisionRCast
@onready var action_tooltip_label: Label = $CanvasLayer/CenterCont/ActionTooltipLabel

func _ready() -> void:
	super()


func _physics_process(delta: float) -> void:
	super(delta)
	action_tooltip_label.hide()
	if vision_r_cast.is_colliding():
		var target = vision_r_cast.get_collider()
		if(target.has_method("interact")):
			action_tooltip_label.text = target.tooltipText
			action_tooltip_label.show()
			if Input.is_action_pressed("interact"):
				target.interact()

func _unhandled_input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventMouseMotion:
		var pcam_rotation_degrees: Vector3

		pcam_rotation_degrees = _player_pcam.rotation_degrees
		pcam_rotation_degrees.x -= event.relative.y * mouse_sensitivity
		pcam_rotation_degrees.x = clampf(pcam_rotation_degrees.x, min_pitch, max_pitch)
		pcam_rotation_degrees.y -= event.relative.x * mouse_sensitivity
		pcam_rotation_degrees.y = wrapf(pcam_rotation_degrees.y, min_yaw, max_yaw)
		_player_pcam.rotation_degrees = pcam_rotation_degrees
