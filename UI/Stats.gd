extends ColorRect

var stats = Utils.get_PlayerStats()
var MainInstances = Utils.get_MainInstances()

onready var coinsUsed = $HBoxContainer/CoinsUsed
onready var par = $HBoxContainer/Par


func _process(delta):
	coinsUsed.set_text("Coins Used: " + str(stats.coins_used))
	par.set_text("Par: " + str(MainInstances.currentLevel.par))
