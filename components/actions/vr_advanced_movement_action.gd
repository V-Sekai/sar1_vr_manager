extends "res://addons/sar1_vr_manager/components/actions/vr_action.gd" # vr_action.gd

signal jump_pressed()
signal jump_released()

func _on_action_pressed(p_action: String) -> void:
	super._on_action_pressed(p_action)
	match p_action:
		"/locomotion/jump":
			jump_pressed.emit()


func _on_action_released(p_action: String) -> void:
	super._on_action_released(p_action)
	match p_action:
		"/locomotion/jump":
			jump_released.emit()
