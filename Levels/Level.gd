extends Node2D

export(bool) var finalLevel = false
export(String) var label = ""
export(int) var par = 0

onready var spawnPoint = $SpawnPoint
onready var levelMenu = $LevelMenu
onready var levelLabel = $LevelMenu/VBoxContainer/LevelLabel


func is_final_level():
	return finalLevel


func get_spawn_point():
	return spawnPoint.global_position


func _on_DeathArea_body_entered(player):
	Events.emit_signal("add_camera_shake", 0.5, 0.5)
	player.die()
