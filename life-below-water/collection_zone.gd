extends Area3D

# Signal emitted when trash is collected
signal trash_collected(item)

# Counter for collected trash
var trash_count: int = 0

func _ready():
	# Connect to body entered signal
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	# Check if it's a pickable trash item
	if body is XRToolsPickable:
		# Make sure it's not being held
		if not body.is_picked_up():
			collect_trash(body)

func collect_trash(item: XRToolsPickable):
	# Increment counter
	trash_count += 1
	print("Trash collected! Total: ", trash_count)
	
	# Emit signal
	trash_collected.emit(item)
	
	# Remove the trash item
	item.queue_free()
