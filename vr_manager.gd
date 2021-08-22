@tool
extends Node

const string_util_const = preload("res://addons/gd_util/string_util.gd")
const vr_user_preferences_const = preload("vr_user_preferences.gd")

var vr_user_preferences: RefCounted = vr_user_preferences_const.new()
var vr_components: Array = []

var interface_names: Array = []

var flat_resolution: Vector2 = Vector2(1280, 720)

# Names
const body_awareness_names = (
	["TR_VR_MANAGER_BODY_AWARENESS_HANDS_ONLY",\
	"TR_VR_MANAGER_BODY_AWARENESS_CONTROLLERS_ONLY",\
	"TR_VR_MANAGER_BODY_AWARENESS_FULL_BODY"])
const turning_mode_names = (
	["TR_VR_MANAGER_TURN_SMOOTH",\
	"TR_VR_MANAGER_TURN_30_DEGREES",
	"TR_VR_MANAGER_TURN_45_DEGREES",\
	"TR_VR_MANAGER_TURN_90_DEGREES",\
	"TR_VR_MANAGER_TURN_CUSTOM"]
)
const play_position_names = (
	["TR_VR_MANAGER_PLAY_POSITION_STANDING",\
	"TR_VR_MANAGER_PLAY_POSITION_SEATED"])
const movement_orientation_names = (
	["TR_VR_MANAGER_HEAD_ORIENTED_MOVEMENT",\
	"TR_VR_MANAGER_HAND_ORIENTED_MOVEMENT",\
	"TR_VR_MANAGER_PLAYSPACE_ORIENTED_MOVEMENT"]
)
const vr_hmd_mirroring_names = (
	["TR_VR_MANAGER_UI_NO_MIRROR", "TR_VR_MANAGER_UI_MIRROR_VR"])
const vr_control_type_names = (
	["TR_VR_MANAGER_CONTROL_TYPE_CLASSIC", "TR_VR_MANAGER_CONTROL_TYPE_DUAL"])
const preferred_hand_oriented_movement_hand_names = (
	["TR_VR_MANAGER_PREFERRED_HAND_ORIENTED_MOVEMENT_LEFT",\
	"TR_VR_MANAGER_PREFERRED_HAND_ORIENTED_MOVEMENT_RIGHT"])
const movement_type_names = (
	["TR_VR_MANAGER_MOVEMENT_TELEPORTATION",\
	"TR_VR_MANAGER_MOVEMENT_LOCOMOTION"])

# Platforms
const vr_platform_const = preload("platforms/vr_platform.gd")
const vr_platform_openvr_const = preload("platforms/vr_platform_openvr.gd")
const vr_platform_ovr_mobile_const = preload("platforms/vr_platform_ovr_mobile.gd")
var vr_platform_oculus_const: Variant = null

const vr_constants_const = preload("vr_constants.gd")
const vr_render_cache_const = preload("vr_render_cache.gd")
const vr_render_tree_const = preload("vr_render_tree.gd")

var vr_platform: RefCounted = null # vr_platform_const = null

var vr_platform_openvr: RefCounted = null # : vr_platform_const = null
var vr_platform_oculus: RefCounted = null # : vr_platform_const = null
var vr_platform_ovr_mobile: RefCounted = null # : vr_platform_const = null

var render_cache = vr_render_cache_const.new()

var xr_interface: XRInterface = null
var xr_origin: XROrigin3D = null
var xr_active: bool = false

var vr_fader: ColorRect = null

var xr_tracker_count: int = 0
var xr_trackers: Dictionary = {}

var snap_turning_radians: float = 0.0

signal new_origin_assigned(p_origin)

signal xr_mode_changed()
signal world_origin_scale_changed(p_scale)

signal tracker_added(tracker_name, type, id)
signal tracker_removed(tracker_name, type, id)

# Called for changes to height and armspan
signal proportions_changed()

signal request_vr_calibration()
signal confirm_vr_calibration()

var laser_material: Material = null
var laser_hit_material: Material = null

func _fade_color_changed(p_color: Color) -> void:
	vr_fader.color = p_color


func create_laser_material(p_transparent: bool) -> Material:
	var new_laser_material = StandardMaterial3D.new()
	new_laser_material.flags_transparent = p_transparent
	new_laser_material.flags_unshaded = true
	new_laser_material.albedo_color = vr_user_preferences.laser_color

	return new_laser_material


func get_laser_material() -> Material:
	if laser_material == null:
		laser_material = create_laser_material(false)

	return laser_material


func is_xr_active() -> bool:
	return xr_active


func get_origin() -> XROrigin3D:
	return xr_origin

