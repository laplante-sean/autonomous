extends Resource
class_name PlayerStats

var death_count = 0
var coins_used = 0


func reload_level():
	"""
	Called when we reload the current level or load a new level.
	Clear the stats. We only keep per-level stats. We track global
	stats in the save data.
	"""
	death_count = 0
	coins_used = 0
