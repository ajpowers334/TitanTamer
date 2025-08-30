extends Node2D

@onready var player_spawn = $PlayerSpawn
@onready var enemy_spawn = $EnemySpawn

@onready var player_health_bar = $PlayerHealthBar
@onready var enemy_health_bar = $EnemyHealthBar

var player_titan: Node2D
var enemy_titan: Node2D

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
		
		# Apply move chances if they exist
		if titan_stats.has("move_chances") and player_titan.has_method("set_move_chances"):
			player_titan.set_move_chances(titan_stats["move_chances"].duplicate())
	
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
	
	# Create and set up enemy titan
	_create_enemy_titan()
	
	# Connect to defeat/death signals
	if player_titan.has_signal("defeated"):
		player_titan.defeated.connect(_on_player_titan_defeated)
	
	if enemy_titan.has_signal("defeated"):
		# Connect to the same function but we can handle it differently if needed
		enemy_titan.defeated.connect(_on_enemy_titan_defeated)
	
	# Connect to player health changes
	if player_titan.has_signal("health_changed"):
		player_titan.health_changed.connect(_on_player_health_changed)
	# Initialize bar
	_on_player_health_changed(player_titan.current_health, player_titan.max_health)

	# Connect to enemy health changes
	if enemy_titan.has_signal("health_changed"):
		enemy_titan.health_changed.connect(_on_enemy_health_changed)
	# Initialize bar
	_on_enemy_health_changed(enemy_titan.current_health, enemy_titan.max_health)

func _create_enemy_titan():
	# Create a basic enemy titan
	var enemy_scene = load("res://Scenes/titan.tscn")
	enemy_titan = enemy_scene.instantiate()
	
	# Add to team_blue group
	enemy_titan.add_to_group("team_blue")
	
	# Position the enemy titan
	if enemy_spawn:
		enemy_titan.global_position = enemy_spawn.global_position
	else:
		enemy_titan.position = Vector2(800, 300)  # Default position if no spawn point
	
	# Add to scene
	add_child(enemy_titan)
	
	# Set up physics if needed
	if enemy_titan.has_method("set_physics_process"):
		enemy_titan.set_physics_process(true)
	if enemy_titan is CharacterBody2D:
		enemy_titan.set_physics_process_internal(true)
		enemy_titan.process_mode = Node.PROCESS_MODE_INHERIT

func _on_player_titan_defeated():
	# Save player titan stats before showing game over
	_save_player_stats()
	# Pause the game and show game over UI
	get_tree().paused = true
	var gameover_scene = load("res://Scenes/gameoverui.tscn")
	var gameover_ui = gameover_scene.instantiate()
	gameover_ui.victory = false  # Player lost
	get_tree().root.add_child(gameover_ui)

func _on_enemy_titan_defeated():
	# Save player titan stats before showing victory
	_save_player_stats()
	# Pause the game and show game over UI
	get_tree().paused = true
	var gameover_scene = load("res://Scenes/gameoverui.tscn")
	var gameover_ui = gameover_scene.instantiate()
	gameover_ui.victory = true  # Player won
	get_tree().root.add_child(gameover_ui)

func _save_player_stats():
	# Save the player titan's current stats
	if player_titan:
		var titan_stats = {
			"scene_path": get_tree().root.get_meta("selected_titan_stats", {}).get("scene_path", "res://Scenes/titan.tscn"),
			"max_health": player_titan.max_health,
			"current_health": player_titan.max_health,  # Heal to full when returning to training
			"power": player_titan.power,
			"range_stat": player_titan.range_stat,
			"bulk": player_titan.bulk,
			"agility": player_titan.agility,
			"weight": player_titan.weight,
			"move_chances": player_titan.get_move_chances().duplicate() if player_titan.has_method("get_move_chances") 
											else {"dodge": 30, "tackle": 30, "block": 30}
		}
		get_tree().root.set_meta("selected_titan_stats", titan_stats)

func _on_player_health_changed(current: float, max: float) -> void:
	if player_health_bar:
		player_health_bar.max_value = max
		player_health_bar.value = current

func _on_enemy_health_changed(current: float, max: float) -> void:
	if enemy_health_bar:
		enemy_health_bar.max_value = max
		enemy_health_bar.value = current
