extends "vr_action.gd"

export var enabled = true setget set_enabled, get_enabled

const AXIS_MAXIMUM = 0.5

export (Color) var can_teleport_color = Color(0.0, 1.0, 0.0, 1.0)
export (Color) var cant_teleport_color = Color(1.0, 0.0, 0.0, 1.0)
export (Color) var no_collision_color = Color(45.0 / 255.0, 80.0 / 255.0, 220.0 / 255.0, 1.0)
export var player_height = 1.8 setget set_player_height, get_player_height
export var player_radius = 0.4 setget set_player_radius, get_player_radius
export var strength = 2.5
export (int) var collision_mask = 1
export (float) var margin = 0.001

export (NodePath) var camera = null

onready var ws = ARVRServer.world_scale
var origin_node = null
var camera_node = null
var is_on_floor = true
var is_teleporting = false
var teleport_rotation = 0.0
var floor_normal = Vector3(0.0, 1.0, 0.0)
var last_target_transform = Transform()
var collision_shape = null
var step_size = 0.5

var locomotion: Spatial = null

onready var capsule = get_node("Target/Player_figure/Capsule")

#############
# Callbacks #
#############
var can_teleport_funcref:FuncRef = FuncRef.new()

func set_can_teleport_funcref(p_instance: Object, p_function : String) -> void:
	can_teleport_funcref = funcref(p_instance, p_function)
	
signal teleported(p_transform)

func set_enabled(new_value):
	enabled = new_value
	if enabled:
		set_physics_process(true)
	else:
		pass


func get_enabled():
	return enabled


func get_player_height():
	return player_height


func set_player_height(p_height):
	player_height = p_height

	if collision_shape:
		collision_shape.height = player_height - (2.0 * player_radius)

	if capsule:
		capsule.mesh.mid_height = player_height - (2.0 * player_radius)
		capsule.translation = Vector3(0.0, player_height / 2.0, 0.0)


func get_player_radius():
	return player_radius


func set_player_radius(p_radius):
	player_radius = p_radius

	if collision_shape:
		collision_shape.height = player_height - (2.0 * player_radius)
		collision_shape.radius = player_radius

	if capsule:
		capsule.mesh.mid_height = player_height - (2.0 * player_radius)
		capsule.mesh.radius = player_radius


func _ready():
	origin_node = find_parent_controller().get_node("..")

	$Teleport.visible = false
	$Target.visible = false

	$Teleport.mesh.size = Vector2(0.05 * ws, 1.0)
	$Target.mesh.size = Vector2(ws, ws)
	$Target/Player_figure.scale = Vector3(ws, ws, ws)

	if camera:
		camera_node = get_node(camera)
	else:
		camera_node = origin_node.get_node('ARVRCamera')

	collision_shape = CapsuleShape.new()

	set_player_height(player_height)
	set_player_radius(player_radius)
	
	locomotion = VRManager.xr_origin.get_component_by_name("LocomotionComponent")


