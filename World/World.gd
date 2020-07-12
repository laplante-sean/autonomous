extends Node2D

const Coin = preload("res://Items/Coin.tscn")
const Player = preload("res://Player/Player.tscn")

export(String, FILE, "*.tscn") var start_level_path = ""
export(float) var CAMERA_ZOOM_STEP = 0.05
export(float) var MIN_ZOOM = 1
export(float) var MAX_ZOOM = 2

var MainInstances = Utils.get_MainInstances()
var stats = Utils.get_PlayerStats()
var currentLevel = null
var player = null
var currentLevelPath = "res://Levels/Level_00.tscn"

onready var levelMenu = $UI/LevelMenu
onready var camera = $Camera


func _ready():
	"""
	1-bit game. Set background to be always black
	"""
	VisualServer.set_default_clear_color(Color.black)
	Events.connect("next_level", self, "_on_Events_next_level")

	if MainInstances.is_load_game:
		var save_data = SaveAndLoad.load_data_from_file()
		currentLevelPath = save_data.current_level
		reload_level()
	elif start_level_path:
		# If this is set, use it.
		currentLevelPath = start_level_path
		reload_level()
	else:
		reload_level()
	
	if MainInstances.is_new_game:
		SaveAndLoad.save_data_to_file(SaveAndLoad.default_save_data)


func _physics_process(delta):
	if Input.is_action_just_pressed("create"):
		create_coin()
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


func update_save_data(current_level, game_completed=false):
	var save_data = SaveAndLoad.load_data_from_file()
	save_data.current_level = current_level
	save_data.total_death_count += stats.death_count
	save_data.total_coins_used += stats.coins_used
	
	# If we're changing levels, currentLevelPath will be
	# the previous level (e.g. the level we just completed)
	# while current_level will be the level we're going to.
	save_data.levels[currentLevelPath] = {
		death_count = stats.death_count,
		coins_used = stats.coins_used,
		par = currentLevel.par
	}
	
	if game_completed:
		save_data.playthroughs += 1
	
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


func create_coin():
	Utils.instance_scene_on_main(Coin, get_local_mouse_position())
	stats.coins_used += 1

func reload_level(fresh_load=true):
	"""
	Called to reload or load whatever level path
	is set in currentLevelPath.
	
	:param fresh_load: True if this reload is called due to a level change or
					   initial start of the game. False if this is the result
					   of a death
	"""
	if player:
		player.queue_free()
		player = null

	# Cleanup any stray coins or other user placed objects
	var main = get_tree().current_scene
	for child in main.get_children():
		if child.is_in_group("UserPlacedObject"):
			child.queue_free()
	
	if currentLevel:
		currentLevel.queue_free()

	currentLevel = Utils.instance_scene_on_main(load(currentLevelPath))
	MainInstances.currentLevel = currentLevel
	stats.reload_level()  # Clear the level stats
	spawn()
	
	if fresh_load:
		call_deferred("display_level_welcome")


func display_level_welcome():
	levelMenu.set_level_label(currentLevel.label)
	levelMenu.set_par_label(currentLevel.par)
	levelMenu.set_visible(true)


func change_levels(scene_path):
	if currentLevel.is_final_level():
		update_save_data("res://Levels/Level_00.tscn", true)
		get_tree().change_scene("res://Menus/TheEnd.tscn")
		return

	update_save_data(scene_path)
	currentLevelPath = scene_path
	reload_level()


func _on_Player_died():
	update_save_data(currentLevelPath)
	reload_level(false)  # We died, this isn't a fresh load of the level


func _on_Events_next_level(scene_path):
	call_deferred("change_levels", scene_path)
