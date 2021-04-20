extends "vr_component.gd"

const vr_advanced_movement_action = preload("actions/vr_advanced_movement_action.gd")

func _jump_pressed() -> void:
	var a: InputEventAction = InputEventAction.new()
	a.action = "jump"
	a.pressed = true 
	Input.parse_input_event(a)
	
func _jump_released() -> void:
	var a: InputEventAction = InputEventAction.new()
	a.action = "jump"
	a.pressed = false 
	Input.parse_input_event(a)
	
func tracker_added(p_tracker: vr_controller_tracker_const) -> void:
	.tracker_added(p_tracker)
	
	var tracker_hand: int = p_tracker.get_hand()
	if tracker_hand == ARVRPositionalTracker.TRACKER_LEFT_HAND or\
	tracker_hand == ARVRPositionalTracker.TRACKER_RIGHT_HAND:
		var action: Spatial = vr_advanced_movement_action.new()
		
		# Assign calls backs
		if action.connect("jump_pressed", self, "_jump_pressed") != OK:
			printerr("Could not connect jump_pressed signal!")
		if action.connect("jump_released", self, "_jump_released") != OK:
			printerr("Could not connect jump_released signal!")
		###
		
		p_tracker.add_component_action(action)

func post_add_setup() -> void:
	.post_add_setup()
	
func _enter_tree():
	set_name("AdvancedMovementComponent")
