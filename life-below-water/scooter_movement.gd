extends RigidBody3D

# Movement speed when trigger is held
@export var movement_speed: float = 2.0

# Is the scooter currently picked up
var is_held: bool = false
var holding_controller: XRController3D = null

# Reference to XROrigin3D
var xr_origin: XROrigin3D = null

func _ready():
	# Find XROrigin
	xr_origin = get_tree().get_first_node_in_group("XROrigin3D")
	if not xr_origin:
		xr_origin = _find_xr_origin(get_tree().root)

func _find_xr_origin(node: Node) -> XROrigin3D:
	if node is XROrigin3D:
		return node
	for child in node.get_children():
		var result = _find_xr_origin(child)
		if result:
			return result
	return null

func _physics_process(delta):
	if not is_held or not holding_controller:
		return
	
	# Check if trigger is pressed
	if holding_controller.is_button_pressed("trigger_click") or holding_controller.get_float("trigger") > 0.5:
		move_player(delta)

func move_player(delta: float):
	if not xr_origin:
		return
	
	# Get forward direction of scooter
	var forward = -global_transform.basis.z
	var movement = forward * movement_speed * delta
	xr_origin.global_position += movement

# Called when picked up
func picked_up(by):
	is_held = true
	if by and by.get_parent() is XRController3D:
		holding_controller = by.get_parent()

# Called when dropped
func dropped():
	is_held = false
	holding_controller = null
