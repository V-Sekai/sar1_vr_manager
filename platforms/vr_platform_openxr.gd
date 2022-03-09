@tool
extends "res://addons/sar1_vr_manager/platforms/vr_platform.gd" # vr_platform.gd

var trackers: Array = []

var controller_actions_scene_path: String = "res://addons/sar1_vr_manager/openxr/controller_actions.tscn"
var controller_actions_scene: PackedScene = null

var action_sets: PackedStringArray = PackedStringArray([])

var openxr_config: RefCounted = null

func get_platform_name() -> String:
	return "OpenXR"
	
static func create_pose(p_pose:Node3D, p_name: String, p_action: String, p_hand: int, p_origin: XROrigin3D) -> Node3D:
	p_pose.set_name("Right%s" % p_name if p_hand == XRPositionalTracker.TRACKER_HAND_RIGHT else "Left%s" % p_name)
	p_pose.set_action(p_action)
	p_pose.set_on_hand(p_hand)
	
	p_origin.add_child(p_pose, true)
	
	return p_pose
	
func create_poses_for_controller(p_controller: XRController3D, p_origin: XROrigin3D) -> void:
	if p_origin:
		var openvr_pose_nativescript: NativeScript = load("res://addons/godot-openvr/OpenVRPose.gdns")
		if openvr_pose_nativescript and openvr_pose_nativescript.can_instantiate():
			var hand: int = p_controller.get_tracker_hand()
			
			#var model:Spatial = create_pose("Model", "/actions/menu/in/model", hand, p_origin)
			var model_origin:Node3D = create_pose(openvr_pose_nativescript.new(), "ModelOrigin", "/actions/menu/in/model_origin", hand, p_origin)
			var laser_origin:Node3D = create_pose(openvr_pose_nativescript.new(), "LaserOrigin", "/actions/menu/in/laser_origin", hand, p_origin)
			
			p_controller.model_origin = model_origin
			p_controller.laser_origin = laser_origin
		else:
			printerr("VRPlatformOpenXR: OpenXRPose could not be instanced!")
	else:
		printerr("VRPlatformOpenXR: Origin does not exist!")
		
func destroy_poses_for_controller(p_controller: XRController3D) -> void:
	if p_controller.laser_origin:
		p_controller.laser_origin.queue_free()
		
	if p_controller.model_origin:
		p_controller.model_origin.queue_free()
		
func add_controller(p_controller: XRController3D, p_origin: XROrigin3D):
	super.add_controller(p_controller, p_origin)
	
	var hand: int = p_controller.get_tracker_hand()
	if hand != XRPositionalTracker.TRACKER_HAND_UNKNOWN:
		create_poses_for_controller(p_controller, p_origin)
		if controller_actions_scene:
			var controller_actions: Node = controller_actions_scene.instantiate()
			if controller_actions:
				controller_actions.get_tracker_hand(hand)
				p_controller.add_child(controller_actions, true)
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
	print("OpenXR pre-setup...")
	super.pre_setup()


func setup() -> void:
	print("Setting up OpenXR platform...")
	super.setup()

	#for action_set in action_sets:
	#	openvr_config.toggle_action_set_active(action_set, true)

	if ResourceLoader.exists(controller_actions_scene_path):
		controller_actions_scene = ResourceLoader.load(controller_actions_scene_path)
