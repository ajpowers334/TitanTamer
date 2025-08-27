extends Control

@onready var egg = $Egg
@onready var button = $Button
@onready var train_button = $TrainButton

# Available titan scenes
const TITAN_SCENES = [
	"res://Scenes/titan.tscn",
	"res://Scenes/vampire.tscn"
]

var titan: Node2D  # Will hold the instantiated titan

func _ready():
	train_button.visible = false  # Hide train button initially
	train_button.disabled = true  # Disable train button initially
	
	# Create a container for the titan
	var titan_container = Node2D.new()
	titan_container.name = "TitanContainer"
	add_child(titan_container)
	
	# Randomly select a titan scene
	var titan_scene_path = TITAN_SCENES[randi() % TITAN_SCENES.size()]
	var titan_scene = load(titan_scene_path)
	
	# Instantiate the titan
	titan = titan_scene.instantiate()
	titan_container.add_child(titan)
	titan.visible = false  # Hide titan initially
	
	# Position the titan at the same position as the egg
	titan.global_position = egg.global_position
	
	# Disable physics on the titan immediately
	if titan.has_method("set_physics_process"):
		titan.set_physics_process(false)
	if titan is CharacterBody2D:
		titan.set_physics_process_internal(false)
		titan.velocity = Vector2.ZERO
		titan.process_mode = Node.PROCESS_MODE_DISABLED
	
	button.pressed.connect(_on_button_pressed)
	train_button.pressed.connect(_on_train_button_pressed)

func _on_button_pressed():
	# Disable button to prevent multiple clicks
	button.disabled = true
	
	# Create a tween for the fade out effect
	var tween = create_tween()
	tween.tween_property(egg, "modulate:a", 0.0, 1.0)  # Fade out over 1 second

	tween.tween_callback(func():
		egg.visible = false
		titan.visible = true
		# Optional: Fade in the titan
		titan.modulate.a = 0.0
		var tween2 = create_tween()
		tween2.tween_property(titan, "modulate:a", 1.0, 0.5)  # Fade in titan over 0.5 seconds
		tween2.tween_callback(_on_hatching_complete)
		
		# Update train button text based on titan type
		if "Vampire" in titan.name:
			train_button.text = "TRAIN VAMPIRE!"
		else:
			train_button.text = "TRAIN TITAN!"
	)

func _on_hatching_complete():
	# Show and enable the train button after hatching is complete
	train_button.visible = true
	train_button.disabled = false

func _on_train_button_pressed():
	# Re-enable physics before changing scene
	if titan.has_method("set_physics_process"):
		titan.set_physics_process(true)
	if titan is CharacterBody2D:
		titan.set_physics_process_internal(true)
		titan.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Determine which titan was selected
	var titan_scene_path: String
	if "Vampire" in titan.name:
		titan_scene_path = "res://Scenes/vampire.tscn"
	else:
		titan_scene_path = "res://Scenes/titan.tscn"
	
	# Pass the titan type to the training scene
	get_tree().root.set_meta("selected_titan", titan_scene_path)
	get_tree().change_scene_to_file("res://Scenes/training.tscn")
