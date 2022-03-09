extends XRController3D

var vr_module: Node = null

var vr_tracker_script = null


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

	print("vr_action.gd TRACKER " + str(get_path))
	if connect("button_pressed", Callable(self, "_on_action_pressed")) != OK:
		printerr("action_pressed not connected!")
	if connect("button_released", Callable(self, "_on_action_released")) != OK:
		printerr("action_released not connected!")
