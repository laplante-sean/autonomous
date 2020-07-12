extends Area2D
class_name CollectibleDetector

signal collect(value)


func _on_CollectibleDetector_body_entered(body):
	emit_signal("collect", body.COLLECTION_VALUE)
	body.queue_free()  # We collected it
