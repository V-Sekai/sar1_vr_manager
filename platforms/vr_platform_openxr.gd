@tool
extends "res://addons/sar1_vr_manager/platforms/vr_platform.gd"

const vr_platform_openxr_const = preload("res://addons/sar1_vr_manager/platforms/vr_platform_openxr.gd")
const vr_render_tree_openxr_class = preload("./vr_render_tree_openxr.gd")

var trackers: Array = []

var controller_actions_scene_path: String = "res://addons/sar1_vr_manager/openxr/controller_actions.tscn"
var controller_actions_scene: PackedScene = null

var action_sets: PackedStringArray = PackedStringArray([])

var openxr_config: RefCounted = null

func get_platform_name() -> String:
	return "OpenXR"
	
func create_render_tree() -> Node3D:
	return vr_render_tree_openxr_class.new()

static func create_pose(p_pose:XRController3D, p_name: String, p_action: StringName, p_tracker: StringName, p_origin: XROrigin3D) -> Node3D:
	p_pose.set_name("%s_%s" % [p_tracker, p_name])
	p_pose.pose = p_action
	p_pose.tracker = p_tracker
	
	p_origin.add_child(p_pose, true)
	
	return p_pose
	
func create_poses_for_controller(p_controller: XRController3D, p_origin: XROrigin3D) -> void:
	if p_origin:
		var _hand: int = p_controller.get_tracker_hand()
		
		var model_origin:Node3D = vr_platform_openxr_const.create_pose(XRController3D.new(), "ModelOrigin", &"aim_pose", p_controller.tracker, p_origin)
		var laser_origin:Node3D = vr_platform_openxr_const.create_pose(XRController3D.new(), "LaserOrigin", &"aim_pose", p_controller.tracker, p_origin)
		
		p_controller.model_origin = model_origin
		p_controller.laser_origin = laser_origin
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
					p_controller.get_analog_funcref = controller_actions.get_axis

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
