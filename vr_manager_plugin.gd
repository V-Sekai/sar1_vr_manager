tool
extends EditorPlugin

var editor_interface = null


func _init() -> void:
	print("Initialising Sar1VRManager plugin")

func _notification(p_notification: int):
	match p_notification:
		NOTIFICATION_PREDELETE:
			print("Destroying Sar1VRManager plugin")


func get_name() -> String:
	return "Sar1VRManager"


func _enter_tree() -> void:
	editor_interface = get_editor_interface()
	add_autoload_singleton("VRManager", "res://addons/sar1_vr_manager/vr_manager.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("VRManager")
