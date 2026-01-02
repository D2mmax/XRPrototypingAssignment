extends Node3D

# Boundary limits
@export var min_bounds: Vector3 = Vector3(-9, -0.5, -9)
@export var max_bounds: Vector3 = Vector3(9, 4.5, 9)

var xr_origin: XROrigin3D = null

func _ready():
	xr_origin = get_parent() as XROrigin3D

func _physics_process(_delta):
	if not xr_origin:
		return
	
	# Clamp player position within bounds
	var pos = xr_origin.global_position
	pos.x = clamp(pos.x, min_bounds.x, max_bounds.x)
	pos.y = clamp(pos.y, min_bounds.y, max_bounds.y)
	pos.z = clamp(pos.z, min_bounds.z, max_bounds.z)
	xr_origin.global_position = pos
