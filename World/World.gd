extends Node2D

const Coin = preload("res://Items/Coin.tscn")


func _ready():
	"""
	1-bit game. Set background to be always black
	"""
	VisualServer.set_default_clear_color(Color.black)


func _physics_process(delta):
	if Input.is_action_just_pressed("create"):
		Utils.instance_scene_on_main(Coin, get_local_mouse_position())
