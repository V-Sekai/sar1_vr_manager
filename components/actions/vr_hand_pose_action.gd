extends "res://addons/sar1_vr_manager/components/actions/vr_action.gd" # vr_action.gd

signal hand_pose_changed(p_pose)

var thumb_touched: bool = false
var trigger_touched: bool = false
var grip_touched: bool = false
var trigger_pressed: bool = false
var grip_pressed: bool = false


const HAND_POSE_DEFAULT=0
const HAND_POSE_OPEN=1
const HAND_POSE_NEUTRAL=2
const HAND_POSE_POINT=3
const HAND_POSE_GUN=4
const HAND_POSE_THUMBS_UP=5
const HAND_POSE_FIST=6
const HAND_POSE_VICTORY=7
const HAND_POSE_OK_SIGN=8
const HAND_POSE_COUNT=9


var current_hand_pose: int = HAND_POSE_DEFAULT

# Designed around Oculus controls
func update_virtual_hand_pose() -> void:
	var new_hand_pose: int = HAND_POSE_DEFAULT
	
	if thumb_touched:
		if grip_pressed:
			if trigger_touched or trigger_pressed:
				new_hand_pose = HAND_POSE_FIST
			else:
				new_hand_pose = HAND_POSE_POINT
		else:
			if trigger_touched or trigger_pressed:
				if trigger_pressed:
					new_hand_pose = HAND_POSE_OK_SIGN
				else:
					new_hand_pose = HAND_POSE_NEUTRAL
			else:
				new_hand_pose = HAND_POSE_VICTORY
	else:		
		if grip_pressed:
			if trigger_touched or trigger_pressed:
				new_hand_pose = HAND_POSE_THUMBS_UP
			else:
				new_hand_pose = HAND_POSE_GUN
		else:
			if trigger_touched or trigger_pressed:
				new_hand_pose = HAND_POSE_NEUTRAL
			else:
				new_hand_pose = HAND_POSE_OPEN
	
	if new_hand_pose != current_hand_pose:
		current_hand_pose = new_hand_pose
		print("Emitting hand_pose_changed...")
		emit_signal("hand_pose_changed", current_hand_pose)
	

func _on_action_pressed(p_action: String) -> void:
	super._on_action_pressed(p_action)
	match p_action:
		"/hands/hand_pose_thumb_touched":
			thumb_touched = true
			update_virtual_hand_pose()
		"/hands/hand_pose_trigger_touched":
			trigger_touched = true
			update_virtual_hand_pose()
		"/hands/hand_pose_trigger_pressed":
			trigger_pressed = true
			update_virtual_hand_pose()
		"/hands/hand_pose_grip_touched":
			grip_touched = true
			update_virtual_hand_pose()
		"/hands/hand_pose_grip_pressed":
			grip_pressed = true
			update_virtual_hand_pose()

func _on_action_released(p_action: String) -> void:
	super._on_action_released(p_action)
	match p_action:
		"/hands/hand_pose_thumb_touched":
			thumb_touched = false
			update_virtual_hand_pose()
		"/hands/hand_pose_trigger_touched":
			trigger_touched = false
			update_virtual_hand_pose()
		"/hands/hand_pose_trigger_pressed":
			trigger_pressed = false
			update_virtual_hand_pose()
		"/hands/hand_pose_grip_touched":
			grip_touched = false
			update_virtual_hand_pose()
		"/hands/hand_pose_grip_pressed":
			grip_pressed = false
			update_virtual_hand_pose()

func _ready() -> void:
	pass
