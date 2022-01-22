@tool
extends "res://addons/sar1_vr_manager/platforms/vr_platform.gd" # vr_platform.gd


func get_platform_name() -> String:
	return "OVRMobile"


func create_render_tree() -> Node3D:
	var render_tree: Node3D = Node3D.new()

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	render_tree.add_child(mesh_instance, true)

	var sphere_mesh: SphereMesh = SphereMesh.new()
	sphere_mesh.radius = 0.1
	sphere_mesh.height = 0.2

	mesh_instance.mesh = sphere_mesh

	return render_tree
