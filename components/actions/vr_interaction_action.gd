extends "vr_action.gd"

const math_funcs_const = preload("res://addons/math_util/math_funcs.gd")

var objects_within_range: Array = []

var assign_pickup_funcref:FuncRef = FuncRef.new()
var can_pickup_funcref:FuncRef = FuncRef.new()

var last_position: Vector3 = Vector3(0.0, 0.0, 0.0)
var velocity: Vector3 = Vector3(0.0, 0.0, 0.0)

static func get_hand_object_id_for_tracker_controller(
	p_player_pickup_controller: Node, p_tracker_controller: ARVRController
):
	if p_player_pickup_controller:
		match p_tracker_controller.get_hand():
			ARVRPositionalTracker.TRACKER_LEFT_HAND:
				return p_player_pickup_controller.LEFT_HAND_ID
			ARVRPositionalTracker.TRACKER_RIGHT_HAND:
				return p_player_pickup_controller.RIGHT_HAND_ID
			_:
				return -1


func get_pickup_controller() -> Node:
	if VSKNetworkManager.local_player_instance:
		return VSKNetworkManager.local_player_instance.simulation_logic_node.get_player_pickup_controller()
	else:
		return null


func get_hand_object() -> Spatial:
	var pickup_controller: Node = get_pickup_controller()
	if pickup_controller:
		var id: int = get_hand_object_id_for_tracker_controller(pickup_controller, tracker)
		return pickup_controller.get_hand_entity_reference(id)

	return null


		
func _on_interaction_body_entered(p_body: Node):
	if p_body.has_method("pick_up"):
		var index: int = objects_within_range.find(p_body)
		if index == -1:
			objects_within_range.push_back(p_body)
		else:
			printerr("Duplicate object {body_name}".format({"body_name": p_body.name}))


func _on_interaction_body_exited(p_body: Node):
	var index: int = objects_within_range.find(p_body)
	if index != -1:
		objects_within_range.remove(index)


func get_nearest_valid_object() -> Spatial:
	return null


func try_to_picking_up_object() -> void:
	return


func try_to_dropping_object() -> void:
	return


func _on_action_pressed(p_action: String) -> void:
	._on_action_pressed(p_action)

	match p_action:
		"/hands/grip":
			try_to_picking_up_object()


func _on_action_released(p_action: String) -> void:
	._on_action_released(p_action)

	match p_action:
		"/hands/grip":
			try_to_dropping_object()


func calculate_velocity(p_delta: float) -> void:
	velocity = (tracker.transform.origin - last_position) / p_delta
	last_position = tracker.transform.origin


func _process(p_delta: float) -> void:
	calculate_velocity(p_delta)