func _process(_delta):
	var controller = find_parent_controller()

	if ! origin_node:
		return

	if ! camera_node:
		return

	var can_teleport: bool = false
	if can_teleport_funcref.is_valid():
		can_teleport = can_teleport_funcref.call_func()
	

	var new_ws = ARVRServer.world_scale
	if ws != new_ws:
		ws = new_ws
		$Teleport.mesh.size = Vector2(0.05 * ws, 1.0)
		$Target.mesh.size = Vector2(ws, ws)
		$Target/Player_figure.scale = Vector3(ws, ws, ws)

	if ! enabled or ! can_teleport:
		is_teleporting = false
		$Teleport.visible = false
		$Target.visible = false

		set_physics_process(false)
		return

	if ! locomotion:
		return

	var teleport_pressed: bool = controller.is_pressed("/locomotion/teleport")
	
	if (
		controller
		and locomotion.movement_controller == controller
		and VRManager.vr_user_preferences.movement_type ==\
		VRManager.vr_user_preferences.movement_type_enum.MOVEMENT_TYPE_TELEPORT
		and teleport_pressed
	):
		if ! is_teleporting:
			is_teleporting = true
			$Teleport.visible = true
			$Target.visible = true
			teleport_rotation = 0.0

		var space = get_world().space
		var state = PhysicsServer.space_get_direct_state(space)
		var query = PhysicsShapeQueryParameters.new()

		query.collision_mask = collision_mask
		query.margin = margin
		query.shape_rid = collision_shape.get_rid()

		var shape_transform = Transform(
			Basis(Vector3(1.0, 0.0, 0.0), PI * 0.5), Vector3(0.0, player_height / 2.0, 0.0)
		)

		var teleport_global_transform = $Teleport.global_transform
		var target_global_origin = teleport_global_transform.origin
		var down = Vector3(0.0, -1.0 / ws, 0.0)

		var cast_length = 0.0
		var fine_tune = 1.0
		var hit_something = false
		for _i in range(1, 26):
			var new_cast_length = cast_length + (step_size / fine_tune)
			var global_target = Vector3(0.0, 0.0, -new_cast_length)

			var t = global_target.z / strength
			var t2 = t * t

			global_target = teleport_global_transform.xform(global_target)

			global_target += down * t2

			query.transform = Transform(Basis(), global_target) * shape_transform
			var cast_result = state.collide_shape(query, 10)
			if cast_result.empty():
				cast_length = new_cast_length
				target_global_origin = global_target
			elif fine_tune <= 16.0:
				fine_tune *= 2.0
			else:
				var collided_at = target_global_origin
				if global_target.y > target_global_origin.y:
					is_on_floor = false
				else:
					var up = Vector3(0.0, 1.0, 0.0)
					var end_pos = target_global_origin - (up * 0.1)
					var intersects = state.intersect_ray(target_global_origin, end_pos)
					if intersects.empty():
						is_on_floor = false
					else:
						floor_normal = intersects["normal"]
						var dot = floor_normal.dot(up)
						if dot > 0.9:
							is_on_floor = true
						else:
							is_on_floor = false

						collided_at = intersects["position"]

				cast_length += (collided_at - target_global_origin).length()
				target_global_origin = collided_at
				hit_something = true
				break

		$Teleport.get_surface_material(0).set_shader_param("scale_t", 1.0 / strength)
		$Teleport.get_surface_material(0).set_shader_param("ws", ws)
		$Teleport.get_surface_material(0).set_shader_param("length", cast_length)
		if hit_something:
			var color = can_teleport_color
			var normal = Vector3(0.0, 1.0, 0.0)
			if is_on_floor:
				# if we're on the floor we'll reorientate our target to match.
				normal = floor_normal
				can_teleport = true
			else:
				can_teleport = false
				color = cant_teleport_color

			#teleport_rotation += (p_delta * controller.get_joystick_axis(0) * -4.0)

			var target_basis = Basis()
			target_basis.z = Vector3(teleport_global_transform.basis.z.x, 0.0, teleport_global_transform.basis.z.z).normalized()
			target_basis.y = normal
			target_basis.x = target_basis.y.cross(target_basis.z)
			target_basis.z = target_basis.x.cross(target_basis.y)

			target_basis = target_basis.rotated(normal, teleport_rotation)
			last_target_transform.basis = target_basis
			last_target_transform.origin = target_global_origin + Vector3(0.0, 0.02, 0.0)
			$Target.global_transform = last_target_transform

			$Teleport.get_surface_material(0).set_shader_param("mix_color", color)
			$Target.get_surface_material(0).albedo_color = color
			$Target.visible = can_teleport
		else:
			can_teleport = false
			$Target.visible = false
			$Teleport.get_surface_material(0).set_shader_param("mix_color", no_collision_color)
	elif is_teleporting:
		if can_teleport:
			var new_transform = last_target_transform
			new_transform.basis.y = Vector3(0.0, 1.0, 0.0)
			new_transform.basis.x = new_transform.basis.y.cross(new_transform.basis.z).normalized()
			new_transform.basis.z = new_transform.basis.x.cross(new_transform.basis.y).normalized()

			var cam_transform = camera_node.transform
			var user_feet_transform = Transform()
			user_feet_transform.origin = cam_transform.origin
			user_feet_transform.origin.y = 0  # the feet are on the ground, but have the same X,Z as the camera

			user_feet_transform.basis.y = Vector3(0.0, 1.0, 0.0)
			user_feet_transform.basis.x = user_feet_transform.basis.y.cross(cam_transform.basis.z).normalized()
			user_feet_transform.basis.z = user_feet_transform.basis.x.cross(user_feet_transform.basis.y).normalized()

			emit_signal("teleported", new_transform * user_feet_transform.inverse())

		is_teleporting = false
		$Teleport.visible = false
		$Target.visible = false
