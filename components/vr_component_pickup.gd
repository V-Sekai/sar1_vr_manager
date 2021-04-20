extends "vr_component.gd"

const vr_pickup_action = preload("actions/vr_pickup_action.gd")

func tracker_added(p_tracker: vr_controller_tracker_const) -> void:
	.tracker_added(p_tracker)

func tracker_removed(p_tracker: vr_controller_tracker_const) -> void:
	.tracker_removed(p_tracker)

func _enter_tree():
	set_name("PickupComponent")
