extends "vr_action.gd"
export (Color) var straight_color = Color(247.0/255.0, 247.0/255.0, 1.0, 0.05)
export (Color) var unsnapped_color = Color(247.0/255.0, 247.0/255.0, 1.0, 0.1)
export (Color) var snapped_color = Color(254.0/255.0, 95.0/255.0, 85.0/255.0, 1.0)
export (Color) var snap_circle_color = Color(1.0, 1.0, 1.0, 1.0)
export (float) var snap_circle_min_alpha = 0.0
export(NodePath) var straight_laser
export(NodePath) var snapped_laser
export(NodePath) var primary_circle
export(NodePath) var secondary_circle
export var min_snap = 0.5
export var snap_increase = 2
# This node will be a child of a controller, add any input or display functionality here.
var current_snap: Spatial = null
var straight_mesh: MeshInstance = null
var snapped_mesh: MeshInstance = null
var primary_mesh: MeshInstance = null
var secondary_mesh: MeshInstance = null
var redirection_lock: bool = false
var redirection_ready: bool = true
var interact_ready: bool = false
var flick_origin_spatial: Spatial = null
# var initialized_laser_transform:bool = false

var print_mod = 0
export var rumble_duration: int = 100 #milisseconds
export var rumble_strength: float = 1.0

var rumble_start_time: int = 0

func _on_action_pressed(p_action: String) -> void:
	._on_action_pressed(p_action)
	match p_action:
		"/menu/lasso":
			pass


func _on_action_released(p_action: String) -> void:
	._on_action_released(p_action)
	match p_action:
		"/menu/lasso":
			pass

func _update_lasso(_delta: float) -> void:
	# Saracen: don't run this function if not in XR mode
	if !VRManager.xr_active:
		return
	
	# var start_time = OS.get_ticks_usec()
	var lasso_analog_value: Vector2 = get_analog("/menu/lasso_analog")
	var lasso: bool = is_pressed("/menu/lasso")
	redirection_lock = redirection_lock && (lasso_analog_value.length_squared() > 0)
	var new_snap = false
	var primary_snap: Vector3
	var secondary_snap: Vector3
	var primary_power: float = 0.0
	var secondary_power: float = 0.0
	if(lasso_analog_value.x > 0):
		var lasso_redirect_value: Vector2 = get_analog("/menu/lasso_redirect")
		# LogManager.printl(str(lasso_redirect_value))
		var snapping_singleton = get_node("/root/SnappingSingleton")
