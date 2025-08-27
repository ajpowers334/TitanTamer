extends Control

@onready var training_button = $VBoxContainer/TrainingButton

func _ready():
	self.process_mode = Node.PROCESS_MODE_ALWAYS # makes the button clickable
	training_button.pressed.connect(_on_training_button_pressed)

func _on_training_button_pressed():
	# Unpause the game before changing scenes
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/training.tscn")
	queue_free()
