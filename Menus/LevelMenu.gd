extends ColorRect

onready var levelLabel = $VBoxContainer/LevelLabel
onready var parLabel = $VBoxContainer/ParLabel

func _ready():
	visible = false


func set_visible(value):
	get_tree().paused = value
	visible = value


func set_level_label(value):
	levelLabel.set_text(value)


func set_par_label(value):
	parLabel.set_text("Par: " + str(value))


func _on_StartButton_pressed():
	set_visible(false)
