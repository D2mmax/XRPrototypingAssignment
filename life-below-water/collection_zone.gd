extends Area3D

# Signal emitted when trash is collected
signal trash_collected(item)

# Counter for collected trash
var trash_count: int = 0

# Track items currently in zone (for haptic feedback)
var items_in_zone: Array = []

func _ready():
	# MAKE IT VISIBLE
	var visual = get_node_or_null("VisualMesh")
	if visual:
		visual.visible = true
	
	# Connect to area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	print("Collection zone ready at position: ", global_position)

func _on_body_entered(body: Node3D):
	print("!!! BODY ENTERED ZONE: ", body.name, " at position: ", body.global_position)
	
	# Ignore the scooter
	if "Seascooter" in body.name or "scooter" in body.name.to_lower():
		print("  -> Ignored (scooter)")
		return
	
	# Check if it's a pickable item
	if body is XRToolsPickable:
		print("  -> BOTTLE IN ZONE! Is held: ", body.is_picked_up())
		# Add to tracking
		if not items_in_zone.has(body):
			items_in_zone.append(body)
			print("  -> TRIGGERING HAPTIC FEEDBACK NOW")
			# Trigger haptic pulse IMMEDIATELY
			trigger_enter_haptic()

func _on_body_exited(body: Node3D):
	print("Body exited zone: ", body.name)
	if items_in_zone.has(body):
		items_in_zone.erase(body)

func _physics_process(_delta):
	# Check if any bottles in the zone are released (no longer held)
	for item in items_in_zone:
		if item and is_instance_valid(item):
			if item is XRToolsPickable and not item.is_picked_up():
				print("!!! COLLECTING BOTTLE NOW !!!")
				collect_trash(item)
				items_in_zone.erase(item)
				break

func trigger_enter_haptic():
	print("Executing haptic feedback...")
	var xr_origin = get_tree().get_first_node_in_group("XROrigin3D")
	if not xr_origin:
		print("  ERROR: No XROrigin found!")
		return
	
	var found_controller = false
	for child in xr_origin.get_children():
		if child is XRController3D:
			print("  -> Pulsing controller: ", child.name)
			child.trigger_haptic_pulse("haptic", 0, 1.0, 0.3, 0)  # STRONG pulse
			found_controller = true
	
	if not found_controller:
		print("  ERROR: No controllers found!")

func collect_trash(item: XRToolsPickable):
	trash_count += 1
	print("=== TRASH COLLECTED! Total: ", trash_count, " ===")
	
	trash_collected.emit(item)
	
	# VERY Strong haptic feedback on collection
	var xr_origin = get_tree().get_first_node_in_group("XROrigin3D")
	if xr_origin:
		for child in xr_origin.get_children():
			if child is XRController3D:
				child.trigger_haptic_pulse("haptic", 0, 1.0, 0.5, 0)
	
	item.queue_free()
