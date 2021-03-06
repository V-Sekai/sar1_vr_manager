extends "res://addons/vsk_entities/extensions/model_rigid_body.gd"

export var snapping_power: float = 1
export var snapping_enabled: bool = true setget set_snapping_enabled, get_snapping_enabled
export var size: float = 0.3 setget set_size, get_size
export var flick_parent_to_hand_on_snap_interact: bool = true 
export var flick_power: float = 1.0 setget set_power, get_power
export var lock_snap_on_trigger: bool = true
signal on_snap_hover
signal on_snap_hover_stop
signal on_snap_interact
signal on_snap_interact_stop

var snap_interacting = false setget , is_snap_interaction_active

var flick_target: Spatial = null

var lasso_point: LassoPoint = LassoPoint.new()

func set_power(p_power:float) -> void:
	lasso_point.set_snapping_power(p_power)
	
func get_power() -> float:
	return lasso_point.get_snapping_power()

func set_size(p_size:float) -> void:
	lasso_point.set_size(p_size)
	
func get_size() -> float:
	return lasso_point.get_size()
	
func set_snapping_enabled(p_enabled:bool) -> void:
	lasso_point.enable_snapping(p_enabled)
	
func get_snapping_enabled() -> bool:
	return lasso_point.get_snapping_enabled()
	


# var physics_script = preload("res://addons/vsk_entities/extensions/prop_simulation_logic.gd")

func _ready() -> void:
	#register self with all lassos
	register_snapping_point()

func _exit_tree():
	unregister_snapping_point()


func register_snapping_point() -> void:
	var snapping_singleton = get_node("/root/SnappingSingleton")
	lasso_point.register_point(snapping_singleton.snapping_points, self)
	
func unregister_snapping_point() -> void:
	lasso_point.unregister_point()

func call_snap_hover() -> void:
	emit_signal("on_snap_hover")

func call_snap_interact(p_flick_target: Spatial) -> void:
	if(flick_parent_to_hand_on_snap_interact):
		flick_target = p_flick_target
	if(!snap_interacting):
		emit_signal("on_snap_interact")
		snap_interacting = true
	if(sleeping):
		linear_velocity = calc_flick_velocity()

func stop_snap_hover() -> void:
	emit_signal("on_snap_hover_stop")
	snap_interacting = false

func stop_snap_interact() -> void:
	if(snap_interacting):
		emit_signal("on_snap_interact_stop")
		snap_interacting = false
		flick_target = null


func is_snap_interaction_active():
	return snap_interacting

func calc_flick_velocity() -> Vector3:
	if(flick_target != null):
		var flick_pos = flick_target.global_transform.origin
		var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
		var time = 1; #make it there in one second
		var vertical_diff = flick_pos.y - global_transform.origin.y;
		var horizontal_vector = Vector3(flick_pos.x, 0, flick_pos.z) - Vector3(global_transform.origin.x, 0, global_transform.origin.z);
		var additional_air_time = 0;
		var vertical_velocity = 0.0
		if gravity <= 0: #if the world makes no sense
			return Vector3(horizontal_vector.x, vertical_diff, horizontal_vector.z).normalized() * flick_power;
		if vertical_diff > 0:
			additional_air_time = pow(horizontal_vector.length()/(horizontal_vector.length() + vertical_diff), 4) * flick_power;
			var base_v_velocity = sqrt(2 * gravity * vertical_diff)
			vertical_velocity = base_v_velocity + (additional_air_time * gravity / 2)
			time = (base_v_velocity) / gravity + (additional_air_time)
		else:
			additional_air_time = pow(horizontal_vector.length()/(horizontal_vector.length() - vertical_diff), 4) / flick_power;
			vertical_velocity = (vertical_diff / gravity) + (vertical_diff / horizontal_vector.length()) + (additional_air_time * gravity / 2)
			time = (sqrt(abs(vertical_diff / gravity))) + additional_air_time / 1.5
		
		var horizontal_velocity = horizontal_vector.length() / time;
		horizontal_vector = horizontal_vector.normalized() * horizontal_velocity
		return Vector3(horizontal_vector.x, vertical_velocity, horizontal_vector.z);
	return Vector3()

func _integrate_forces(state: PhysicsDirectBodyState):
	#._integrate_forces(state)
	if (flick_parent_to_hand_on_snap_interact && snap_interacting):
		if(flick_target != null && flick_target.global_transform.origin.distance_to(global_transform.origin) > size + 0.001):
			state.linear_velocity = calc_flick_velocity()
		elif(flick_target != null):
			var vector_to_target = flick_target.global_transform.origin - global_transform.origin
			state.linear_velocity = vector_to_target * 10