func update_turning_radians() -> void:
	match vr_user_preferences.turning_mode:
		vr_user_preferences_const.turning_mode_enum.TURNING_MODE_SNAP_30:
			snap_turning_radians = deg2rad(30.0)
		vr_user_preferences_const.turning_mode_enum.TURNING_MODE_SNAP_45:
			snap_turning_radians = deg2rad(45.0)
		vr_user_preferences_const.turning_mode_enum.TURNING_MODE_SNAP_90:
			snap_turning_radians = deg2rad(90.0)
		vr_user_preferences_const.turning_mode_enum.TURNING_MODE_SNAP_CUSTOM:
			snap_turning_radians = deg2rad(vr_user_preferences.snap_turning_degrees_custom)

func settings_changed() -> void:
	update_turning_radians()

func create_render_tree() -> Node3D:
	if xr_interface:
		print("Creating render tree for platform %s" % vr_platform.get_platform_name())
		var render_tree: Node3D = vr_platform.create_render_tree()

		if render_tree:
			render_tree.set_name("RenderTree")

		return render_tree
	else:
		return null


func is_joypad_id_input_map_valid(p_id: int) -> bool:
	for i in xr_tracker_count:
		var tracker: XRPositionalTracker = XRServer.get_tracker(i)

		if tracker.get_joy_id() == p_id:
			return false

	return true


static func get_tracker_type_name(p_type: int) -> String:
	match p_type:
		XRServer.TRACKER_CONTROLLER:
			return "controller"
		XRServer.TRACKER_BASESTATION:
			return "base station"
		XRServer.TRACKER_ANCHOR:
			return "anchor"
		XRServer.TRACKER_ANY_KNOWN:
			return "any known"
		XRServer.TRACKER_UNKNOWN:
			return "unknown"
		_:
			return "?"


func get_render_cache():
	return render_cache


func _on_interface_added(p_interface_name: String) -> void:
	print("Interface added %s" % p_interface_name)


func _on_interface_removed(p_interface_name: String) -> void:
	print("Interface removed %s" % p_interface_name)


func _on_tracker_added(p_tracker_name: String, p_type: int, p_id: int) -> void:
	print(
		"Tracker added {tracker_name} type {tracker_type_name} id {id}".format(
			{
				"tracker_name": p_tracker_name,
				"tracker_type_name": get_tracker_type_name(p_type),
				"id": str(p_id)
			}
		)
	)

	xr_tracker_count += 1

	var tracker_id: int = xr_tracker_count - 1
	var tracker: XRPositionalTracker = XRServer.get_tracker(tracker_id)

	xr_trackers[p_id] = tracker
	
	emit_signal("tracker_added", p_tracker_name, p_type, p_id)


func _on_tracker_removed(p_tracker_name: String, p_type: int, p_id: int) -> void:
	print(
		"Tracker removed {tracker_name} type {tracker_type_name} id {id}".format(
			{
				"tracker_name": p_tracker_name,
				"tracker_type_name": get_tracker_type_name(p_type),
				"id": str(p_id)
			}
		)
	)

	xr_tracker_count -= 1
	
	if xr_trackers.has(p_id):
		if xr_trackers.erase(p_id):
			emit_signal("tracker_removed", p_tracker_name, p_type, p_id)


func create_vr_platform_for_interface(p_interface_name: String) -> void:
	match p_interface_name:
		"OpenVR":
			vr_platform = vr_platform_openvr
		"Oculus":
			vr_platform = vr_platform_oculus
		"OVRMobile":
			vr_platform = vr_platform_ovr_mobile
		_:
			vr_platform = vr_platform_const.new()

	if vr_platform:
		vr_platform.setup()


func create_vr_platforms() -> void:
	if vr_platform_openvr_const:
		vr_platform_openvr = vr_platform_openvr_const.new()
		if vr_platform_openvr:
			vr_platform_openvr.pre_setup()

	if vr_platform_oculus_const:
		vr_platform_oculus = vr_platform_oculus_const.new()
		if vr_platform_oculus:
			vr_platform_oculus.pre_setup()

	if vr_platform_ovr_mobile_const:
		vr_platform_ovr_mobile = vr_platform_ovr_mobile_const.new()
		if vr_platform_ovr_mobile:
			vr_platform_ovr_mobile.pre_setup()


func platform_add_controller(p_controller: XRController3D, p_origin: XROrigin3D) -> void:
	vr_platform.add_controller(p_controller, p_origin)

func platform_remove_controller(p_controller: XRController3D, p_origin: XROrigin3D) -> void:
	vr_platform.remove_controller(p_controller, p_origin)

func is_quitting() -> void:
	vr_user_preferences.set_settings_values()
	
