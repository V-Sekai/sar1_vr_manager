@tool
extends RefCounted


func get_platform_name() -> String:
	return "Empty Platform"


func create_render_tree() -> Node3D:
	return Node3D.new()


func add_controller(_controller: XRController3D, _origin: XROrigin3D) -> void:
	pass


func remove_controller(_controller: XRController3D, _origin: XROrigin3D) -> void:
	pass


func pre_setup() -> void:
	pass


func setup() -> void:
	pass
