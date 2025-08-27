extends Control

@onready var start_run_button = $StartRunButton

func _ready():
	start_run_button.pressed.connect(_on_start_run_pressed)

func _on_start_run_pressed():
	get_tree().change_scene_to_file("res://Scenes/hatch.tscn")
