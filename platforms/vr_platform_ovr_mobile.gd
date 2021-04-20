extends "vr_platform.gd"
tool


func get_platform_name() -> String:
	return "OVRMobile"


func create_render_tree() -> Spatial:
	var render_tree: Spatial = Spatial.new()

	var mesh_instance: MeshInstance = MeshInstance.new()
	render_tree.add_child(mesh_instance)

	var sphere_mesh: SphereMesh = SphereMesh.new()
	sphere_mesh.radius = 0.1
	sphere_mesh.height = 0.2

	mesh_instance.mesh = sphere_mesh

	return render_tree
