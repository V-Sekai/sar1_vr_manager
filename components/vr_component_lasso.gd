extends "res://addons/sar1_vr_manager/components/vr_component.gd"

# This will be added to the root of VR_origin. It is responsible for assigning
# the lasso action to the controllers

var vr_lasso_action_const = load("res://addons/sar1_vr_manager/components/actions/vr_lasso_action.tscn")

var left_lasso_action: Node3D = null
var right_lasso_action: Node3D = null

const vr_ui_pointer_action_const = preload("actions/vr_ui_pointer_action.gd")

var left_ui_pointer_action: Node3D = null
var right_ui_pointer_action: Node3D = null


func select_primary_hand() -> void:
	for child in get_children():
		if child is vr_controller_tracker_const:
			_on_requested_as_ui_selector(child)
			# Make the right-hand the default selector.
			if child.controller_id == XRPositionalTracker.TRACKER_HAND_RIGHT:
				break


func _on_requested_as_ui_selector(p_node: Node) -> void:
	for child in get_children():
		if child is vr_controller_tracker_const:
			child.deactivate_ui_selector()
	p_node.activate_ui_selector()


func _requested_as_ui_selector(p_hand: int) -> void:
	match p_hand:
		XRPositionalTracker.TRACKER_HAND_LEFT:
			if left_ui_pointer_action:
				_on_requested_as_ui_selector(left_ui_pointer_action)
		XRPositionalTracker.TRACKER_HAND_RIGHT:
			if right_ui_pointer_action:
				_on_requested_as_ui_selector(right_ui_pointer_action)


func tracker_added(p_tracker: XRController3D) -> void:
	super.tracker_added(p_tracker)

	var tracker_hand: int = p_tracker.get_tracker_hand()
	# TODO: fire 2022-12-18 restore picking the other hand. 
	if tracker_hand == XRPositionalTracker.TRACKER_HAND_RIGHT:
		var vr_lasso_action: Node3D = vr_lasso_action_const.instantiate()
		vr_lasso_action.flick_origin_spatial = self
		p_tracker.add_component_action(vr_lasso_action)
		var vr_ui_pointer_action: Node3D = vr_ui_pointer_action_const.new()
		vr_ui_pointer_action.requested_as_ui_selector.connect(self._requested_as_ui_selector)


func tracker_removed(p_tracker: XRController3D) -> void:
	super.tracker_removed(p_tracker)

	match p_tracker.get_tracker_hand():
		XRPositionalTracker.TRACKER_HAND_LEFT:
			p_tracker.remove_component_action(left_lasso_action)
			left_lasso_action = null
			p_tracker.remove_component_action(left_ui_pointer_action)
			left_ui_pointer_action = null
		XRPositionalTracker.TRACKER_HAND_RIGHT:
			p_tracker.remove_component_action(right_lasso_action)
			right_lasso_action = null
			p_tracker.remove_component_action(right_ui_pointer_action)
			right_ui_pointer_action = null


func post_add_setup() -> void:
	super.post_add_setup()
	select_primary_hand()


func _enter_tree() -> void:
	set_name("LassoComponent")
