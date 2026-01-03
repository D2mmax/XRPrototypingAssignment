extends Node3D

# Bottle scene to spawn
@export var bottle_scene: PackedScene

# Wave settings
@export var bottles_per_wave: int = 8  # How many bottles per wave
@export var collection_threshold: int = 6  # Spawn next wave when this many are collected
@export var min_spawn_height: float = 1.0  # Minimum spawn height
@export var max_spawn_height: float = 3.5  # Maximum spawn height
@export var spawn_radius: float = 8.0  # How far from center to spawn

var xr_origin: XROrigin3D = null
var collection_zone: Area3D = null
var current_wave_bottles: Array = []
var total_collected: int = 0
var wave_number: int = 0

func _ready():
	# Find XROrigin to spawn relative to player
	xr_origin = get_tree().get_first_node_in_group("XROrigin3D")
	
	# Find collection zone to track collected bottles
	if xr_origin:
		for child in xr_origin.get_children():
			if child.name == "CollectionZone":
				collection_zone = child
				collection_zone.trash_collected.connect(_on_trash_collected)
				break
	
	# Load bottle scene if not set
	if not bottle_scene:
		bottle_scene = load("res://plastic_bottle_pickable.tscn")
	
	# Spawn first wave
	spawn_wave()

func _process(_delta):
	# Clean up null references (bottles that were destroyed)
	current_wave_bottles = current_wave_bottles.filter(func(b): return is_instance_valid(b))
	
	# Check if we should spawn next wave
	if total_collected >= collection_threshold * (wave_number + 1):
		spawn_wave()

func spawn_wave():
	wave_number += 1
	print("Spawning wave ", wave_number, " - ", bottles_per_wave, " bottles")
	
	for i in range(bottles_per_wave):
		spawn_bottle()

func spawn_bottle():
	if not bottle_scene:
		return
	
	# Random position around player
	var angle = randf() * TAU  # Random angle
	var distance = randf_range(3.0, spawn_radius)  # Random distance
	var height = randf_range(min_spawn_height, max_spawn_height)  # Random height
	
	var spawn_pos = Vector3.ZERO
	if xr_origin:
		spawn_pos = xr_origin.global_position
	
	spawn_pos.x += cos(angle) * distance
	spawn_pos.y = height
	spawn_pos.z += sin(angle) * distance
	
	# Create bottle
	var bottle = bottle_scene.instantiate()
	get_parent().call_deferred("add_child", bottle)
	bottle.global_position = spawn_pos
	
	# Track this bottle
	current_wave_bottles.append(bottle)
	
	# Add gentle floating animation
	var floater = FloatingBottle.new()
	bottle.call_deferred("add_child", floater)

func _on_trash_collected(item):
	total_collected += 1
	print("Collected: ", total_collected, " / ", collection_threshold * (wave_number + 1))

# Inner class to add gentle bobbing motion
class FloatingBottle extends Node:
	var time: float = 0.0
	var bob_speed: float = 0.5
	var bob_amount: float = 0.15
	var initial_y: float = 0.0
	var is_active: bool = true
	
	func _ready():
		var parent_node = get_parent()
		if parent_node:
			initial_y = parent_node.global_position.y
			# Random starting offset so bottles don't all bob in sync
			time = randf() * TAU
			
			# Connect to pickup signals to stop bobbing when held
			if parent_node.has_signal("picked_up"):
				parent_node.picked_up.connect(_on_picked_up)
			if parent_node.has_signal("dropped"):
				parent_node.dropped.connect(_on_dropped)
	
	func _on_picked_up(_what):
		is_active = false
	
	func _on_dropped(_what):
		is_active = true
		# Update initial_y to current position
		var parent_node = get_parent()
		if parent_node:
			initial_y = parent_node.global_position.y
	
	func _physics_process(delta):
		if not is_active:
			return
			
		var parent_node = get_parent()
		if parent_node:
			time += delta * bob_speed
			# Gentle up/down bobbing motion
			var offset = sin(time) * bob_amount
			var pos = parent_node.global_position
			pos.y = initial_y + offset
			parent_node.global_position = pos
