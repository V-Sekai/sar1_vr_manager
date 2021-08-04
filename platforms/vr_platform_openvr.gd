@tool
extends "res://addons/sar1_vr_manager/platforms/vr_platform.gd" # vr_platform.gd

var trackers: Array = []

var controller_actions_scene_path: String = "res://addons/sar1_vr_manager/openvr/controller_actions.tscn"
var controller_actions_scene: PackedScene = null

var action_json_editor_directory: String = "res://assets/actions/openvr/actions"
var action_json_filename: String = "actions.json"
var default_action_set: String = "/actions/godot"

var action_sets: PackedStringArray = PackedStringArray([])

#var openvr_controller_nativescript: NativeScript = preload("res://addons/godot-openvr/OpenVRController.gdns")
var openvr_config: RefCounted = null

const vr_render_openvr_tree_const = preload("../openvr/vr_render_tree_openvr.gd")


func get_platform_name() -> String:
	return "OpenVR"


func create_render_tree() -> Node3D:
	return vr_render_openvr_tree_const.new()
	
static func create_pose(p_pose:Node3D, p_name: String, p_action: String, p_hand: int, p_origin: XROrigin3D) -> Node3D:
	p_pose.set_name("Right%s" % p_name if p_hand == XRPositionalTracker.TRACKER_HAND_RIGHT else "Left%s" % p_name)
	p_pose.set_action(p_action)
	p_pose.set_on_hand(p_hand)
	
	p_origin.add_child(p_pose)
	
	return p_pose

func create_poses_for_controller(p_controller: XRController3D, p_origin: XROrigin3D) -> void:
	if p_origin:
		var openvr_pose_nativescript: NativeScript = load("res://addons/godot-openvr/OpenVRPose.gdns")
		if openvr_pose_nativescript and openvr_pose_nativescript.can_instance():
			var hand: int = p_controller.get_hand()
			
			#var model:Spatial = create_pose("Model", "/actions/menu/in/model", hand, p_origin)
			var model_origin:Node3D = create_pose(openvr_pose_nativescript.new(), "ModelOrigin", "/actions/menu/in/model_origin", hand, p_origin)
			var laser_origin:Node3D = create_pose(openvr_pose_nativescript.new(), "LaserOrigin", "/actions/menu/in/laser_origin", hand, p_origin)
			
			p_controller.model_origin = model_origin
			p_controller.laser_origin = laser_origin
		else:
			printerr("VRPlatformOpenVR: OpenVRPose could not be instanced!")
	else:
		printerr("VRPlatformOpenVR: Origin does not exist!")
		
func destroy_poses_for_controller(p_controller: XRController3D) -> void:
	if p_controller.laser_origin:
		p_controller.laser_origin.queue_free()
		
	if p_controller.model_origin:
		p_controller.model_origin.queue_free()
		
func add_controller(p_controller: XRController3D, p_origin: XROrigin3D):
	super.add_controller(p_controller, p_origin)
	
	var hand: int = p_controller.get_hand()
	if hand != XRPositionalTracker.TRACKER_HAND_UNKNOWN:
		create_poses_for_controller(p_controller, p_origin)
		if controller_actions_scene:
			var controller_actions: Node = controller_actions_scene.instantiate()
			if controller_actions:
				controller_actions.set_hand(hand)
				p_controller.add_child(controller_actions)
				if (
					controller_actions.has_signal("on_action_pressed")
					and controller_actions.has_signal("on_action_released")
				):
					if (
						controller_actions.connect(
							"on_action_pressed", Callable(p_controller, "_on_action_pressed"
						))
						!= OK
					):
						printerr("Could not connect signal 'on_action_pressed' !")
					if (
						controller_actions.connect(
							"on_action_released", Callable(p_controller, "_on_action_released"
						))
						!= OK
					):
						printerr("Could not connect signal 'on_action_released' !")

					p_controller.get_is_action_pressed_funcref = Callable(
						controller_actions, "is_action_pressed"
					)
					p_controller.get_analog_funcref = Callable(controller_actions, "get_analog")

func remove_controller(p_controller: XRController3D, p_origin: XROrigin3D):
	super.remove_controller(p_controller, p_origin)
	
	destroy_poses_for_controller(p_controller)

func pre_setup() -> void:
	print("OpenVR pre-setup...")
	super.pre_setup()

	###
	if ! ProjectSettings.has_setting("vr/config/openvr/controller_actions_scene"):
		ProjectSettings.set_setting(
			"vr/config/openvr/controller_actions_scene", controller_actions_scene_path
		)
	else:
		controller_actions_scene_path = ProjectSettings.get_setting(
			"vr/config/openvr/controller_actions_scene"
		)

	if ! ProjectSettings.has_setting("vr/config/openvr/action_json_filename"):
		ProjectSettings.set_setting("vr/config/openvr/action_json_filename", action_json_filename)
	else:
		action_json_filename = ProjectSettings.get_setting("vr/config/openvr/action_json_filename")

	if ! ProjectSettings.has_setting("vr/config/openvr/action_json_editor_directory"):
		ProjectSettings.set_setting("vr/config/openvr/action_json_editor_directory", action_json_editor_directory)
	else:
		action_json_editor_directory = ProjectSettings.get_setting("vr/config/openvr/action_json_editor_directory")

	if ! ProjectSettings.has_setting("vr/config/openvr/default_action_set"):
		ProjectSettings.set_setting("vr/config/openvr/default_action_set", default_action_set)
	else:
		default_action_set = ProjectSettings.get_setting("vr/config/openvr/default_action_set")

	if ! ProjectSettings.has_setting("vr/config/openvr/action_sets"):
		ProjectSettings.set_setting("vr/config/openvr/action_sets", action_sets)
	else:
		action_sets = ProjectSettings.get_setting("vr/config/openvr/action_sets")
	###

	if ! Engine.is_editor_hint():
		# Load our config before we initialise
		var openvr_config_nativescript: NativeScript = load("res://addons/godot-openvr/OpenVRConfig.gdns")
		if openvr_config_nativescript and openvr_config_nativescript.can_instance():
			openvr_config = openvr_config_nativescript.new()
			if openvr_config:
				if ProjectSettings.globalize_path("res://") == "":
					openvr_config.action_json_path = (
						OS.get_executable_path().get_base_dir()
						+ "/actions/"
						+ action_json_filename
					)
				else:
					openvr_config.action_json_path = (
						action_json_editor_directory
						+ "/" + action_json_filename
					)
				openvr_config.default_action_set = default_action_set
				print("ACTION JSON PATH IS: " + openvr_config.action_json_path)
				for action_set in action_sets:
					openvr_config.register_action_set(action_set)
		else:
			printerr("VRPlatformOpenVR: OpenVRConfig could not be instanced!!")


func setup() -> void:
	print("Setting up OpenVR platform...")
	super.setup()

	for action_set in action_sets:
		openvr_config.toggle_action_set_active(action_set, true)

	if ResourceLoader.exists(controller_actions_scene_path):
		controller_actions_scene = ResourceLoader.load(controller_actions_scene_path)
