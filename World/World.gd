extends Node2D

const Coin = preload("res://Items/Coin.tscn")
const Player = preload("res://Player/Player.tscn")
const Level_00 = preload("res://Levels/Level_00.tscn")

export(String, FILE, "*.tscn") var start_level_path = ""
export(float) var CAMERA_ZOOM_STEP = 0.05
export(float) var MIN_ZOOM = 1
export(float) var MAX_ZOOM = 2

var MainInstances = Utils.get_MainInstances()
var currentLevel = null
var player = null
var currentLevelPath = "res://Levels/Level_00.tscn"

onready var camera = $Camera


func _ready():
	"""
	1-bit game. Set background to be always black
	"""
	VisualServer.set_default_clear_color(Color.black)
	Events.connect("next_level", self, "_on_Events_next_level")

	if MainInstances.is_load_game:
		var save_data = SaveAndLoad.load_data_from_file()
		currentLevelPath = save_data.level
		currentLevel = Utils.instance_scene_on_main(load(save_data.level))
	elif start_level_path:
		# If this is set, use it.
		currentLevelPath = start_level_path
		currentLevel = Utils.instance_scene_on_main(load(start_level_path))
	else:
		# If not we default to Level_00
		currentLevel = Utils.instance_scene_on_main(Level_00)
	
	if MainInstances.is_new_game:
		SaveAndLoad.save_data_to_file(SaveAndLoad.default_save_data)

	spawn()


func _physics_process(delta):
	if Input.is_action_just_pressed("create"):
		Utils.instance_scene_on_main(Coin, get_local_mouse_position())
	if Input.is_action_just_released("zoom_in"):
		zoom_in()
	if Input.is_action_just_released("zoom_out"):
		zoom_out()
	if Input.is_action_just_pressed("reset_camera"):
		reset_zoom()


func spawn():
	"""
	Spawn the player
	"""
	player = Utils.instance_scene_on_main(Player, currentLevel.get_spawn_point())
	player.connect("died", self, "_on_Player_died")
	player.cameraFollow.set_remote_node("../../Camera")


func update_save_data():
	var save_data = SaveAndLoad.load_data_from_file()
	save_data.level = currentLevelPath
	SaveAndLoad.save_data_to_file(save_data)


func zoom_in():
	zoom(-CAMERA_ZOOM_STEP)


func zoom_out():
	zoom(CAMERA_ZOOM_STEP)


func zoom(step):
	camera.zoom.x = clamp(camera.zoom.x + step, MIN_ZOOM, MAX_ZOOM)
	camera.zoom.y = clamp(camera.zoom.y + step, MIN_ZOOM, MAX_ZOOM)


func reset_zoom():
	camera.zoom = Vector2(1, 1)


func reload_level():
	if player:
		player.queue_free()
		player = null

	# Cleanup any stray coins or other user placed objects
	var main = get_tree().current_scene
	for child in main.get_children():
		if child.is_in_group("UserPlacedObject"):
			child.queue_free()
	
	currentLevel.queue_free()
	currentLevel = Utils.instance_scene_on_main(load(currentLevelPath))
	spawn()


func change_levels(scene_path):
	if currentLevel.is_final_level():
		get_tree().change_scene("res://Menus/TheEnd.tscn")
		return

	if player:
		player.queue_free()
		player = null

	currentLevel.queue_free()
	currentLevelPath = scene_path
	currentLevel = Utils.instance_scene_on_main(load(scene_path))
	update_save_data()
	spawn()


func _on_Player_died():
	reload_level()


func _on_Events_next_level(scene_path):
	call_deferred("change_levels", scene_path)
