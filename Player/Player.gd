extends KinematicBody2D
class_name Player

signal died

export(bool) var HUMAN_CONTROL = false  # Used for testing
export(int) var ACCELERATION = 500
export(int) var MAX_SPEED = 65
export(float) var FRICTION = 0.25
export(int) var GRAVITY = 200
export(int) var JUMP_FORCE = 120
export(int) var MAX_SLOPE_ANGLE = 46

enum PlayerState {
	HUMAN_CONTROL,
	MOVE,
	WANDER
}

var state = PlayerState.WANDER
var snap_vector = Vector2.ZERO
var just_jumped = false
var double_jump = true
var motion = Vector2.ZERO
var input_vector = Vector2.ZERO
var current_animation = "Idle"
var interesting_objects = []

onready var coyoteJumpTimer = $CoyoteJumpTimer
onready var directionSwitchTimer = $DirectionSwitchTimer
onready var jumpTimer = $JumpTimer
onready var collider = $Collider
onready var animationPlayer = $AnimationPlayer
onready var sprite = $Sprite
onready var cameraFollow = $CameraFollow


func _ready():
	if HUMAN_CONTROL:
		state = PlayerState.HUMAN_CONTROL
	else:
		directionSwitchTimer.start()
		jumpTimer.start()


func _physics_process(delta):
	match state:
		PlayerState.HUMAN_CONTROL:
			# When debugging we can enable human controls
			get_input_vector()
			apply_horizontal_force(delta)
			jump_check()
			apply_gravity(delta)
			update_animations()
			move()
		PlayerState.MOVE:
			# This will be the computer's state when it's moving towards something it wants
			var should_jump = get_input_vector_towards_object()
			apply_horizontal_force(delta)
			if should_jump:
				jump_towards_object()
			apply_gravity(delta)
			update_animations()
			move()
		PlayerState.WANDER:
			# This is the computer's state when it's moving randomly
			get_random_input_vector()
			apply_horizontal_force(delta)
			random_jump_check()
			apply_gravity(delta)
			update_animations()
			move()


func die():
	"""
	Called if we die
	"""
	emit_signal("died")


func get_input_vector():
	"""
	Get the current input vector (left or right) for movement
	"""
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")


func get_random_input_vector():
	"""
	Get a random input vector for our WANDER state
	
	:returns: The input vector
	"""
	var options = [-1, 0, 1]
	options.shuffle()

	if directionSwitchTimer.time_left == 0 or is_on_wall():
		directionSwitchTimer.start()
		input_vector.x = options[0]


func get_input_vector_towards_object():
	"""
	Get the input vector that moves us toward the
	closest object. The closest object will be first
	in our interesting objects list
	
	:returns: true if a jump should be performed as well, false if not
	"""
	if len(interesting_objects) == 0:
		input_vector = Vector2.ZERO
		state = PlayerState.WANDER
		return
	
	var target = interesting_objects[0]
	var direction = global_position.direction_to(target.global_position).normalized()
	print(direction.y)
	var should_jump = round(direction.y) != 0 and sign(direction.y) == -1
	input_vector.x = round(direction.x)

	return should_jump


func jump_towards_object():
	"""
	Perform a jump towards an object (handles double jump too)
	"""
	if is_on_floor() or coyoteJumpTimer.time_left > 0:
		jump(JUMP_FORCE)
		just_jumped = true
	else:
		# TODO: Make computer double-jump better
		# this basically makes it so the computer can fly
		if double_jump == true:
			jump(JUMP_FORCE * 0.75)


func apply_horizontal_force(delta):
	"""
	Based on the input vector and delta, apply horizontal motion

	:param delta: The current delta from _physics_process
	"""
	# Apply movement
	if input_vector.x != 0:
		motion.x += input_vector.x * ACCELERATION * delta
		motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED)

	# If not moving, apply friction
	if input_vector.x == 0 and is_on_floor():
		motion.x = lerp(motion.x, 0, FRICTION)

	# Update the snap vector if we're on the floor
	if is_on_floor():
		snap_vector = Vector2.DOWN


func jump_check():
	"""
	Check if we're jumping or not. This method will adjust
	our motion directly.
	"""
	if is_on_floor() or coyoteJumpTimer.time_left > 0:
		if Input.is_action_just_pressed("jump"):
			jump(JUMP_FORCE)
			just_jumped = true
	else:
		if Input.is_action_just_released("jump") and motion.y < -JUMP_FORCE / 2:
			motion.y = -JUMP_FORCE / 2

		if Input.is_action_just_pressed("jump") and double_jump == true:
			# Handle double jump
			jump(JUMP_FORCE * 0.75)
			double_jump = false


