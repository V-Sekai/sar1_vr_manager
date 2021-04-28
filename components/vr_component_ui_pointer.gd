extends "vr_component.gd"

const vr_ui_pointer_action_const = preload("actions/vr_ui_pointer_action.gd")

var left_ui_pointer_action: Spatial = null
var right_ui_pointer_action: Spatial = null

func select_primary_hand() -> void:
	for child in get_children():
		if child is vr_controller_tracker_const:
			_on_requested_as_ui_selector(child)
			# Make the right-hand the default selector
			if child.controller_id == ARVRPositionalTracker.TRACKER_RIGHT_HAND:
				break

func _on_requested_as_ui_selector(p_node: Node) -> void:
	for child in get_children():
		if child is vr_controller_tracker_const:
			child.deactivate_ui_selector()

	p_node.activate_ui_selector()

func _requested_as_ui_selector(p_hand: int) -> void:
	match p_hand:
		ARVRPositionalTracker.TRACKER_LEFT_HAND:
			if left_ui_pointer_action:
				_on_requested_as_ui_selector(left_ui_pointer_action)
		ARVRPositionalTracker.TRACKER_RIGHT_HAND:
			if right_ui_pointer_action:
				_on_requested_as_ui_selector(right_ui_pointer_action)

func tracker_added(p_tracker: vr_controller_tracker_const) -> void:
	.tracker_added(p_tracker)
	
	var tracker_hand: int = p_tracker.get_hand()
	if tracker_hand == ARVRPositionalTracker.TRACKER_LEFT_HAND or\
	tracker_hand == ARVRPositionalTracker.TRACKER_RIGHT_HAND:
		var vr_ui_pointer_action: Spatial = vr_ui_pointer_action_const.new()
		assert(vr_ui_pointer_action.connect("requested_as_ui_selector", self, "_requested_as_ui_selector") == OK)
		p_tracker.add_component_action(vr_ui_pointer_action)
		match tracker_hand:
			ARVRPositionalTracker.TRACKER_LEFT_HAND:
				assert(!is_instance_valid(left_ui_pointer_action))
				left_ui_pointer_action = vr_ui_pointer_action
			ARVRPositionalTracker.TRACKER_RIGHT_HAND:
				assert(!is_instance_valid(right_ui_pointer_action))
				right_ui_pointer_action = vr_ui_pointer_action

func tracker_removed(p_tracker: vr_controller_tracker_const) -> void:
	.tracker_removed(p_tracker)
	
	match p_tracker.get_hand():
		ARVRPositionalTracker.TRACKER_LEFT_HAND:
			p_tracker.remove_component_action(left_ui_pointer_action)
			left_ui_pointer_action = null
		ARVRPositionalTracker.TRACKER_RIGHT_HAND:
			p_tracker.remove_component_action(right_ui_pointer_action)
			right_ui_pointer_action = null

func post_add_setup() -> void:
	.post_add_setup()
	select_primary_hand()
	
func _enter_tree():
	set_name("UIPointerComponent")
