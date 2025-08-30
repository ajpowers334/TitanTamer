extends Control

# Signal emitted when health changes
signal health_changed(current_health: float, max_health: float)

# Move chance related signals and variables
signal move_chances_updated(chances: Dictionary)

const MOVE_CHANGE_AMOUNT = 5  # Percentage points to change per click
const MIN_MOVE_CHANCE = 5      # Minimum chance percentage for any move
const TOTAL_CHANCE = 100       # Total percentage points to distribute

@onready var stats_label = $StatsLabel
@onready var fight_button = $FightButton
@onready var titan_container = $TitanContainer

# Move chance UI elements
@onready var move_chance_labels = {
	"dodge": $MoveDisplay/MoveList/DodgeMove/DodgeChance,
	"tackle": $MoveDisplay/MoveList/TackleMove/TackleChance,
	"block": $MoveDisplay/MoveList/BlockMove/BlockChance
}

@onready var move_buttons = {
	"dodge": {"increase": $MoveDisplay/MoveList/DodgeMove/DodgeIncrease, "decrease": $MoveDisplay/MoveList/DodgeMove/DodgeDecrease},
	"tackle": {"increase": $MoveDisplay/MoveList/TackleMove/TackleIncrease, "decrease": $MoveDisplay/MoveList/TackleMove/TackleDecrease},
	"block": {"increase": $MoveDisplay/MoveList/BlockMove/BlockIncrease, "decrease": $MoveDisplay/MoveList/BlockMove/BlockDecrease}
}

# Current move chances
var move_chances = {
	"dodge": 30,
	"tackle": 30,
	"block": 30
}
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
const MAX_TRAININGS = 1  # Only one training allowed

func _ready():
	# Try to get the titan type from the hatch scene
	titan_scene_path = get_tree().root.get_meta("selected_titan", "res://Scenes/titan.tscn")
	
	# Instantiate the titan
	var titan_scene = load(titan_scene_path)
	titan = titan_scene.instantiate()
	titan_container.add_child(titan)
	
	# Initialize move chances from titan if available
	if titan.has_method("get_move_chances"):
		move_chances = titan.get_move_chances()
	
	# Connect move chance buttons
	for move in move_buttons:
		move_buttons[move]["increase"].pressed.connect(_on_move_increase_pressed.bind(move))
		move_buttons[move]["decrease"].pressed.connect(_on_move_decrease_pressed.bind(move))
	
	# Update move chance display
	_update_move_chance_ui()
	
	# --- FIX: Apply saved stats if they exist ---
	var saved_stats = get_tree().root.get_meta("selected_titan_stats", null)
	if saved_stats and saved_stats.has("max_health"):
		titan.max_health = saved_stats["max_health"]
		titan.current_health = saved_stats["current_health"]
		titan.power = saved_stats["power"]
		titan.range_stat = saved_stats["range_stat"]
		titan.bulk = saved_stats["bulk"]
		titan.agility = saved_stats["agility"]
		titan.weight = saved_stats["weight"]
	
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
		
		# Disable all training buttons after one is selected
		for button in training_buttons.values():
			button.disabled = true
		
		# Show the fight button
		if fight_button:
			fight_button.visible = true
		
		# Increment training counter
		training_completed += 1
		
		update_ui()

func update_ui() -> void:
	# Update UI to show training status
	if stats_label and titan:
		stats_label.text = (
			"Current Stats:\n"
			+ "HP: %d/%d\n" % [titan.current_health, titan.max_health]
			+ "PWR: %d\n" % titan.power
			+ "AGI: %d\n" % titan.agility
			+ "BLK: %d\n" % titan.bulk
			+ "RNG: %d\n" % titan.range_stat
			+ "Weight: %d" % titan.weight
		)
	if training_completed >= MAX_TRAININGS:
		# All trainings done, show fight button
		if fight_button:
			fight_button.visible = true

# Update the move chance display
func _update_move_chance_ui() -> void:
	for move in move_chance_labels:
		move_chance_labels[move].text = "%d%%" % move_chances[move]
	
	# Update button states based on current chances
	for move in move_buttons:
		move_buttons[move]["decrease"].disabled = (move_chances[move] <= MIN_MOVE_CHANCE)
		move_buttons[move]["increase"].disabled = (move_chances[move] >= 100)

# Handle increase button press for a move
func _on_move_increase_pressed(move: String) -> void:
	var total_available = 0
	for move_key in move_chances:
		if move_key != move and move_chances[move_key] > MIN_MOVE_CHANCE:
			total_available += (move_chances[move_key] - MIN_MOVE_CHANCE)
	
	if total_available > 0:
		var amount = min(MOVE_CHANGE_AMOUNT, total_available)
		move_chances[move] += amount
		
		# Distribute the decrease among other moves
		var remaining = amount
		while remaining > 0:
			var per_move = max(1, remaining / (move_chances.size() - 1))  # At least 1 point per move
			for move_key in move_chances:
				if move_key != move and move_chances[move_key] > MIN_MOVE_CHANCE and remaining > 0:
					var decrease = min(per_move, move_chances[move_key] - MIN_MOVE_CHANCE, remaining)
					move_chances[move_key] -= decrease
					remaining -= decrease
		
		_update_move_chance_ui()
		emit_signal("move_chances_updated", move_chances.duplicate())

# Handle decrease button press for a move
func _on_move_decrease_pressed(move: String) -> void:
	if move_chances[move] > MIN_MOVE_CHANCE:
		var amount = min(MOVE_CHANGE_AMOUNT, move_chances[move] - MIN_MOVE_CHANCE)
		move_chances[move] -= amount
		
		# Distribute the increase among other moves
		var remaining = amount
		while remaining > 0:
			var per_move = max(1, remaining / (move_chances.size() - 1))  # At least 1 point per move
			for move_key in move_chances:
				if move_key != move and remaining > 0:
					var increase = min(per_move, remaining)
					move_chances[move_key] += increase
					remaining -= increase
		
		_update_move_chance_ui()
		emit_signal("move_chances_updated", move_chances.duplicate())

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
		"weight": titan.weight,
		"move_chances": move_chances.duplicate()  # Save current move chances
	}
	get_tree().root.set_meta("selected_titan_stats", titan_stats)
	get_tree().change_scene_to_file("res://Scenes/test.tscn")
