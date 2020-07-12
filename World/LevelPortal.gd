extends Area2D

export(String, FILE, "*.tscn") var next_level_path = ""


func _on_LevelPortal_body_entered(body):
	Events.emit_signal("next_level", next_level_path)
