extends Node3D

func _ready():
	# Initialize OpenXR
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")
		
		var vp: Viewport = get_viewport()
		vp.use_xr = true
	else:
		print("OpenXR not initialized - running in desktop mode")