func setup_vr_interface() -> void:
	# Temporary workaround to prevent OpenVR plugin crash!
	var _render_model_temp = load("res://addons/godot-openvr/OpenVRRenderModel.gdns")

	# Search through all the vr interface names in project configuration
	# Break when one has been found
	for interface_name in interface_names:
		xr_interface = XRServer.find_interface(interface_name)
		if xr_interface:
			print("Attempting to initialise %s..." % interface_name)
			if xr_interface.initialize():
				print("%s Initalised!" % interface_name)
				create_vr_platform_for_interface(interface_name)
				
				if vr_user_preferences.vr_mode_enabled:
					OS.vsync_enabled = false
					xr_active = true
					return
					
				break
			else:
				print("Could not initalise interface %s..." % interface_name)
					
	print("Could not initalise any VR interface...")
	# FIXME: Need vsync_enabled=true for non-VR
	###### OS.vsync_enabled = true
	xr_active = false
		
func initialise_vr_interface(p_force: bool = false) -> void:
	if (!xr_interface and vr_user_preferences.vr_mode_enabled) or \
		p_force:
		setup_vr_interface()
		
func toggle_vr() -> void:
	var enabled: bool = !vr_user_preferences.vr_mode_enabled
	vr_user_preferences.vr_mode_enabled = enabled
	
	initialise_vr_interface()
	
	if xr_interface:
		xr_active = enabled
		OS.vsync_enabled = !enabled
	else:
		xr_active = false
		OS.vsync_enabled = true
		
	emit_signal("xr_mode_changed")

func force_update() -> void:
	if xr_active and xr_origin:
		xr_origin.notification(NOTIFICATION_INTERNAL_PROCESS)
		#xr_origin._cache_world_origin_transform()
		#xr_origin._update_tracked_camera()
	
func set_origin_world_scale(p_scale: float) -> void:
	if xr_origin:
		xr_origin.set_world_scale(p_scale)
		emit_signal("world_origin_scale_changed", p_scale)
	
func assign_xr_origin(p_xr_origin) -> void:
	if xr_origin != p_xr_origin:
		xr_origin = p_xr_origin
		emit_signal("new_origin_assigned", xr_origin)
	
func apply_project_settings() -> void:
	if Engine.is_editor_hint():
		#################
		# VR Interfaces #
		#################
		if ! ProjectSettings.has_setting("vr/config/interfaces"):
			ProjectSettings.set_setting("vr/config/interfaces", PackedStringArray())
	
			var vr_interfaces_property_info: Dictionary = {
				"name": "vr/config/interfaces",
				"type": TYPE_STRING_ARRAY,
				"hint": PROPERTY_HINT_NONE,
				"hint_string": ""
			}
		
			ProjectSettings.add_property_info(vr_interfaces_property_info)
	
		if ! ProjectSettings.has_setting("vr/config/process_priority"):
			ProjectSettings.set_setting("vr/config/process_priority", 0)
	
		########
		# Save #
		########
		if ProjectSettings.save() != OK:
			printerr("Could not save project settings!")

func get_project_settings() -> void:
	interface_names = ProjectSettings.get_setting("vr/config/interfaces")
	process_priority = ProjectSettings.get_setting("vr/config/process_priority")
	
func _input(p_event: InputEvent) -> void:
	if p_event.is_action_pressed("toggle_vr"):
		toggle_vr()
	elif p_event.is_action_pressed("request_vr_calibration"):
		emit_signal("request_vr_calibration")
	elif p_event.is_action_pressed("confirm_vr_calibration"):
		emit_signal("confirm_vr_calibration")

func _process(_delta) -> void:
	force_update()

func _ready() -> void:
	apply_project_settings()
	get_project_settings()
	
	settings_changed()
	
	if vr_user_preferences.connect("settings_changed", Callable(self, "settings_changed")) != OK:
		printerr("Could not connect settings_changed!")
	
	vr_fader = ColorRect.new()
	if FadeManager.connect("color_changed", Callable(self, "_fade_color_changed")) != OK:
		printerr("Could not connect 'color_changed'!")

	# Caches the laser material for laser use
	laser_material = create_laser_material(false)

	# Sets up the VR state
	create_vr_platforms()

	if ! Engine.is_editor_hint():
		InputManager.assign_input_map_validation_callback(self, "is_joypad_id_input_map_valid")

		if (
			XRServer.connect(
				"interface_added", Callable(self, "_on_interface_added"), [], CONNECT_DEFERRED
			)
			!= OK
		):
			printerr("interface_added could not be connected")
		if (
			XRServer.connect(
				"interface_removed", Callable(self, "_on_interface_removed"), [], CONNECT_DEFERRED
			)
			!= OK
		):
			printerr("interface_removed could not be connected")

		if (
			XRServer.connect("tracker_added", Callable(self, "_on_tracker_added"), [], CONNECT_DEFERRED)
			!= OK
		):
			printerr("tracker_added could not be connected")
		if (
			XRServer.connect(
				"tracker_removed", Callable(self, "_on_tracker_removed"), [], CONNECT_DEFERRED
			)
			!= OK
		):
			printerr("tracker_removed could not be connected")
		set_process(true)
		set_process_input(true)
	else:
		set_process(false)
		set_process_input(false)
