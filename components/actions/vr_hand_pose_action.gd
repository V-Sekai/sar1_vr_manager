extends "vr_action.gd"

enum {
	HAND_POSE_0,
	HAND_POSE_1,
	HAND_POSE_2,
	HAND_POSE_3,
	HAND_POSE_4,
	HAND_POSE_5,
	HAND_POSE_6,
	HAND_POSE_7,
	HAND_POSE_8,
	HAND_POSE_9
	HAND_POSE_COUNT
}

var hand_pose_stack: Array = []
var current_hand_pose = HAND_POSE_0

func update_hand_pose_from_stack() -> void:
	if hand_pose_stack.size() > 0:
		current_hand_pose = hand_pose_stack.front()
	else:
		current_hand_pose = HAND_POSE_0
		
func update_hand_pose_from_index(p_index: int) -> void:
	if p_index < HAND_POSE_0:
		p_index = HAND_POSE_9
	elif p_index > HAND_POSE_9:
		p_index = HAND_POSE_0
		
	current_hand_pose = p_index

func _on_action_pressed(p_action: String) -> void:
	._on_action_pressed(p_action)
	var stack_updated: bool = false
	match p_action:
		"/hands/hand_pose_1":
			hand_pose_stack.push_back(HAND_POSE_1)
			stack_updated = true
		"/hands/hand_pose_2":
			hand_pose_stack.push_back(HAND_POSE_2)
			stack_updated = true
		"/hands/hand_pose_3":
			hand_pose_stack.push_back(HAND_POSE_3)
			stack_updated = true
		"/hands/hand_pose_4":
			hand_pose_stack.push_back(HAND_POSE_4)
			stack_updated = true
		"/hands/hand_pose_5":
			hand_pose_stack.push_back(HAND_POSE_5)
			stack_updated = true
		"/hands/hand_pose_6":
			hand_pose_stack.push_back(HAND_POSE_6)
			stack_updated = true
		"/hands/hand_pose_7":
			hand_pose_stack.push_back(HAND_POSE_7)
			stack_updated = true
		"/hands/hand_pose_8":
			hand_pose_stack.push_back(HAND_POSE_8)
			stack_updated = true
		"/hands/hand_pose_9":
			hand_pose_stack.push_back(HAND_POSE_9)
			stack_updated = true
			
	if stack_updated:
		update_hand_pose_from_stack()

func _on_action_released(p_action: String) -> void:
	._on_action_released(p_action)
	var index: int = -1
	var stack_updated: bool = false
	match p_action:
		"/hands/hand_pose_1":
			index = hand_pose_stack.find(HAND_POSE_1)
			stack_updated = true
		"/hands/hand_pose_2":
			index = hand_pose_stack.find(HAND_POSE_2)
			stack_updated = true
		"/hands/hand_pose_3":
			index = hand_pose_stack.find(HAND_POSE_3)
			stack_updated = true
		"/hands/hand_pose_4":
			index = hand_pose_stack.find(HAND_POSE_4)
			stack_updated = true
		"/hands/hand_pose_5":
			index = hand_pose_stack.find(HAND_POSE_5)
			stack_updated = true
		"/hands/hand_pose_6":
			index = hand_pose_stack.find(HAND_POSE_6)
			stack_updated = true
		"/hands/hand_pose_7":
			index = hand_pose_stack.find(HAND_POSE_7)
			stack_updated = true
		"/hands/hand_pose_8":
			index = hand_pose_stack.find(HAND_POSE_8)
			stack_updated = true
		"/hands/hand_pose_9":
			index = hand_pose_stack.find(HAND_POSE_9)
			stack_updated = true
			
	if index != -1:
		if stack_updated:
			hand_pose_stack.remove(index)
			update_hand_pose_from_stack()
		else:
			pass

func _ready() -> void:
	pass
