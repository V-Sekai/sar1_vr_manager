extends "res://addons/sar1_vr_manager/components/vr_component.gd" # vr_component.gd

const vr_ui_pointer_action_const = preload("actions/vr_ui_pointer_action.gd")

var left_ui_pointer_action: Node3D = null
var right_ui_pointer_action: Node3D = null

func select_primary_hand() -> void:
	for child in get_children():
		if child is vr_controller_tracker_const:
			_on_requested_as_ui_selector(child)
			# Make the right-hand the default selector
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

func tracker_added(p_tracker: XRController3D) -> void: # vr_controller_tracker_const
	super.tracker_added(p_tracker)
	
	var tracker_hand: int = p_tracker.get_hand()
	if tracker_hand == XRPositionalTracker.TRACKER_HAND_LEFT or\
	tracker_hand == XRPositionalTracker.TRACKER_HAND_RIGHT:
		var vr_ui_pointer_action: Node3D = vr_ui_pointer_action_const.new()
		assert(vr_ui_pointer_action.connect("requested_as_ui_selector", self._requested_as_ui_selector) == OK)
		p_tracker.add_component_action(vr_ui_pointer_action)
		match tracker_hand:
			XRPositionalTracker.TRACKER_HAND_LEFT:
				assert(!is_instance_valid(left_ui_pointer_action))
				left_ui_pointer_action = vr_ui_pointer_action
			XRPositionalTracker.TRACKER_HAND_RIGHT:
				assert(!is_instance_valid(right_ui_pointer_action))
				right_ui_pointer_action = vr_ui_pointer_action

func tracker_removed(p_tracker: XRController3D) -> void: # vr_controller_tracker_const
	super.tracker_removed(p_tracker)
	
	match p_tracker.get_hand():
		XRPositionalTracker.TRACKER_HAND_LEFT:
			p_tracker.remove_component_action(left_ui_pointer_action)
			left_ui_pointer_action = null
		XRPositionalTracker.TRACKER_HAND_RIGHT:
			p_tracker.remove_component_action(right_ui_pointer_action)
			right_ui_pointer_action = null

func post_add_setup() -> void:
	super.post_add_setup()
	select_primary_hand()
	
func _enter_tree():
	set_name("UIPointerComponent")
