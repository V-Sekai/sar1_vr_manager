extends Spatial

const vr_controller_tracker_const = preload("res://addons/sar1_vr_manager/vr_controller_tracker.gd")

signal trackers_changed

var head_tracker_module: Spatial = null

var hand_controllers: Array = []
var left_hand_controller: ARVRController = null
var right_hand_controller: ARVRController = null

func tracker_added(p_tracker: vr_controller_tracker_const) -> void:
	var tracker_hand: int = p_tracker.get_hand()
	match tracker_hand:
		ARVRPositionalTracker.TRACKER_LEFT_HAND:
			# Attempt to add left controller
			if left_hand_controller == null:
				left_hand_controller = p_tracker
				hand_controllers.push_back(p_tracker)
		ARVRPositionalTracker.TRACKER_RIGHT_HAND:
			if right_hand_controller == null:
				right_hand_controller = p_tracker
				hand_controllers.push_back(p_tracker)
		_:
			pass
			
	emit_signal("trackers_changed")

func tracker_removed(p_tracker: vr_controller_tracker_const) -> void:
	var index: int = hand_controllers.find(p_tracker)
	if index != -1:
		hand_controllers.remove(index)
		
	if left_hand_controller == p_tracker:
		left_hand_controller = null

	if right_hand_controller == p_tracker:
		right_hand_controller = null
		
	emit_signal("trackers_changed")
		
func post_add_setup() -> void:
	pass
	
func _enter_tree():
	set_name("VRComponent")
