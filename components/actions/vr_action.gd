extends Node3D

var vr_module: Node = null

var vr_tracker_script = null
var tracker: XRController3D = null


func is_pressed(p_action: String) -> bool:
	return tracker.is_pressed(p_action)


func get_analog(p_action: String) -> Vector2:
	return tracker.get_analog(p_action)


func _on_action_pressed(_action: String) -> void:
	pass


func _on_action_released(_action: String) -> void:
	pass


func find_parent_controller() -> Node:
	var node = self
	while node.get_script() != vr_tracker_script:
		if node == null:
			break
		node = node.get_parent()

	return node


func _ready() -> void:
	vr_tracker_script = load("res://addons/sar1_vr_manager/vr_controller_tracker.gd")

	tracker = find_parent_controller()
	if tracker:
		if tracker.connect("action_pressed", Callable(self, "_on_action_pressed")) != OK:
			printerr("action_pressed not connected!")
		if tracker.connect("action_released", Callable(self, "_on_action_released")) != OK:
			printerr("action_released not connected!")
