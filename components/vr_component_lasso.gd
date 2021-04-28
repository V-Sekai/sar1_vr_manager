extends "vr_component.gd"

# This will be added to the root of VR_origin. It is responsible for assigning
# the lasso action to the controllers

const vr_lasso_action_const = preload("actions/vr_lasso_action.tscn")
# const snapping_point = preload("lasso_snapping/snapping_point.gd")

var left_lasso_action: Spatial = null
var right_lasso_action: Spatial = null


func tracker_added(p_tracker: vr_controller_tracker_const) -> void:
	.tracker_added(p_tracker)
	
	var tracker_hand: int = p_tracker.get_hand()
	if tracker_hand == ARVRPositionalTracker.TRACKER_LEFT_HAND or\
	tracker_hand == ARVRPositionalTracker.TRACKER_RIGHT_HAND:
		var vr_lasso_action: Spatial = vr_lasso_action_const.instance()
		vr_lasso_action.flick_origin_spatial = self
		p_tracker.add_component_action(vr_lasso_action)
		match tracker_hand:
			ARVRPositionalTracker.TRACKER_LEFT_HAND:
				assert(!is_instance_valid(left_lasso_action))
				left_lasso_action = vr_lasso_action
			ARVRPositionalTracker.TRACKER_RIGHT_HAND:
				assert(!is_instance_valid(right_lasso_action))
				right_lasso_action = vr_lasso_action
				
func tracker_removed(p_tracker: vr_controller_tracker_const) -> void:
	.tracker_removed(p_tracker)
	
	match p_tracker.get_hand():
		ARVRPositionalTracker.TRACKER_LEFT_HAND:
			p_tracker.remove_component_action(left_lasso_action)
			left_lasso_action = null
		ARVRPositionalTracker.TRACKER_RIGHT_HAND:
			p_tracker.remove_component_action(right_lasso_action)
			right_lasso_action = null

func post_add_setup() -> void:
	.post_add_setup()
	
func _enter_tree() -> void:
	set_name("LassoComponent")
	
