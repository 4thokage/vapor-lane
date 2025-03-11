extends Node3D

#const RoadActor:PackedScene = preload("res://scenes/road_actor.tscn")

## How far ahead of the camera will we let a new RoadPoint be added
@export var max_rp_distance: int = 100
## How much buffer around this max dist to avoid adding new RPs
## (this will also define spacing between RoadPoints)
@export var buffer_distance: int = 50

## Node used to calcualte distances
@export var target_node: NodePath

@onready var container: RoadContainer = get_node("RoadManager/Road_001")
@onready var vehicles:Node = get_node("RoadManager/vehicles")
@onready var target: Node = get_node_or_null(target_node)

@onready var camera_fps: PhantomCamera3D = $RoadManager/vehicles/Player/Camera_FPS
@onready var camera_tp: PhantomCamera3D = %Camera_TP
var is_tp_active: bool = true  # Tracks the current active camera
@onready var settings: Control = $Settings

@export var min_pitch: float = -89.9
@export var max_pitch: float = 50

@export var min_yaw: float = 0
@export var max_yaw: float = 360

@export var mouse_sensitivity: float = 0.05
@onready var hud: HUD = %HUD

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_view"):
		toggle_camera()
	if event.is_action_pressed("pause"):
		get_tree().paused = true
		settings.visible = true
		
	if !is_tp_active:
		handle_camera_rotation(event)
	

func handle_camera_rotation(event: InputEvent):
	if event is InputEventMouseMotion:
		var pcam_rotation_degrees: Vector3
		pcam_rotation_degrees = camera_fps.rotation_degrees
		pcam_rotation_degrees.x -= event.relative.y * mouse_sensitivity
		pcam_rotation_degrees.x = clampf(pcam_rotation_degrees.x, min_pitch, max_pitch)
		pcam_rotation_degrees.y -= event.relative.x * mouse_sensitivity
		pcam_rotation_degrees.y = wrapf(pcam_rotation_degrees.y, min_yaw, max_yaw)
		camera_fps.rotation_degrees = pcam_rotation_degrees
		
func toggle_camera() -> void:
	if is_tp_active:
		camera_fps.priority = 10
		camera_tp.priority = 0
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		camera_fps.priority = 0
		camera_tp.priority = 10
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	is_tp_active = !is_tp_active  # Toggle state
	
func _physics_process(_delta: float) -> void:
	update_road()


func xz_target_distance_to(_target: Node3D) -> float:
	var pos_a := Vector2(target.global_transform.origin.x, target.global_transform.origin.z)
	var pos_b := Vector2(_target.global_transform.origin.x, _target.global_transform.origin.z)
	return pos_a.distance_to(pos_b)


## Parent function responsible for processing this road.
func update_road() -> void:

	# Make sure the edges of the Road are all open.
	container.update_edges()
	# TODO: This is overkill as it refreshes all points, in the future we should
	# have the container connection tool handle the responsibility of updating
	# prior/next lane assignments of edge roadPoints so it happens automatically
	container.update_lane_seg_connections()

	if not container.edge_rp_locals:
		print("No edges to add")
		return

	# Iterate over all the RoadPoints with open connections.
	var rp_count:int = container.get_child_count()

	# Cache the initial edges, to avoid referencing export vars on container
	# that get updated as we add new RoadPoints
	var edge_list: Array = container.edge_rp_locals
	var edge_dirs: Array = container.edge_rp_local_dirs

	for _idx in range(len(edge_list)):
		var edge_rp:RoadPoint = container.get_node(edge_list[_idx])
		var dist := xz_target_distance_to(edge_rp)
		# print("Process loop %s with RoadPoint %s with dist %s" % [_idx, edge_rp, dist])
		if dist > max_rp_distance + buffer_distance * 1.5:
			# buffer * factor is to ensure buffer range is wider than the distance between rps,
			# to avoid flicker spawning
			remove_rp(edge_rp)
		elif dist < max_rp_distance:
			var which_edge = edge_dirs[_idx]
			add_next_rp(edge_rp, which_edge)
		elif rp_count > 20:
			pass


## Manually clear prior/next points to ensure it gets fully disconnected
func remove_rp(edge_rp: RoadPoint) -> void:
	# No need to manually remove cars, as we use the default: RoadLane.auto_free_vehicles=true
	#despawn_cars(edge_rp)
	edge_rp.prior_pt_init = ""
	edge_rp.next_pt_init = ""
	# Defer to allow time to free cars first, if using despawn_cars above
	edge_rp.call_deferred("queue_free")


## Add a new roadpoint in a given direction
func add_next_rp(rp: RoadPoint, dir: int) -> void:
	var mag = 1 if dir == RoadPoint.PointInit.NEXT else -1
	var flip_dir: int = RoadPoint.PointInit.NEXT if dir == RoadPoint.PointInit.PRIOR else RoadPoint.PointInit.PRIOR

	var new_rp := RoadPoint.new()
	container.add_child(new_rp)

	# Copy initial things like lane counts and orientation
	new_rp.copy_settings_from(rp, true)

	# Placement of a new roadpoint with interval no larger than buffer,
	# to avoid flicker removal/adding with the culling system

	# Randomly rotate the offset vector slightly
	randomize()
	var _transform := new_rp.transform
	var angle_range := 30 # Random angle rotation range
	var random_angle: float = randf_range(-angle_range / 2.0, angle_range / 2.0) # Generate a random angle within the range
	var rotation_axis := Vector3(0, 1, 0)
	_transform = _transform.rotated(rotation_axis, deg_to_rad(random_angle))
	
	var rand_y_offset:float = (randf() - 0.5) * 2.5
	var offset_pos:Vector3 = _transform.basis.z * buffer_distance * mag + Vector3.UP * rand_y_offset

	new_rp.transform.origin += offset_pos

	# Finally, connect them together
	var res = rp.connect_roadpoint(dir, new_rp, flip_dir)
	if res != true:
		print("Failed to connect RoadPoint")
		return
	#spawn_vehicles_on_lane(rp, dir)
