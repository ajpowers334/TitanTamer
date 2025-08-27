extends Control

# Signal emitted when health changes
signal health_changed(current_health: float, max_health: float)

@onready var fight_button = $FightButton
@onready var titan_container = $TitanContainer
@onready var training_buttons = {
	"brawler": $BrawlerTraining,
	"dodge": $DodgeTraining,
	"strength": $StrengthTraining
}

var titan_scene_path: String
var titan: Node2D

# Training types with their stat bonuses
const TRAINING_TYPES = {
	"brawler": {"power": 2, "bulk": 1},  # PWR and BLK
	"dodge": {"agility": 2, "range_stat": 1},  # AGI and RNG
	"strength": {"max_health": 2, "bulk": 1}  # HP and BLK
}

var training_completed = 0
const MAX_TRAININGS = 3

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
	
	# Connect training buttons
	for training_type in training_buttons:
		training_buttons[training_type].pressed.connect(_on_training_selected.bind(training_type))
		training_buttons[training_type].disabled = false
	
	# Hide fight button until all trainings are done
	if fight_button:
		fight_button.visible = false
		fight_button.pressed.connect(_on_fight_button_pressed)
	
	update_ui()

func _on_training_selected(training_type: String) -> void:
	if training_type in TRAINING_TYPES:
		# Apply stat bonuses
		var bonuses = TRAINING_TYPES[training_type]
		for stat in bonuses:
			match stat:
				"max_health":
					titan.max_health += bonuses[stat]
					titan.current_health = titan.max_health
					health_changed.emit(titan.current_health, titan.max_health)
				"power":
					titan.power += bonuses[stat]
				"agility":
					titan.agility += bonuses[stat]
				"bulk":
					titan.bulk += bonuses[stat]
				"range_stat":
					titan.range_stat += bonuses[stat]
		
		# Disable this training option
		training_buttons[training_type].disabled = true
		
		# Increment training counter
		training_completed += 1
		
		# Check if all trainings are done
		if training_completed >= MAX_TRAININGS and fight_button:
			fight_button.visible = true
			for button in training_buttons.values():
				button.visible = false
		
		update_ui()

func update_ui() -> void:
	# Update any UI elements to show remaining trainings
	var remaining = MAX_TRAININGS - training_completed
	if remaining > 0:
		# Update UI to show remaining trainings
		pass

func _on_fight_button_pressed():
	# Save titan stats before changing scenes
	var titan_stats = {
		"scene_path": titan_scene_path,
		"max_health": titan.max_health,
		"current_health": titan.current_health,
		"power": titan.power,
		"range_stat": titan.range_stat,
		"bulk": titan.bulk,
		"agility": titan.agility,
		"weight": titan.weight
	}
	get_tree().root.set_meta("selected_titan_stats", titan_stats)
	get_tree().change_scene_to_file("res://Scenes/test.tscn")
