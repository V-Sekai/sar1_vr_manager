extends "vr_component.gd"


const vr_hand_pose_action_const = preload("actions/vr_hand_pose_action.gd")

var left_hand_pose_action: Spatial = null
var right_hand_pose_action: Spatial = null

var left_hand_pose: int = vr_hand_pose_action_const.HAND_POSE_DEFAULT
var right_hand_pose: int = vr_hand_pose_action_const.HAND_POSE_DEFAULT

func update_hand_pose_action(p_action: int, p_right: bool, p_pressed: bool) -> void:
	if p_right:
		match(p_action):
			vr_hand_pose_action_const.HAND_POSE_OPEN:
				var a: InputEventAction = InputEventAction.new()
				a.action = "right_hand_pose_open"
				a.pressed = p_pressed
				Input.parse_input_event(a)
			vr_hand_pose_action_const.HAND_POSE_NEUTRAL:
				var a: InputEventAction = InputEventAction.new()
				a.action = "right_hand_pose_neutral"
				a.pressed = p_pressed 
				Input.parse_input_event(a)
			vr_hand_pose_action_const.HAND_POSE_POINT:
				var a: InputEventAction = InputEventAction.new()
				a.action = "right_hand_pose_point"
				a.pressed = p_pressed 
				Input.parse_input_event(a)
			vr_hand_pose_action_const.HAND_POSE_GUN:
				var a: InputEventAction = InputEventAction.new()
				a.action = "right_hand_pose_gun"
				a.pressed = p_pressed 
				Input.parse_input_event(a)
			vr_hand_pose_action_const.HAND_POSE_THUMBS_UP:
				var a: InputEventAction = InputEventAction.new()
				a.action = "right_hand_pose_thumbs_up"
				a.pressed = p_pressed 
				Input.parse_input_event(a)
			vr_hand_pose_action_const.HAND_POSE_FIST:
				var a: InputEventAction = InputEventAction.new()
				a.action = "right_hand_pose_fist"
				a.pressed = p_pressed 
				Input.parse_input_event(a)
			vr_hand_pose_action_const.HAND_POSE_VICTORY:
				var a: InputEventAction = InputEventAction.new()
				a.action = "right_hand_pose_victory"
				a.pressed = p_pressed 
				Input.parse_input_event(a)
			vr_hand_pose_action_const.HAND_POSE_OK_SIGN:
				var a: InputEventAction = InputEventAction.new()
				a.action = "right_hand_pose_ok_sign"
				a.pressed = p_pressed 
				Input.parse_input_event(a)
	else:
		match(p_action):
			vr_hand_pose_action_const.HAND_POSE_OPEN:
				var a: InputEventAction = InputEventAction.new()
				a.action = "left_hand_pose_open"
				a.pressed = p_pressed 
				Input.parse_input_event(a)
			vr_hand_pose_action_const.HAND_POSE_NEUTRAL:
				var a: InputEventAction = InputEventAction.new()
				a.action = "left_hand_pose_neutral"
				a.pressed = p_pressed 
				Input.parse_input_event(a)
			vr_hand_pose_action_const.HAND_POSE_POINT:
				var a: InputEventAction = InputEventAction.new()
				a.action = "left_hand_pose_point"
				a.pressed = p_pressed 
				Input.parse_input_event(a)
			vr_hand_pose_action_const.HAND_POSE_GUN:
				var a: InputEventAction = InputEventAction.new()
				a.action = "left_hand_pose_gun"
				a.pressed = p_pressed 
				Input.parse_input_event(a)
			vr_hand_pose_action_const.HAND_POSE_THUMBS_UP:
				var a: InputEventAction = InputEventAction.new()
				a.action = "left_hand_pose_thumbs_up"
				a.pressed = p_pressed 
				Input.parse_input_event(a)
			vr_hand_pose_action_const.HAND_POSE_FIST:
				var a: InputEventAction = InputEventAction.new()
				a.action = "left_hand_pose_fist"
				a.pressed = p_pressed 
				Input.parse_input_event(a)
			vr_hand_pose_action_const.HAND_POSE_VICTORY:
				var a: InputEventAction = InputEventAction.new()
				a.action = "left_hand_pose_victory"
				a.pressed = p_pressed 
				Input.parse_input_event(a)
			vr_hand_pose_action_const.HAND_POSE_OK_SIGN:
				var a: InputEventAction = InputEventAction.new()
				a.action = "left_hand_pose_ok_sign"
				a.pressed = p_pressed 
				Input.parse_input_event(a)
	
func left_hand_pose_updated(p_new_pose: int) -> void:
	if p_new_pose != left_hand_pose:
		update_hand_pose_action(left_hand_pose, false, false)
		left_hand_pose = p_new_pose
		update_hand_pose_action(left_hand_pose, false, true)
	
func right_hand_pose_updated(p_new_pose: int) -> void:
	if p_new_pose != right_hand_pose:
		update_hand_pose_action(right_hand_pose, true, false)
		right_hand_pose = p_new_pose
		update_hand_pose_action(right_hand_pose, true, true)

func tracker_added(p_tracker: vr_controller_tracker_const) -> void:
	.tracker_added(p_tracker)
	
	var tracker_hand: int = p_tracker.get_hand()
	if tracker_hand == ARVRPositionalTracker.TRACKER_LEFT_HAND or\
	tracker_hand == ARVRPositionalTracker.TRACKER_RIGHT_HAND:
		var vr_hand_pose_action: Spatial = vr_hand_pose_action_const.new()
		p_tracker.add_component_action(vr_hand_pose_action)
		match tracker_hand:
			ARVRPositionalTracker.TRACKER_LEFT_HAND:
				assert(!is_instance_valid(left_hand_pose_action))
				left_hand_pose_action = vr_hand_pose_action
				assert(left_hand_pose_action.connect("hand_pose_changed", self, "left_hand_pose_updated") == OK)
			ARVRPositionalTracker.TRACKER_RIGHT_HAND:
				assert(!is_instance_valid(right_hand_pose_action))
				right_hand_pose_action = vr_hand_pose_action
				assert(right_hand_pose_action.connect("hand_pose_changed", self, "right_hand_pose_updated") == OK)
				
func tracker_removed(p_tracker: vr_controller_tracker_const) -> void:
	.tracker_removed(p_tracker)
	
	match p_tracker.get_hand():
		ARVRPositionalTracker.TRACKER_LEFT_HAND:
			p_tracker.remove_component_action(left_hand_pose_action)
			left_hand_pose_action = null
			left_hand_pose_updated(vr_hand_pose_action_const.HAND_POSE_DEFAULT)
		ARVRPositionalTracker.TRACKER_RIGHT_HAND:
			p_tracker.remove_component_action(right_hand_pose_action)
			right_hand_pose_action = null
			right_hand_pose_updated(vr_hand_pose_action_const.HAND_POSE_DEFAULT)

func post_add_setup() -> void:
	pass
	
func _enter_tree():
	set_name("HandPoseComponent")
