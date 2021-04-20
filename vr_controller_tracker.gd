extends ARVRController

const vr_constants_const = preload("res://addons/sar1_vr_manager/vr_constants.gd")

const vr_manager_const = preload("vr_manager.gd")
const vr_render_tree_const = preload("vr_render_tree.gd")

var component_action: Array = []

var laser_origin: Spatial
var model_origin: Spatial

var world_scale: float = 1.0

var get_is_action_pressed_funcref: FuncRef = null
var get_analog_funcref: FuncRef = null

signal action_pressed(p_action)
signal action_released(p_action)

func is_pressed(p_action: String) -> bool:
	if get_is_action_pressed_funcref and get_is_action_pressed_funcref.is_valid():
		return get_is_action_pressed_funcref.call_func(p_action)

	return false


func get_analog(p_action: String) -> Vector2:
	if get_analog_funcref and get_analog_funcref.is_valid():
		return get_analog_funcref.call_func(p_action)

	return Vector2()


# Get the enum value from the vr_constants file based on the internal hand ID of the tracker
func get_hand_id_for_tracker() -> int:
	match get_hand():
		ARVRPositionalTracker.TRACKER_LEFT_HAND:
			return vr_constants_const.LEFT_HAND
		ARVRPositionalTracker.TRACKER_RIGHT_HAND:
			return vr_constants_const.RIGHT_HAND
		_:
			return vr_constants_const.UNKNOWN_HAND


func apply_world_scale():
	pass


func _on_action_pressed(p_action: String) -> void:
	match p_action:
		"/menu/menu_toggle":
			var a: InputEventAction = InputEventAction.new()
			a.action = "ui_menu"
			a.pressed = true 
			Input.parse_input_event(a)
	emit_signal("action_pressed", p_action)


func _on_action_released(p_action: String) -> void:
	match p_action:
		"/menu/menu_toggle":
			var a: InputEventAction = InputEventAction.new()
			a.action = "ui_menu"
			a.pressed = false
			Input.parse_input_event(a)

	emit_signal("action_released", p_action)


func add_component_action(p_component_action: Node) -> void:
	if component_action.has(p_component_action):
		printerr("Attempted to add duplicate module tracker!")
		return
		
	component_action.push_back(p_component_action)
	
	add_child(p_component_action)


func remove_component_action(p_component_action: Node) -> void:
	var index: int = component_action.find(p_component_action)
	if index != -1:
		component_action.remove(index)
	else:
		printerr("Attempted to remove invalid module tracker!")
		
	remove_child(p_component_action)


func _process(_delta: float) -> void:
	apply_world_scale()
	if ! get_is_active():
		visible = false


func _ready() -> void:
	pass
