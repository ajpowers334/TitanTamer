extends Control

@onready var fight_button = $FightButton

func _ready():
	fight_button.pressed.connect(_on_fight_button_pressed)

func _on_fight_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/test.tscn")