func random_jump_check():
	"""
	Randomly decide if we should jump around
	"""
	var options = [false, true]
	options.shuffle()
	var should_jump = options[0]
	
	if jumpTimer.time_left > 0:
		return  # Don't bother

	jumpTimer.start()

	if is_on_floor() or coyoteJumpTimer.time_left > 0:
		if should_jump:
			jump(JUMP_FORCE)
			just_jumped = true
	else:
		if should_jump and double_jump == true:
			jump(JUMP_FORCE * 0.75)
			double_jump = false


func jump(force):
	"""
	Apply a force in the upward direction to make the player jump
	
	:param force: The jump force to apply
	"""
	motion.y = -force
	snap_vector = Vector2.ZERO


func apply_gravity(delta):
	"""
	Apply gravity to the player if we're in the air
	
	:param delta: The current delta from _physics_process
	"""
	if not is_on_floor():
		motion.y += GRAVITY * delta
		motion.y = min(motion.y, JUMP_FORCE)


func is_moving_up():
	"""
	:returns: True if moving up, False if not.
	"""
	return motion.y < 0


func is_moving_down():
	"""
	:returns: True if moving down, False if not.
	"""
	return motion.y > 0


func update_animations():
	"""
	Update our animations based on the input_vector
	"""
	if not is_zero_approx(motion.x):
		sprite.scale.x = sign(motion.x) 

	if input_vector.x != 0:
		current_animation = "Run"
	else:
		current_animation = "Idle"

	# Override run/idle if we're in the air
	if not is_on_floor() and is_moving_up() and abs(motion.x) >= 0.1:
		current_animation = "Jump"
	elif not is_on_floor() and is_moving_down() and abs(motion.x) >= 0.1:
		current_animation = "Fall"
	elif not is_on_floor() and is_moving_up():
		current_animation = "JumpIdle"
	elif not is_on_floor() and is_moving_down():
		current_animation = "FallIdle"

	animationPlayer.play(current_animation)


func move():
	"""
	Final step: Actually move the player
	"""
	# Capture properties of motion prior to moving
	# We use them after moving to fix some
	# move_and_slide_with_snap issues
	var was_in_air = not is_on_floor()
	var was_on_floor = is_on_floor()
	var last_motion = motion
	var last_position = position
	
	motion = move_and_slide_with_snap(motion, snap_vector * 4, Vector2.UP, true, 4, deg2rad(MAX_SLOPE_ANGLE))

	# Happens on landing
	if was_in_air and is_on_floor():
		# Fix for move_and_slide_with_snap causing us to 
		# lose momentum when landing on a slope
		motion.x = last_motion.x
		
		# On landing we get double jump back
		double_jump = true
		just_jumped = false

	# Just left the ground
	if was_on_floor and not is_on_floor() and not just_jumped:
		# Fix for little hop if you fall off a ledge after
		# climbing a slope
		motion.y = 0
		position.y = last_position.y
		coyoteJumpTimer.start()

	# Prevent sliding on slope when idle (hack)
	if is_on_floor() and get_floor_velocity().length() == 0 and abs(motion.x) < 1:
		# If we're on the floor, not on a moving platform, and our motion is super tiny...don't move
		position.x = last_position.x

	if state == PlayerState.MOVE and (is_on_ceiling() or is_on_wall()) and len(interesting_objects) > 0:
		# This means we're trying to get to an object but it
		# is probably on the other side of something. We're only
		# ever moving towards the closest object and that should be
		# the first one in our list. So remove it for now. Maybe 
		# we'll be in a better position to grab it next time it comes 
		# into view.
		interesting_objects.remove(0)


func sort_interesting(obj_a, obj_b):
	"""
	Called from sort_custom to determine which object is closer (a or b).
	
	:param obj_a: The first object to compare
	:param obj_b: The second object to compare
	:returns: true if A should come before B in a list, False otherwise.
	"""
	var a_dist = global_position.distance_to(obj_a.global_position)
	var b_dist = global_position.distance_to(obj_b.global_position)
	if a_dist < b_dist:
		return true  # A is closer than B, it should be first
	return false  # B should come before A


func _on_ObjectDetectionZone_object_detected(body):
	print("Found something interesting: ", body)
	state = PlayerState.MOVE
	interesting_objects.append(body)

	# Every time a new object is added, make sure the
	# closest object is first in the list
	interesting_objects.sort_custom(self, "sort_interesting")


func _on_ObjectDetectionZone_body_exited(body):
	print("Lost track of something interesting: ", body)
	var idx = interesting_objects.find(body)
	if idx != -1:
		interesting_objects.remove(idx)
		
	if len(interesting_objects) == 0:
		state = PlayerState.WANDER


func _on_CollectibleDetector_collect(value):
	print("Found a collectible worth: ", value)
	# TODO: Increment score or something



