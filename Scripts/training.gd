extends Control

@onready var fight_button = $FightButton
@onready var titan_container = $TitanContainer

var titan_scene_path: String
var titan: Node2D

func _ready():
	# Try to get the titan type from the hatch scene
	titan_scene_path = get_tree().root.get_meta("selected_titan", "res://Scenes/titan.tscn")
	
	# Instantiate the titan
	var titan_scene = load(titan_scene_path)
	titan = titan_scene.instantiate()
	titan_container.add_child(titan)
	
	# Position the titan
	titan.position = Vector2(0, 0)  # Adjust position as needed
	
	# Disable physics on the titan
	if titan.has_method("set_physics_process"):
		titan.set_physics_process(false)
	if titan is CharacterBody2D:
		titan.set_physics_process_internal(false)
		titan.velocity = Vector2.ZERO
		titan.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Connect the fight button
	if fight_button:
		fight_button.pressed.connect(_on_fight_button_pressed)

func _on_fight_button_pressed():
	# Save the titan type for the test scene
	get_tree().root.set_meta("selected_titan", titan_scene_path)
	get_tree().change_scene_to_file("res://Scenes/test.tscn")
