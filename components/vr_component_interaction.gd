extends "vr_component.gd"

const vr_pickup_action_const = preload("actions/vr_interaction_action.gd")

var assign_left_pickup_funcref:FuncRef = FuncRef.new()
var assign_right_pickup_funcref:FuncRef = FuncRef.new()

var can_pickup_funcref:FuncRef = FuncRef.new()

func _can_pickup(p_body: PhysicsBody) -> bool:
	if can_pickup_funcref.is_valid():
		return can_pickup_funcref.call_func(p_body)
	else:
		return false
		
func _assign_left_pickup(p_body: PhysicsBody) -> bool:
	if assign_left_pickup_funcref.is_valid():
		return assign_left_pickup_funcref.call_func(p_body)
	else:
		return false
		
func _assign_right_pickup(p_body: PhysicsBody) -> bool:
	if assign_right_pickup_funcref.is_valid():
		return assign_right_pickup_funcref.call_func(p_body)
	else:
		return false

func tracker_added(p_tracker: vr_controller_tracker_const) -> void:
	.tracker_added(p_tracker)
	
	var tracker_hand: int = p_tracker.get_hand()
	if tracker_hand == ARVRPositionalTracker.TRACKER_LEFT_HAND or\
	tracker_hand == ARVRPositionalTracker.TRACKER_RIGHT_HAND:
		var action: Spatial = vr_pickup_action_const.instance()
		
		### Assign callsbacks ###
		action.can_pickup_funcref = funcref(self, "_can_pickup")
		
		if tracker_hand == ARVRPositionalTracker.TRACKER_LEFT_HAND:
			action.assign_pickup(self, "_assign_left_pickup")
		else:
			action.assign_pickup(self, "_assign_right_pickup")
		###
		
		p_tracker.add_component_action(action)
		

func tracker_removed(p_tracker: vr_controller_tracker_const) -> void:
	.tracker_removed(p_tracker)

func _enter_tree():
	set_name("InteractionComponent")
