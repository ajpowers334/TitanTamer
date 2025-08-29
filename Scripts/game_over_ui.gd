extends Control

@onready var result_label = $VBoxContainer/ResultLabel
@onready var training_button = $VBoxContainer/TrainingButton

var victory := false

func _ready():
	self.process_mode = Node.PROCESS_MODE_ALWAYS # makes the button clickable
	
	# Set result text based on victory state
	if victory:
		result_label.text = "Victory! Titan has returned to training."
	else:
		result_label.text = "Defeat! Titan has returned to training."
	
	training_button.pressed.connect(_on_training_button_pressed)

func _on_training_button_pressed():
	# Unpause the game before changing scenes
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/training.tscn")
	queue_free()
