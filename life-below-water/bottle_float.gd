extends XRToolsPickable

var original_freeze_mode: int = 0

func _ready():
	super._ready()
	# Store original freeze mode
	original_freeze_mode = freeze_mode
	# Set to kinematic mode (freeze_mode = 1) so it's static but still detectable
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	
	# Connect pickup signals
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)

func _on_picked_up(_what):
	# Switch to dynamic when picked up
	freeze = false
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC

func _on_dropped(_what):
	# Back to kinematic when dropped
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	# Reset velocities
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
