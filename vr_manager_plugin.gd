tool
extends EditorPlugin

var editor_interface = null


func _init() -> void:
	print("Initialising VRManager plugin")

func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying VRManager plugin")


func get_name() -> String:
	return "VRManager"


func _enter_tree() -> void:
	editor_interface = get_editor_interface()
	add_autoload_singleton("VRManager", "res://addons/vr_manager/vr_manager.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("VRManager")
