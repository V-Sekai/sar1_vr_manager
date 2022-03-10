extends "res://addons/sar1_vr_manager/vr_render_tree.gd"

var tree: Node3D = null


func setup_openvr_dummy_attachment(p_name: StringName) -> Node3D:
	var spatial: Node3D = create_attachment_point(p_name)
	spatial.translate(Vector3(0.0, -0.01, 0.05))
	spatial.rotate_x(deg2rad(-45))

	return spatial


func load_render_tree(p_vrmanager: Node, p_name: String) -> bool:
	var result: bool = false
	var controller_name: String = p_name.substr(0, p_name.length() - 2)

	if tree:
		tree.queue_free()
		tree.get_parent().remove_child(tree)
		tree = null

	tree = Node3D.new()

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.set_name("mesh")
	tree.add_child(mesh_instance)

	var render_mesh: Mesh = null
	var render_cache = p_vrmanager.get_render_cache()

	if render_cache:
		render_mesh = render_cache.get_render_mesh(controller_name)

	if render_mesh == null:
		# TODO: There is currently no OpenXR api for accessing the render model.
		# So we have a cylinder as a placeholder instead.
		render_mesh = CylinderMesh.new() # openvr_render_model.new()
		render_mesh.top_radius = 0.05
		render_mesh.height = 0.05
		# render_mesh.load_model(controller_name)
		render_mesh.set_name(controller_name)
		if render_cache:
			render_cache.add_render_mesh(controller_name, render_mesh)

	if render_mesh != null:
		mesh_instance.set_mesh(render_mesh)

	# Create dummy attachments
	tree.add_child(setup_openvr_dummy_attachment("base"))
	tree.add_child(setup_openvr_dummy_attachment("handgrip"))
	tree.add_child(setup_openvr_dummy_attachment("tip"))

	result = true
	if tree:
		tree.set_name("RenderTree")
		add_child(tree)

	return result


func get_attachment_point(p_name: StringName) -> Node3D:
	if tree:
		if tree.has_node(NodePath(p_name)):
			var render_mesh_instance = tree.get_node(NodePath(p_name))
			if render_mesh_instance.has_node("attach"):
				return render_mesh_instance.get_node("attach")

	return null


func update_render_tree() -> void:
	if tree and tree.has_method("update_tree"):
		tree.update_tree()


func _init() -> void:
	pass