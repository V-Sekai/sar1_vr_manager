extends "vr_component.gd"

const vr_teleport_action_const = preload("actions/vr_teleport_action.tscn")

var can_teleport_funcref:FuncRef = FuncRef.new()
var teleport_callback_funcref:FuncRef = FuncRef.new()

func _teleported(p_transform: Transform) -> void:
	if teleport_callback_funcref.is_valid():
		teleport_callback_funcref.call_func(p_transform) 

func _can_teleport() -> bool:
	if can_teleport_funcref.is_valid():
		return can_teleport_funcref.call_func() 
		
	return false

func tracker_added(p_tracker: vr_controller_tracker_const) -> void:
	.tracker_added(p_tracker)
	
	var tracker_hand: int = p_tracker.get_hand()
	if tracker_hand == ARVRPositionalTracker.TRACKER_LEFT_HAND or\
	tracker_hand == ARVRPositionalTracker.TRACKER_RIGHT_HAND:
		var action: Spatial = vr_teleport_action_const.instance()
		
		### Assign callsbacks ###
		action.set_can_teleport_funcref(self, "_can_teleport")
		if action.connect("teleported", self, "_teleported") != OK:
			printerr("Could not connect teleported signal!")
		###
		
		p_tracker.add_component_action(action)

func tracker_removed(p_tracker: vr_controller_tracker_const) -> void:
	.tracker_removed(p_tracker)
	
func assign_teleport_callback_funcref(p_instance: Object, p_function: String) -> void:
	teleport_callback_funcref = funcref(p_instance, p_function)
	
func assign_can_teleport_funcref(p_instance: Object, p_function: String) -> void:
	can_teleport_funcref = funcref(p_instance, p_function)

func _enter_tree():
	set_name("TeleportComponent")
