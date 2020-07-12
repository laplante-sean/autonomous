extends Node2D

export(bool) var finalLevel = false

onready var spawnPoint = $SpawnPoint


func is_final_level():
	return finalLevel


func get_spawn_point():
	return spawnPoint.global_position


func _on_PlayableArea_body_exited(player):
	Events.emit_signal("add_camera_shake", 0.25, 0.5)
	player.call_deferred("die")
