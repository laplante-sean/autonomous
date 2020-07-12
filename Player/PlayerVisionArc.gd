extends Sprite

export(int) var VISION_RADIUS = 40


func _draw():
	#draw_circle(position, VISION_RADIUS, Color.white)
	draw_arc(
		position,        # Position to draw the arc
		VISION_RADIUS,   # The radius of the arc
		deg2rad(172),    # The starting angle for the arc
		deg2rad(368),    # The ending angle for the arc
		100,             # Number of points used when drawing the arc
		Color.white,     # Color of the arc
		1.0,             # Width of the arc line
		true             # Antialiasing
	)
