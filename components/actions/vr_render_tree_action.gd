extends "vr_action.gd"

var render_tree: Spatial = null

func set_render_tree(p_render_tree) -> void:
	render_tree = p_render_tree


func _process(_delta: float) -> void:
	if render_tree:
		render_tree.update_render_tree()

func _update_scale(p_scale) -> void:
	if render_tree:
		render_tree.set_scale(Vector3(p_scale, p_scale, p_scale))

func _ready() -> void:
	assert(tracker.model_origin)
	tracker.model_origin.add_child(render_tree)
	
	if VRManager.xr_origin:
		_update_scale(VRManager.xr_origin.get_world_scale())
	
	if VRManager.connect("world_origin_scale_changed", self, "_update_scale") != OK:
		printerr("Could not connect world_origin_scale_changed")
