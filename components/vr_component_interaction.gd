extends "res://addons/sar1_vr_manager/components/vr_component.gd" # vr_component.gd

const vr_pickup_action_const = preload("actions/vr_interaction_action.gd")

var assign_left_pickup_funcref
var assign_right_pickup_funcref

var can_pickup_funcref

func _can_pickup(p_body: PhysicsBody3D) -> bool:
	if can_pickup_funcref.is_valid():
		return can_pickup_funcref.call(p_body)
	else:
		return false
		
func _assign_left_pickup(p_body: PhysicsBody3D) -> bool:
	if assign_left_pickup_funcref.is_valid():
		return assign_left_pickup_funcref.call(p_body)
	else:
		return false
		
func _assign_right_pickup(p_body: PhysicsBody3D) -> bool:
	if assign_right_pickup_funcref.is_valid():
		return assign_right_pickup_funcref.call(p_body)
	else:
		return false

func tracker_added(p_tracker: XRController3D) -> void: # vr_controller_tracker_const
	super.tracker_added(p_tracker)
	
	var tracker_hand: int = p_tracker.get_hand()
	if tracker_hand == XRPositionalTracker.TRACKER_HAND_LEFT or\
	tracker_hand == XRPositionalTracker.TRACKER_HAND_RIGHT_HAND:
		var action: Node3D = vr_pickup_action_const.instantiate()
		
		### Assign callsbacks ###
		action.can_pickup_funcref = Callable(self, "_can_pickup")
		
		if tracker_hand == XRPositionalTracker.TRACKER_HAND_LEFT:
			action.assign_pickup(self, "_assign_left_pickup")
		else:
			action.assign_pickup(self, "_assign_right_pickup")
		###
		
		p_tracker.add_component_action(action)
		

func tracker_removed(p_tracker: XRController3D) -> void: # vr_controller_tracker_const
	super.tracker_removed(p_tracker)

func _enter_tree():
	set_name("InteractionComponent")