#		var points: Array = snapping_singleton.snapping_points
		var snap_point = null
		var redirecting: bool = redirection_ready && lasso_redirect_value.length_squared() > 0.0
		#you have to reset your joystick to the center to be able to redirect the lasso again
		redirection_ready = lasso_redirect_value.length_squared() <= 0.0
		if(redirecting && current_snap != null):
			redirection_lock = true
			var viewpoint: Transform = ARVRServer.get_hmd_transform()
			viewpoint.origin = flick_origin_spatial.global_transform.xform(viewpoint.origin)
			snap_point = snapping_singleton.snapping_points.calc_top_redirecting_power(current_snap, viewpoint, lasso_redirect_value)
			if(!snap_point):
				snap_point = current_snap
		else:
			interact_ready = interact_ready || !lasso
			if(current_snap && current_snap.is_inside_tree() && redirection_lock):
				snap_point = current_snap
				primary_power = 1
				secondary_power = 0
				primary_snap = snap_point.get_global_transform().origin
			else:
				var snap_arr:Array = snapping_singleton.snapping_points.calc_top_two_snapping_power(tracker.laser_origin.global_transform, current_snap, snap_increase, lasso_analog_value.x, lasso)
				if(snap_arr.size() > 0 && snap_arr[0] && snap_arr[0].get_origin() && snap_arr[0].get_snap_score() > min_snap):
					snap_point = snap_arr[0].get_origin()
					primary_power = snap_arr[0].get_snap_score()
					primary_snap = snap_point.get_global_transform().origin
				else:
					snap_point = current_snap;
					if(snap_point):
						primary_power = 1.0
						primary_snap = snap_point.get_global_transform().origin
				if(snap_arr.size() > 1 && snap_arr[1] && snap_arr[1].get_origin() && snap_arr[1].get_snap_score() > min_snap):
					secondary_power = snap_arr[1].get_snap_score();
					secondary_snap = snap_arr[1].get_origin().get_global_transform().origin

		if(current_snap != snap_point):
			interact_ready = !lasso
			new_snap = true
			if(current_snap != null):
				current_snap.stop_snap_hover()
				current_snap.stop_snap_interact()
			current_snap = snap_point
			if(current_snap != null):
				#HERE IS THE SNAP
				#do haptics here
				rumble_start_time = OS.get_ticks_msec()
				current_snap.call_snap_hover()
	else:
		if(current_snap != null):
			current_snap.stop_snap_hover()
		current_snap = null
		redirection_ready = false
		interact_ready = false
	
	#SO COOL HOW RUMBLE DOESNT WORK
	if (OS.get_ticks_msec() - rumble_start_time < rumble_duration):
		tracker.rumble = rumble_strength;
	else:
		tracker.rumble = 0.0
	
	if(current_snap != null):
		if(lasso && interact_ready):
			current_snap.call_snap_interact(self)
		else:
			current_snap.stop_snap_interact()
		
	if(straight_mesh != null && snapped_mesh != null):
		if(straight_mesh.material_override != null && snapped_mesh.material_override != null):
			var primary_alpha = 1.0
			var secondary_alpha = 0.0
			if(primary_power > min_snap && secondary_power > min_snap):
				primary_alpha = (primary_power - min_snap) / (primary_power + secondary_power - 2 * min_snap)
				secondary_alpha = 1.0 - primary_alpha
			elif(primary_power > min_snap):
				secondary_alpha = (secondary_power / primary_power)
			else:
				primary_alpha = lerp(snap_circle_min_alpha, 0.5, primary_power / (min_snap + 0.001))
				secondary_alpha = lerp(snap_circle_min_alpha, 0.5, secondary_power / (min_snap + 0.001))

			var primary_color = Color(snap_circle_color.r, snap_circle_color.g, snap_circle_color.b, lerp(snap_circle_min_alpha, 1.0, primary_alpha))
			var secondary_color = Color(snap_circle_color.r, snap_circle_color.g, snap_circle_color.b, lerp(snap_circle_min_alpha, 1.0, secondary_alpha))
			if(primary_mesh != null):
				primary_mesh.visible = primary_power > 0
				if(primary_power > 0):
					if(primary_mesh.material_override != null):
						primary_mesh.material_override.set_shader_param('mix_color', primary_color)
					primary_mesh.global_transform.origin = primary_snap
			if(secondary_mesh != null):
				secondary_mesh.visible = secondary_power > 0
				if(secondary_power > 0):
					if(secondary_mesh.material_override != null):
						secondary_mesh.material_override.set_shader_param('mix_color', secondary_color)
					secondary_mesh.global_transform.origin = secondary_snap

			if(lasso):
				snapped_mesh.material_override.set_shader_param('speed', -10.0)
			else:
				snapped_mesh.material_override.set_shader_param('speed', 0.0)

			if(lasso_analog_value.x <= 0):
				if(snapped_mesh.visible):
					snapped_mesh.material_override.set_shader_param('mix_color', unsnapped_color)
				straight_mesh.visible = false
				snapped_mesh.visible = false
			else:
				straight_mesh.visible = true
				snapped_mesh.visible = true
				if(current_snap != null):
					if(new_snap):
						snapped_mesh.material_override.set_shader_param('mix_color', snapped_color)
					var target_local = straight_mesh.global_transform.xform_inv(current_snap.global_transform.origin)
					var straight_length = target_local.length_squared() / (abs(target_local.z) + 0.001) #when there's very little snapping, this will equal .length() when there is a lot it'll be longer
					straight_mesh.material_override.set_shader_param('target', Vector3(0.0, 0.0, -straight_length))
					snapped_mesh.material_override.set_shader_param('target', target_local)
				else:
					if(new_snap):
						snapped_mesh.material_override.set_shader_param('mix_color', unsnapped_color)
					var into_infinity = Vector3(0.0, 0.0, -10)
					straight_mesh.material_override.set_shader_param('target', Vector3(0.0, 0.0, 0.0))
					snapped_mesh.material_override.set_shader_param('target', into_infinity)
		else:
			straight_mesh.visible = false
			snapped_mesh.visible = false

	# print_mod += 1
	# if(print_mod % 30 == 0 && lasso_analog_value.x > 0):
	# 	LogManager.printl("lasso frame microseconds: " + str(OS.get_ticks_usec() - start_time))
	return
	
func _process(p_delta: float) -> void:
	_update_lasso(p_delta)

# Saracen
func _update_visibility() -> void:
	if VRManager.xr_active:
		straight_mesh.show()
		snapped_mesh.show()
		set_process(true)
	else:
		straight_mesh.hide()
		snapped_mesh.hide()
		set_process(false)
		
# Saracen
func _xr_mode_changed() -> void:
	_update_visibility()

func _ready() -> void:
	# Saracen: disable visibility when not in XR mode
	assert(VRManager.connect("xr_mode_changed", self, "_xr_mode_changed") == OK)
	
	#Align with the laser_origin we were given
	assert(tracker.laser_origin)

	straight_mesh = get_node(straight_laser) as MeshInstance
	snapped_mesh = get_node(snapped_laser) as MeshInstance

	straight_mesh.get_parent().remove_child(straight_mesh)
	snapped_mesh.get_parent().remove_child(snapped_mesh)

	tracker.laser_origin.add_child(straight_mesh)
	tracker.laser_origin.add_child(snapped_mesh)

	straight_mesh.transform = Transform()
	snapped_mesh.transform = Transform()

	primary_mesh = get_node(primary_circle) as MeshInstance
	secondary_mesh = get_node(secondary_circle) as MeshInstance
	if(straight_mesh != null && straight_mesh.material_override != null):
		straight_mesh.material_override.set_shader_param('mix_color', straight_color)
		straight_mesh.material_override = straight_mesh.material_override.duplicate(true)
	if(snapped_mesh != null && snapped_mesh.material_override != null):
		snapped_mesh.material_override = snapped_mesh.material_override.duplicate(true)


	if(primary_mesh != null && primary_mesh.material_override != null):
		primary_mesh.material_override.set_shader_param('mix_color', snap_circle_color)
		primary_mesh.material_override = primary_mesh.material_override.duplicate(true)
		primary_mesh.visible = false
	if(secondary_mesh != null && secondary_mesh.material_override != null):
		secondary_mesh.material_override.set_shader_param('mix_color', snap_circle_color)
		secondary_mesh.material_override = secondary_mesh.material_override.duplicate(true)
		secondary_mesh.visible = false
	
	# Saracen: hide meshes if not in XR mode
	_update_visibility()
	
	return

func _exit_tree() -> void:
	tracker.laser_origin.remove_child(straight_mesh)
	tracker.laser_origin.remove_child(snapped_mesh)
