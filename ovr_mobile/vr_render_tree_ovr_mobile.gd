extends "res://addons/vr_manager/vr_render_tree.gd"

var ovr_component_tree: NativeScript = null
var ovr_render_model: NativeScript = null

var tree: Spatial = null


func setup_openvr_dummy_attachment(p_name: String) -> Spatial:
	var spatial: Spatial = create_attachment_point(p_name)
	spatial.translate(Vector3(0.0, -0.01, 0.05))
	spatial.rotate_x(deg2rad(-45))

	return spatial


func load_render_tree(p_name: String) -> bool:
	var result: bool = false
	var controller_name: String = p_name.substr(0, p_name.length() - 2)

	if tree:
		tree.queue_free()
		tree.get_parent().remove_child(tree)
		tree = null

	if ovr_component_tree:
		tree = ovr_component_tree.new()
		result = tree.load_tree(controller_name)
		if ! result:
			result = tree.load_tree("generic_controller")
	else:
		if ovr_render_model:
			tree = Spatial.new()

			var mesh_instance: MeshInstance = MeshInstance.new()
			mesh_instance.set_name("mesh")
			tree.add_child(mesh_instance)

			var render_mesh: Mesh = null
			var render_cache = null  #VRManager.get_render_cache()

			if render_cache:
				render_mesh = render_cache.get_render_mesh(controller_name)

			if render_mesh == null:
				render_mesh = ovr_render_model.new()
				render_mesh.load_model(controller_name)
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


func get_attachment_point(p_name: String) -> Spatial:
	if tree:
		if tree.has_node(p_name):
			var render_mesh_instance = tree.get_node(p_name)
			if render_mesh_instance.has_node("attach"):
				return render_mesh_instance.get_node("attach")

	return null


func update_render_tree() -> void:
	if tree and tree.has_method("update_tree"):
		tree.update_tree()


func _init() -> void:
	##################
	# Component Tree #
	##################
	if ResourceLoader.exists("res://addons/godot-openvr/OpenVRComponentTree.gdns"):
		ovr_component_tree = (
			ResourceLoader.load("res://addons/godot-openvr/OpenVRComponentTree.gdns") as NativeScript
		)

	################
	# Render Model #
	################
	if ResourceLoader.exists("res://addons/godot-openvr/OpenVRRenderModel.gdns"):
		ovr_render_model = (
			ResourceLoader.load("res://addons/godot-openvr/OpenVRRenderModel.gdns") as NativeScript
		)
