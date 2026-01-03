extends XRToolsPickable

func _ready():
	super._ready()
	# Connect pickup signals
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)

func _on_picked_up(_what):
	# Completely remove all physics restrictions when held
	lock_rotation = false
	linear_damp = 0.0
	angular_damp = 0.0
	# Make sure mass is reasonable
	mass = 0.1

func _on_dropped(_what):
	# Restore restrictions when dropped
	lock_rotation = true
	linear_damp = 20.0
	angular_damp = 20.0
	# Stop any movement immediately
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	# Reset collision to prevent interaction
	await get_tree().create_timer(0.1).timeout
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
