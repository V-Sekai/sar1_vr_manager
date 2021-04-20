extends Reference
tool


func get_platform_name() -> String:
	return "Empty Platform"


func create_render_tree() -> Spatial:
	return Spatial.new()


func add_controller(_controller: ARVRController, _origin: ARVROrigin) -> void:
	pass


func remove_controller(_controller: ARVRController, _origin: ARVROrigin) -> void:
	pass


func pre_setup() -> void:
	pass


func setup() -> void:
	pass
