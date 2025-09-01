extends Control

@onready var start_run_button = $StartRunButton
@onready var titans_button = $TitansButton

func _ready():
	start_run_button.pressed.connect(_on_start_run_pressed)
	titans_button.pressed.connect(_on_titans_pressed)

func _on_start_run_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/hatch.tscn")

func _on_titans_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/titan_collection.tscn")
