extends Node2D

@onready var player_spawn = $PlayerSpawn
var player_titan: Node2D

func _ready():
	# Get the saved titan stats
	var titan_stats = get_tree().root.get_meta("selected_titan_stats", {})
	
	# Default to regular titan if no saved stats
	var titan_scene_path = titan_stats.get("scene_path", "res://Scenes/titan.tscn")
	var titan_scene = load(titan_scene_path)
	
	# Instantiate the player titan
	player_titan = titan_scene.instantiate()
	
	# Apply saved stats if they exist
	if titan_stats.has("max_health"):
		player_titan.max_health = titan_stats["max_health"]
		player_titan.current_health = titan_stats["current_health"]
		player_titan.power = titan_stats["power"]
		player_titan.range_stat = titan_stats["range_stat"]
		player_titan.bulk = titan_stats["bulk"]
		player_titan.agility = titan_stats["agility"]
		player_titan.weight = titan_stats["weight"]
	
	# Add to team_red group
	player_titan.add_to_group("team_red")
	
	# Add the titan to the scene
	add_child(player_titan)
	
	# Make sure the titan is set up for gameplay
	if player_titan.has_method("set_physics_process"):
		player_titan.set_physics_process(true)
	if player_titan is CharacterBody2D:
		player_titan.set_physics_process_internal(true)
		player_titan.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Position the player titan
	if player_spawn:
		player_titan.global_position = player_spawn.global_position
	else:
		# Fallback position if no spawn point is found
		player_titan.position = Vector2(200, 300)
	
	# Add to scene
	add_child(player_titan)
	
	# Make sure the titan is set up for gameplay
	if player_titan.has_method("set_physics_process"):
		player_titan.set_physics_process(true)
	if player_titan is CharacterBody2D:
		player_titan.set_physics_process_internal(true)
		player_titan.process_mode = Node.PROCESS_MODE_INHERIT
