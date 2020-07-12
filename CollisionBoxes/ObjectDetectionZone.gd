extends Area2D
class_name ObjectDetectionZone

signal object_detected(body)


func _on_ObjectDetectionZone_body_entered(body):
	emit_signal("object_detected", body)
