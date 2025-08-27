extends Control

@onready var egg = $Egg
@onready var titan = $Titan
@onready var button = $Button
@onready var train_button = $TrainButton

func _ready():
	titan.visible = false  # Hide titan initially
	train_button.visible = false  # Hide train button initially
	train_button.disabled = true  # Disable train button initially
	
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
	)

func _on_hatching_complete():
	# Show and enable the train button after hatching is complete
	train_button.visible = true
	train_button.disabled = false

func _on_train_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/training.tscn")
