extends XRToolsPickable

# Movement speed when trigger is held
@export var movement_speed: float = 2.0
@export var motor_sound: AudioStream

# Is the scooter currently held
var holding_controller: XRController3D = null

# Reference to XROrigin3D
var xr_origin: XROrigin3D = null

# Audio player for motor sound
var audio_player: AudioStreamPlayer = null
var is_moving: bool = false

func _ready():
	super._ready()
	
	# Find XROrigin
	xr_origin = get_tree().get_first_node_in_group("XROrigin3D")
	if not xr_origin:
		xr_origin = _find_xr_origin(get_tree().root)
	
	# Create audio player for motor sound (using regular AudioStreamPlayer for debugging)
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.stream = motor_sound
	audio_player.bus = "Master"
	audio_player.volume_db = 0.0
	print("Audio player created with stream: ", motor_sound)
	
	# Connect to pickup signals
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)

func _find_xr_origin(node: Node) -> XROrigin3D:
	if node is XROrigin3D:
		return node
	for child in node.get_children():
		var result = _find_xr_origin(child)
		if result:
			return result
	return null

func _physics_process(delta):
	if not is_picked_up():
		# Stop sound if not picked up
		if audio_player and audio_player.playing:
			audio_player.stop()
		is_moving = false
		return
	
	# Check if ANY controller's trigger is pressed
	var should_move = false
	
	# Check primary hand
	if _grab_driver and _grab_driver.primary and _grab_driver.primary.controller:
		var controller = _grab_driver.primary.controller
		if controller.is_button_pressed("trigger_click") or controller.get_float("trigger") > 0.5:
			should_move = true
	
	# Check secondary hand
	if not should_move and _grab_driver and _grab_driver.secondary and _grab_driver.secondary.controller:
		var controller = _grab_driver.secondary.controller
		if controller.is_button_pressed("trigger_click") or controller.get_float("trigger") > 0.5:
			should_move = true
	
	if should_move:
		# Start motor sound if not already playing
		if audio_player:
			if not audio_player.playing:
				print("Starting motor sound")
				audio_player.play()
			else:
				print("Motor already playing")
		else:
			print("No audio player!")
		is_moving = true
		move_player(delta)
	else:
		# Stop motor sound when not moving
		if audio_player and audio_player.playing:
			audio_player.stop()
		is_moving = false

func move_player(delta: float):
	if not xr_origin:
		return
	
	# Get forward direction of scooter
	var forward = -global_transform.basis.z
	var movement = forward * movement_speed * delta
	xr_origin.global_position += movement
	
	# Add haptic feedback to both hands while moving
	if _grab_driver:
		if _grab_driver.primary and _grab_driver.primary.controller:
			_grab_driver.primary.controller.trigger_haptic_pulse("haptic", 0, 0.3, 0.1, 0)
		if _grab_driver.secondary and _grab_driver.secondary.controller:
			_grab_driver.secondary.controller.trigger_haptic_pulse("haptic", 0, 0.3, 0.1, 0)

func _on_picked_up(what):
	# Find which hand is holding us
	var picker = get_picked_up_by()
	if picker and picker.get_parent() is XRController3D:
		holding_controller = picker.get_parent()

func _on_dropped(what):
	holding_controller = null
	# Stop motor sound
	if audio_player and audio_player.playing:
		audio_player.stop()
	is_moving = false
	# Stop it from flying away
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	# Briefly disable collision with player to prevent teleporting
	collision_layer = 0
	await get_tree().create_timer(0.2).timeout
	collision_layer = 4  # Re-enable collision on layer 4
