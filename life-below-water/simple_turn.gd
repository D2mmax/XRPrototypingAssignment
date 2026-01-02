extends Node3D

@export var turn_speed: float = 90.0  # degrees per second
@export var deadzone: float = 0.2

var xr_origin: XROrigin3D = null
var controller: XRController3D = null

func _ready():
	# Get the controller this is attached to
	controller = get_parent() as XRController3D
	
	# Find XROrigin
	xr_origin = get_tree().get_first_node_in_group("XROrigin3D")

func _physics_process(delta):
	if not controller or not xr_origin:
		return
	
	if not controller.get_is_active():
		return
	
	# Get right joystick X axis (left/right)
	var joystick = controller.get_vector2("primary")
	var turn_input = joystick.x
	
	# Apply deadzone
	if abs(turn_input) < deadzone:
		return
	
	# Rotate the XROrigin around Y axis (negative to flip direction)
	var rotation_amount = deg_to_rad(-turn_speed * delta * turn_input)
	xr_origin.rotate_y(rotation_amount)
