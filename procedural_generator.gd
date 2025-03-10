extends Node3D

const RoadActor:PackedScene = preload("res://scenes/RoadActor.tscn")

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
@onready var car_label: Label = %debug

@onready var camera_fps: PhantomCamera3D = $RoadManager/vehicles/Player/Camera_FPS
@onready var camera_tp: PhantomCamera3D = %Camera_TP
var is_tp_active: bool = true  # Tracks the current active camera

@export var min_pitch: float = -89.9
@export var max_pitch: float = 50

@export var min_yaw: float = 0
@export var max_yaw: float = 360

@export var mouse_sensitivity: float = 0.05

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_view"):
		toggle_camera()
		
	if is_tp_active:
		return  # No need to process FPS rotation in TP camera mode
	handle_camera_rotation(event)	

func handle_camera_rotation(event: InputEvent):
	if event is InputEventMouseMotion:
		var pcam_rotation_degrees: Vector3

		# Assigns the current 3D rotation of the SpringArm3D node - so it starts off where it is in the editor
		pcam_rotation_degrees = camera_fps.rotation_degrees

		# Change the X rotation
		pcam_rotation_degrees.x -= event.relative.y * mouse_sensitivity

		# Clamp the rotation in the X axis so it go over or under the target
		pcam_rotation_degrees.x = clampf(pcam_rotation_degrees.x, min_pitch, max_pitch)

		# Change the Y rotation value
		pcam_rotation_degrees.y -= event.relative.x * mouse_sensitivity

		# Sets the rotation to fully loop around its target, but witout going below or exceeding 0 and 360 degrees respectively
		pcam_rotation_degrees.y = wrapf(pcam_rotation_degrees.y, min_yaw, max_yaw)

		# Change the SpringArm3D node's rotation and rotate around its target
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
	update_car_count()


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


func spawn_vehicles_on_lane(rp: RoadPoint, dir: int) -> void:
	# Now spawn vehicles
	var new_seg = rp.next_seg if dir == RoadPoint.PointInit.NEXT else rp.prior_seg
	if not is_instance_valid(new_seg):
		print("Invalid new segment")
		return
	var new_lanes = new_seg.get_lanes()
	for _lane in new_lanes:
		# TODO: get random poing along this lane and spawn,
		# for now just placing at the start point
		var new_instance = RoadActor.instantiate()
		vehicles.add_child(new_instance)

		# We could let the agent auto-find the nearest road lane, but to save
		# on some performance we can directly assign BEFORE entering the tree
		# so that it skips the recusive find funciton.
		# Must run after its ready function, but before its physics_process call
		new_instance.agent.current_lane = _lane
		print("new_instance %s " % new_instance)

		var rand_offset = randf() * _lane.curve.get_baked_length()
		var rand_pos = _lane.curve.sample_baked(rand_offset)
		new_instance.global_transform.origin = _lane.to_global(rand_pos)
		_lane.register_vehicle(new_instance)


## Manual way to emvoe all vehicles registered to lanes of this RoadPoint,
## if we didn't use RoadLane.auto_free_vehicles = true
func despawn_cars(road_point:RoadPoint) -> void:
	var lanes:Array = []
	var any_valid := false
	for seg in [road_point.prior_seg, road_point.next_seg]:
		if not is_instance_valid(seg):
			continue
		# Any connected segment is about to be destroyed since this RP is going
		# away, so all adjacent vehicles should all be removed
		lanes.append_array(seg.get_lanes())
		any_valid = true
	if not any_valid:
		print("No segments valid for car despawning")
		return

	for _lane in lanes:
		var this_lane:RoadLane = _lane
		var lane_vehicles = this_lane._vehicles_in_lane #this_lane.get_vehicles()
		for _vehicle in lane_vehicles:
			print("Freeing vehicle ", _vehicle)
			_vehicle.queue_free()


func update_car_count() -> void:
	# For debugging purpses, brute force count the number of cars registered
	# across all RoadLanes; number should match overall car count.
	var _ln_cars = 0
	for _rp in container.get_roadpoints():
		var rp:RoadPoint = _rp
		for seg in [rp.prior_seg, rp.next_seg]:
			if not is_instance_valid(seg):
				continue
			if not seg in rp.get_children():
				continue # avoid double counting
			for lane in seg.get_lanes():
				_ln_cars += len(lane._vehicles_in_lane)

	var car_count: int = len(get_tree().get_nodes_in_group("cars"))
	var rp_count: int = len(container.get_roadpoints())
	var _origin = target.global_transform.origin
	var player_pos: String = "(%s, %s, %s)" % [
		round(_origin.x), round(_origin.y), round(_origin.z)
	]
	car_label.text = "Roadpoints:%s\nCars: %s (lane-registered %s)\nfps: %s\nPlayer at: %s" % [
		rp_count,
		car_count,
		_ln_cars,
		Engine.get_frames_per_second(),
		player_pos]
