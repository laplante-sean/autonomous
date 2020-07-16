extends Camera2D

var shake = 0

onready var shakeTimer = $ShakeTimer


func _ready():
	Events.connect("add_camera_shake", self, "_on_Events_add_camera_shake")


func _physics_process(delta):
	if shake != 0:
		offset_h = rand_range(-shake, shake)
		offset_v = rand_range(-shake, shake)


func camera_shake(amount, duration):
	shake = amount
	shakeTimer.wait_time = duration
	shakeTimer.start()


func _on_Events_add_camera_shake(amount, duration):
	camera_shake(amount, duration)


func _on_ShakeTimer_timeout():
	shake = 0
