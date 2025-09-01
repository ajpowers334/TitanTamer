extends Node

# Dictionary to store move chances for each titan
var titan_move_chances = {}

# Function to update move chances for a titan
func update_move_chances(titan_name: String, chances: Dictionary) -> void:
	print("GameState: Updating move chances for ", titan_name, " - ", chances)
	titan_move_chances[titan_name] = chances.duplicate()

# Function to get move chances for a titan
func get_move_chances(titan_name: String) -> Dictionary:
	var chances = titan_move_chances.get(titan_name, {})
	print("GameState: Getting move chances for ", titan_name, " - ", "Found: ", not chances.is_empty())
	return chances
