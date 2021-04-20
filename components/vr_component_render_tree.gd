extends "vr_component.gd"

const vr_render_tree_const = preload("../vr_render_tree.gd")
const vr_render_tree_action_const = preload("actions/vr_render_tree_action.gd")

var left_render_tree_action: Spatial = null
var right_render_tree_action: Spatial = null

func tracker_added(p_tracker: vr_controller_tracker_const) -> void:
	.tracker_added(p_tracker)
	
	var tracker_hand: int = p_tracker.get_hand()
	if tracker_hand == ARVRPositionalTracker.TRACKER_LEFT_HAND or\
	tracker_hand == ARVRPositionalTracker.TRACKER_RIGHT_HAND:
		var vr_render_tree_action: Spatial = vr_render_tree_action_const.new()
		
		# instance our render model object
		var spatial_render_tree: Spatial = VRManager.create_render_tree()
		# hide to begin with
		vr_render_tree_action.visible = false
		
		var controller_name: String = p_tracker.get_controller_name()
		if ! spatial_render_tree.load_render_tree(controller_name):
			printerr("Could not load render tree")
		
		vr_render_tree_action.visible = true
		
		vr_render_tree_action.set_render_tree(spatial_render_tree)
		p_tracker.add_component_action(vr_render_tree_action)
		
		match tracker_hand:
			ARVRPositionalTracker.TRACKER_LEFT_HAND:
				assert(! left_render_tree_action)
				left_render_tree_action = vr_render_tree_action
			ARVRPositionalTracker.TRACKER_RIGHT_HAND:
				assert(! right_render_tree_action)
				right_render_tree_action = vr_render_tree_action

func tracker_removed(p_tracker: vr_controller_tracker_const) -> void:
	match p_tracker.get_hand():
		ARVRPositionalTracker.TRACKER_LEFT_HAND:
			p_tracker.remove_module_tracker(left_render_tree_action)
			left_render_tree_action = null
		ARVRPositionalTracker.TRACKER_RIGHT_HAND:
			p_tracker.remove_module_tracker(right_render_tree_action)
			right_render_tree_action = null

func _enter_tree():
	set_name("RenderTreeComponent")
