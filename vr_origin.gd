extends XROrigin3D

const vr_controller_tracker_const = preload("res://addons/sar1_vr_manager/vr_controller_tracker.gd")

var active_controllers: Dictionary = {}
var unknown_controller_count: int = 0

var hand_controllers: Array = []
var left_hand_controller: XRController3D = null
var right_hand_controller: XRController3D = null

#############
# Component #
#############

const vr_component_locomotion_const = preload("components/vr_component_locomotion.gd")
const vr_component_ui_pointer_const = preload("components/vr_component_ui_pointer.gd")
const vr_component_interaction_const = preload("components/vr_component_interaction.gd")
const vr_component_teleport_const = preload("components/vr_component_teleport.gd")
const vr_component_render_tree_const = preload("components/vr_component_render_tree.gd")
const vr_component_advanced_movement_const = preload("components/vr_component_advanced_movement.gd")
const vr_component_lasso_const = preload("components/vr_component_lasso.gd")
const vr_component_hand_pose_const = preload("components/vr_component_hand_pose.gd")

var components: Array = []

signal tracker_added(p_spatial)
signal tracker_removed(p_spatial)

func clear_controllers() -> void:
	for tracker_id in active_controllers.keys():
		remove_tracker(tracker_id)
		
	assert(active_controllers == {})
	assert(unknown_controller_count == 0)
	
	assert(hand_controllers == [])
	assert(left_hand_controller == null)
	assert(right_hand_controller == null)

func add_tracker(p_tracker_id: int) -> void:
	var tracker: XRPositionalTracker = VRManager.xr_trackers[p_tracker_id]
	if tracker != null && tracker.get_type() == XRServer.TRACKER_CONTROLLER:
		var tracker_hand: int = tracker.get_hand()
		var controller = vr_controller_tracker_const.new()

		match tracker_hand:
			XRPositionalTracker.TRACKER_HAND_LEFT:
				controller.set_name("LeftController")
				controller.set_controller_id(XRPositionalTracker.TRACKER_HAND_LEFT)

				# Attempt to add left controller
				if left_hand_controller == null:
					left_hand_controller = controller
					hand_controllers.push_back(controller)
			XRPositionalTracker.TRACKER_HAND_RIGHT:
				controller.set_name("RightController")
				controller.set_controller_id(XRPositionalTracker.TRACKER_HAND_RIGHT)

				# Attempt to add right controller
				if right_hand_controller == null:
					right_hand_controller = controller
					hand_controllers.push_back(controller)
			XRPositionalTracker.TRACKER_HAND_UNKNOWN:
				controller.set_name("UnknownHandController")
				controller.set_controller_id(
					(XRPositionalTracker.TRACKER_HAND_RIGHT + 1) + unknown_controller_count
				)
				unknown_controller_count += 1
			_:
				pass

		VRManager.platform_add_controller(controller, self)

		for component in components:
			component.tracker_added(controller)

		if ! active_controllers.has(p_tracker_id):
			active_controllers[p_tracker_id] = controller
			add_child(controller)
			emit_signal("tracker_added", controller)
		else:
			controller.free()
			printerr("Attempted to add duplicate active tracker!")


func remove_tracker(p_tracker_id: int) -> void:
	if active_controllers.has(p_tracker_id):
		var controller: XRController3D = active_controllers[p_tracker_id] # vr_controller_tracker_const
		if active_controllers.erase(p_tracker_id):
			# Attempt to clear it from any hands it is assigned to
			if left_hand_controller == controller or right_hand_controller == controller:
				if left_hand_controller == controller:
					left_hand_controller = null
				if right_hand_controller == controller:
					right_hand_controller = null
				hand_controllers.remove(hand_controllers.find(controller))

			if VRManager.xr_trackers.has(p_tracker_id):
				var tracker: XRPositionalTracker = VRManager.xr_trackers[p_tracker_id]
				if tracker.get_hand() == XRPositionalTracker.TRACKER_HAND_UNKNOWN:
					unknown_controller_count -= 1

				VRManager.platform_remove_controller(controller, self)

				for component in components:
					component.tracker_removed(controller)

				emit_signal("tracker_removed", tracker)

			if controller.is_inside_tree():
				controller.queue_free()
				controller.get_parent().remove_child(controller)
			else:
				printerr("Tracker is not inside tree!")
		else:
			printerr("Attampted to erase invalid tracker!")
	else:
		printerr("Attempted to erase invalid active tracker!")


func _on_tracker_added(p_tracker_name: String, p_type: int, p_id: int) -> void:
	print(
		"Adding hand for tracker {tracker_name} type {tracker_type_name} id {id} to VR Player".format(
			{
				"tracker_name": p_tracker_name,
				"tracker_type_name": VRManager.get_tracker_type_name(p_type),
				"id": str(p_id)
			}
		)
	)
	add_tracker(p_id)


func _on_tracker_removed(p_tracker_name: String, p_type: int, p_id: int) -> void:
	print(
		"Removing hand for tracker {tracker_name} type {tracker_type_name} id {id} to VR Player".format(
			{
				"tracker_name": p_tracker_name,
				"tracker_type_name": VRManager.get_tracker_type_name(p_type),
				"id": str(p_id)
			}
		)
	)
	remove_tracker(p_id)

func create_and_add_component(p_component_script: Script) -> void:
	var vr_component: Node3D = p_component_script.new()
	components.push_back(vr_component)
	add_child(vr_component)

func create_components() -> void:
	create_and_add_component(vr_component_ui_pointer_const)
	create_and_add_component(vr_component_locomotion_const)
	create_and_add_component(vr_component_teleport_const)
	create_and_add_component(vr_component_render_tree_const)
	create_and_add_component(vr_component_advanced_movement_const)
	create_and_add_component(vr_component_lasso_const)
	create_and_add_component(vr_component_hand_pose_const)

func destroy_components() -> void:
	for component in components:
		component.queue_free()
		
	components = []
	
func get_component_by_name(p_name: String) -> Node:
	for component in components:
		if p_name == component.name:
			return component
			
	return null
	
func setup_components() -> void:
	for component in components:
		component.post_add_setup()
		
func _ready() -> void:
	set_process_internal(false)
		
func _exit_tree() -> void:
	if VRManager.xr_origin == self:
		VRManager.xr_origin = null
		
	destroy_components()
	clear_controllers()
	
	if VRManager.is_connected("tracker_added", self._on_tracker_added):
		VRManager.disconnect("tracker_added", self._on_tracker_added)
	else:
		printerr("tracker_added could not be disconnected")
	if VRManager.is_connected("tracker_removed", self._on_tracker_removed):
		VRManager.disconnect("tracker_removed", self._on_tracker_removed)
	else:
		printerr("tracker_removed could not be disconnected")
		
func _enter_tree() -> void:
	# Self-assign
	VRManager.assign_xr_origin(self)
	
	create_components()

	for key in VRManager.xr_trackers.keys():
		add_tracker(key)
		
	setup_components()

	if VRManager.connect("tracker_added", self._on_tracker_added) != OK:
		printerr("tracker_added could not be connected")
	if VRManager.connect("tracker_removed", self._on_tracker_removed) != OK:
		printerr("tracker_removed could not be connected")
