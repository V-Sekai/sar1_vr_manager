extends "vr_action.gd"

const LASER_THICKNESS = 0.001
const LASER_HIT_SIZE = 0.01

const UI_COLLISION_LAYER = 0x02

const line_renderer_const = preload("res://addons/line_renderer/line_renderer.gd")
var is_active_selector: bool = false
var valid_ray_result: Dictionary = {}

export (float) var maxiumum_ray_length: float = 10.0

var laser_node: Spatial = null
var laser_hit_node: MeshInstance = null

signal requested_as_ui_selector(p_hand)


func _on_action_pressed(p_action: String) -> void:
	._on_action_pressed(p_action)
	match p_action:
		"/menu/menu_interaction":
			emit_signal("requested_as_ui_selector", tracker.get_hand())
			if valid_ray_result and is_active_selector:
				if valid_ray_result["collider"].has_method("on_pointer_pressed"):
					valid_ray_result["collider"].on_pointer_pressed(valid_ray_result["position"])


func _on_action_released(p_action: String) -> void:
	._on_action_released(p_action)
	match p_action:
		"/menu/menu_interaction":
			if valid_ray_result and is_active_selector:
				if valid_ray_result["collider"].has_method("on_pointer_release"):
					valid_ray_result["collider"].on_pointer_release(valid_ray_result["position"])


func activate_ui_selector() -> void:
	is_active_selector = true


func deactivate_ui_selector() -> void:
	is_active_selector = false


func create_nodes() -> void:
	laser_node = line_renderer_const.new()
	laser_node.name = "Laser"
	laser_node.material = VRManager.get_laser_material()
	laser_node.thickness = LASER_THICKNESS
	laser_node.start = Vector3(0.0, 0.0, 0.0)
	laser_node.end = Vector3(0.0, 0.0, -1.0) * maxiumum_ray_length

	var laser_hit_mesh: SphereMesh = SphereMesh.new()
	laser_hit_mesh.radius *= LASER_HIT_SIZE
	laser_hit_mesh.height *= LASER_HIT_SIZE
	laser_hit_mesh.material = VRManager.get_laser_material()

	laser_hit_node = MeshInstance.new()
	laser_hit_node.name = "LaserHit"
	laser_hit_node.mesh = laser_hit_mesh


func _ready() -> void:
	create_nodes()

	assert(tracker.laser_origin)
	tracker.laser_origin.add_child(laser_node)
	tracker.laser_origin.add_child(laser_hit_node)

	laser_node.hide()
	laser_hit_node.hide()


func cast_validation_ray(p_length: float) -> Dictionary:
	var dss: PhysicsDirectSpaceState = PhysicsServer.space_get_direct_state(get_world().get_space())
	if ! dss:
		return {}

	var start: Vector3 = laser_node.global_transform.origin
	var end: Vector3 = (
		laser_node.global_transform.origin
		+ laser_node.global_transform.basis.xform(Vector3(0.0, 0.0, -p_length))
	)

	var ray_result: Dictionary = dss.intersect_ray(start, end, [], UI_COLLISION_LAYER, false, true)

	laser_hit_node.global_transform = Transform(global_transform.basis, end)

	if ray_result:
		if ray_result["collider"].has_method("validate_pointer"):
			if ray_result["collider"].validate_pointer(ray_result["normal"]):
				laser_node.start = start
				laser_node.end = ray_result["position"]

				laser_hit_node.global_transform = Transform(
					global_transform.basis, ray_result["position"]
				)

				return ray_result

	return {}


func update_ray() -> void:
	if is_active_selector:
		valid_ray_result = cast_validation_ray(maxiumum_ray_length)
		if ! valid_ray_result.empty() and is_active_selector:
			if valid_ray_result["collider"].has_method("on_pointer_moved"):
				valid_ray_result["collider"].on_pointer_moved(
					valid_ray_result["position"], valid_ray_result["normal"]
				)
			laser_node.show()
			laser_hit_node.show()
			return

	laser_node.hide()
	laser_hit_node.hide()


func _process(_delta: float) -> void:
	update_ray()
