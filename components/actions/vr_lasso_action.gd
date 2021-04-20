extends "vr_action.gd"
export (Color) var straight_color = Color(247.0/255.0, 247.0/255.0, 1.0, 0.0)
export (Color) var unsnapped_color = Color(247.0/255.0, 247.0/255.0, 1.0, 0.1)
export (Color) var snapped_color = Color(254.0/255.0, 95.0/255.0, 85.0/255.0, 1.0)
export (Color) var snap_circle_color = Color(1.0, 1.0, 1.0, 1.0)
export (float) var snap_circle_min_alpha = 0.0
export(NodePath) var straight_laser;
export(NodePath) var snapped_laser;
export(NodePath) var primary_circle;
export(NodePath) var secondary_circle;
export var min_snap = 0.5;
export var snap_increase = 2;
# This node will be a child of a controller, add any input or display functionality here.
var current_snap: Spatial = null
var straight_mesh: MeshInstance = null;
var snapped_mesh: MeshInstance = null;
var primary_mesh: MeshInstance = null;
var secondary_mesh: MeshInstance = null;
var redirection_lock: bool = false;
var redirection_ready: bool = true;
var vr_origin_spatial: Spatial = null;

var print_mod = 0

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

func _process(_delta: float) -> void:
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
		var lasso_redirect_value: Vector2 = get_analog("/locomotion/turning")
		# LogManager.printl(str(lasso_redirect_value))
		var snapping_singleton = get_node("/root/SnappingSingleton")
		var points: Array = snapping_singleton.snapping_points
		var snap_point = null
		var redirecting: bool = redirection_ready && lasso_redirect_value.length_squared() > 0
		#you have to reset your joystick to the center to be able to redirect the lasso again
		redirection_ready = lasso_redirect_value.length_squared() <= 0;
		if(redirecting && current_snap != null):
			redirection_lock = true
			var shortest_dist = INF
			#we calculate the shortest distance to hit a point's voronoi cell (if it were projected on the unit sphere) while traveling along the redirection vector
			for point in points:
				if(point == current_snap):
					continue
				#var redirect_basis: Basis = snapping_singleton.calc_redirection_basis(self.global_transform.origin, current_snap.global_transform.origin)
				#var new_dist = snapping_singleton.calc_redirection_dist(point.global_transform.origin, self.global_transform.origin, current_snap.global_transform.origin, redirect_basis, lasso_redirect_value)
				var redirect_basis: Basis = snapping_singleton.calc_redirection_basis(vr_origin_spatial.global_transform.xform(ARVRServer.get_hmd_transform().origin), current_snap.global_transform.origin)
				var new_dist = snapping_singleton.calc_redirection_dist(point.global_transform.origin, vr_origin_spatial.global_transform.xform(ARVRServer.get_hmd_transform().origin), current_snap.global_transform.origin, redirect_basis, lasso_redirect_value)
				if(new_dist < shortest_dist):
					shortest_dist = new_dist
					snap_point = point
					primary_power = 1.0
					secondary_power = 0.0

		else:
			var highest_power: float = min_snap;
			for point in points:
				if (point == null || !point.snapping_enabled || !point.visible):
					continue
				var new_power = snapping_singleton.calc_snapping_power_sphere(point.global_transform.origin, point.size, point.snapping_power, self.global_transform)
				if(point == current_snap):
					if (((lasso && point.lock_snap_on_trigger) || redirection_lock)):
						highest_power = new_power
						snap_point = point
						primary_snap = point.global_transform.origin
						primary_power = highest_power
						secondary_power = 0.0
						break
					else:
						new_power += pow(lasso_analog_value.x, 2) * snap_increase * new_power
				if(new_power > highest_power):
					highest_power = new_power
					snap_point = point
					secondary_snap = primary_snap
					secondary_power = primary_power
					primary_snap = point.global_transform.origin
					primary_power = highest_power
				elif(new_power > secondary_power):
					secondary_snap = point.global_transform.origin
					secondary_power = new_power

		if(current_snap != snap_point):
			new_snap = true
			if(current_snap != null):
				current_snap.stop_snap_hover()
			current_snap = snap_point
			if(current_snap != null):
				#HERE IS THE SNAP
				#do haptics here
				current_snap.call_snap_hover();
	else:
		if(current_snap != null):
			current_snap.stop_snap_hover()
		current_snap = null
		redirection_ready = false
	
	if(current_snap != null):
		if(lasso):
			current_snap.call_snap_interact(self);
		else:
			current_snap.stop_snap_interact();
		
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
					primary_mesh.global_transform.origin = primary_snap;
			if(secondary_mesh != null):
				secondary_mesh.visible = secondary_power > 0
				if(secondary_power > 0):
					if(secondary_mesh.material_override != null):
						secondary_mesh.material_override.set_shader_param('mix_color', secondary_color)
					secondary_mesh.global_transform.origin = secondary_snap;

			if(lasso):
				snapped_mesh.material_override.set_shader_param('speed', -10.0)
			else:
				snapped_mesh.material_override.set_shader_param('speed', 0.0)

			if(lasso_analog_value.x <= 0):
				if(snapped_mesh.visible):
					snapped_mesh.material_override.set_shader_param('mix_color', unsnapped_color);
				straight_mesh.visible = false;
				snapped_mesh.visible = false;
			else:
				straight_mesh.visible = true;
				snapped_mesh.visible = true;
				if(current_snap != null):
					if(new_snap):
						snapped_mesh.material_override.set_shader_param('mix_color', snapped_color);
					var target_local = global_transform.xform_inv(current_snap.global_transform.origin);
					straight_mesh.material_override.set_shader_param('target', Vector3(0.0, 0.0, -target_local.length()));
					snapped_mesh.material_override.set_shader_param('target', target_local);
				else:
					if(new_snap):
						snapped_mesh.material_override.set_shader_param('mix_color', unsnapped_color);
					var into_infinity = Vector3(0.0, 0.0, -10)
					straight_mesh.material_override.set_shader_param('target', Vector3(0.0, 0.0, 0.0));
					snapped_mesh.material_override.set_shader_param('target', into_infinity);
		else:
			straight_mesh.visible = false;
			snapped_mesh.visible = false;

	# print_mod += 1
	# if(print_mod % 30 == 0 && lasso_analog_value.x > 0):
	# 	LogManager.printl("lasso frame microseconds: " + str(OS.get_ticks_usec() - start_time))
	return


func _ready() -> void:
	straight_mesh = get_node(straight_laser) as MeshInstance;
	snapped_mesh = get_node(snapped_laser) as MeshInstance;
	primary_mesh = get_node(primary_circle) as MeshInstance;
	secondary_mesh = get_node(secondary_circle) as MeshInstance;
	if(straight_mesh != null && straight_mesh.material_override != null):
		straight_mesh.material_override.set_shader_param('mix_color', straight_color);
		straight_mesh.material_override = straight_mesh.material_override.duplicate(true)
	if(snapped_mesh != null && snapped_mesh.material_override != null):
		snapped_mesh.material_override = snapped_mesh.material_override.duplicate(true)


	if(primary_mesh != null && primary_mesh.material_override != null):
		primary_mesh.material_override.set_shader_param('mix_color', snap_circle_color);
		primary_mesh.material_override = primary_mesh.material_override.duplicate(true)
		primary_mesh.visible = false;
	if(secondary_mesh != null && secondary_mesh.material_override != null):
		secondary_mesh.material_override.set_shader_param('mix_color', snap_circle_color);
		secondary_mesh.material_override = secondary_mesh.material_override.duplicate(true)
		secondary_mesh.visible = false;
	return
