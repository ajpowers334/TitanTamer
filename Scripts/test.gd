extends Node2D

@onready var player_spawn = $PlayerSpawn
var player_titan: Node2D

func _ready():
	# Get the selected titan scene path from the root
	var titan_scene_path = get_tree().root.get_meta("selected_titan", "res://Scenes/titan.tscn")
	var titan_scene = load(titan_scene_path)
	
	# Instantiate the player titan
	player_titan = titan_scene.instantiate()
	
	# Add to team_red group
	player_titan.add_to_group("team_red")
	
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
