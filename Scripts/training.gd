extends Control

# Signal emitted when health changes
signal health_changed(current_health: float, max_health: float)

# Move chance related signals and variables
signal move_chances_updated(chances: Dictionary)

const MOVE_CHANGE_AMOUNT = 5  # Percentage points to change per click
const MIN_MOVE_CHANCE = 5      # Minimum chance percentage for any move
const TOTAL_CHANCE = 100       # Total percentage points to distribute
const MAX_MOVE_CHANGES = 2     # Maximum number of move changes allowed per training session

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

# Move change tracking
var move_changes_remaining = MAX_MOVE_CHANGES

# Titan name for saving/loading move chances
var current_titan_name: String = ""
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
	print("Training: Starting _ready()")
	# Try to get the titan type from the hatch scene
	titan_scene_path = get_tree().root.get_meta("selected_titan", "res://Scenes/titan.tscn")
	
	# Get titan name from the path (e.g., "titan" from "res://Scenes/titan.tscn")
	current_titan_name = titan_scene_path.get_file().get_basename()
	print("Training: Loading titan ", current_titan_name)
	
	# Instantiate the titan
	var titan_scene = load(titan_scene_path)
	titan = titan_scene.instantiate()
	titan_container.add_child(titan)
	
	# Check for saved stats (from fight scene)
	var saved_stats = get_tree().root.get_meta("selected_titan_stats", {})
	
	# First try to load move chances from saved stats
	if saved_stats and saved_stats.has("move_chances"):
		print("Training: Loading move chances from saved stats: ", saved_stats["move_chances"])
		move_chances = saved_stats["move_chances"].duplicate()
		# Update GameState with these chances
		if Engine.has_singleton("GameState"):
			GameState.update_move_chances(current_titan_name, move_chances.duplicate())
	# Then try GameState
	elif Engine.has_singleton("GameState"):
		var game_state = get_node_or_null("/root/GameState")
		if game_state:
			var saved_chances = game_state.get_move_chances(current_titan_name)
			if not saved_chances.is_empty():
				print("Training: Loaded move chances from GameState: ", saved_chances)
				move_chances = saved_chances.duplicate()
	# Finally fall back to titan defaults
	if titan.has_method("get_move_chances") and move_chances.is_empty():
		print("Training: Using titan default move chances")
		move_chances = titan.get_move_chances().duplicate()
		# Save to GameState for future use
		if Engine.has_singleton("GameState"):
			GameState.update_move_chances(current_titan_name, move_chances.duplicate())
	
	# Connect move chance buttons
	for move in move_buttons:
		move_buttons[move]["increase"].pressed.connect(_on_move_increase_pressed.bind(move))
		move_buttons[move]["decrease"].pressed.connect(_on_move_decrease_pressed.bind(move))
	
	# Update move chance display
	_update_move_chance_ui()
	
	# Apply saved stats if they exist (except move_chances which we already handled)
	if saved_stats and saved_stats.has("max_health"):
		print("Training: Loading saved stats for titan")
		titan.max_health = saved_stats["max_health"]
		titan.current_health = saved_stats["current_health"]
		titan.power = saved_stats["power"]
		titan.range_stat = saved_stats["range_stat"]
		titan.bulk = saved_stats["bulk"]
		titan.agility = saved_stats["agility"]
		titan.weight = saved_stats["weight"]
		# Note: We don't load move_chances here anymore as we handle it above
	
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
		
		# Increment training counter and reset move changes
		training_completed += 1
		move_changes_remaining = 0
		
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

# Calculate the maximum amount a move can be increased
func calculate_max_increase(move: String) -> int:
	var total_available = 0
	for move_key in move_chances:
		if move_key != move and move_chances[move_key] > MIN_MOVE_CHANCE:
			total_available += (move_chances[move_key] - MIN_MOVE_CHANCE)
	return total_available

# Redistribute changes to other moves when one move is modified
func _redistribute_changes(changed_move: String, amount: int) -> void:
	if amount > 0:  # Increasing a move, need to decrease others
		var remaining = amount
		var moves_to_decrease = []
		
		# Find moves that can be decreased
		for move_key in move_chances:
			if move_key != changed_move and move_chances[move_key] > MIN_MOVE_CHANCE:
				moves_to_decrease.append(move_key)
		
		if moves_to_decrease.is_empty():
			return
			
		# Decrease moves proportionally
		var decrease_per_move = ceil(float(amount) / moves_to_decrease.size())
		for move_key in moves_to_decrease:
			if remaining <= 0:
				break
				
			var decrease_amount = min(decrease_per_move, move_chances[move_key] - MIN_MOVE_CHANCE, remaining)
			move_chances[move_key] -= decrease_amount
			remaining -= decrease_amount
	
	else:  # Decreasing a move, need to increase others
		var remaining = -amount  # Convert to positive
		var moves_to_increase = []
		
		# Find moves that can be increased
		for move_key in move_chances:
			if move_key != changed_move:
				moves_to_increase.append(move_key)
		
		if moves_to_increase.is_empty():
			return
			
		# Increase moves proportionally
		var increase_per_move = ceil(float(-amount) / moves_to_increase.size())
		for move_key in moves_to_increase:
			if remaining <= 0:
				break
				
			var increase_amount = min(increase_per_move, remaining)
			move_chances[move_key] += increase_amount
			remaining -= increase_amount

# Update the move chance display
func _update_move_chance_ui() -> void:
	# Validate that chances sum to 100
	var total = 0
	for chance in move_chances.values():
		total += chance
	
	# If they don't sum to 100, normalize them
	if total != 100:
		var normalization_factor = 100.0 / total
		for move in move_chances:
			move_chances[move] = round(move_chances[move] * normalization_factor)
		
		# Ensure exact sum of 100 after rounding
		_ensure_exact_sum()
	
	# Update all move chance labels and button states
	for move in move_chances:
		move_chance_labels[move].text = str(move_chances[move]) + "%"
		
		# Update button states based on move chances and remaining changes
		var can_increase = calculate_max_increase(move) > 0 and move_changes_remaining > 0
		move_buttons[move]["increase"].disabled = !can_increase
		move_buttons[move]["decrease"].disabled = (move_chances[move] <= MIN_MOVE_CHANCE) or (move_changes_remaining <= 0)
	
	# Update move changes counter display
	if has_node("MoveChangesLabel"):
		$MoveChangesLabel.text = "Move Changes: %d/%d" % [MAX_MOVE_CHANGES - move_changes_remaining, MAX_MOVE_CHANGES]
	
	# Save move chances to GameState if available
	if not current_titan_name.is_empty() and Engine.has_singleton("GameState"):
		GameState.update_move_chances(current_titan_name, move_chances)
	
	# Emit signal with current move chances
	move_chances_updated.emit(move_chances)

# Ensure move chances sum to exactly 100 after normalization
func _ensure_exact_sum() -> void:
	var total = 0
	for chance in move_chances.values():
		total += chance
	
	var difference = 100 - total
	if difference != 0:
		# Find the move with the highest value and adjust it
		var highest_move = ""
		var highest_value = -1
		
		for move in move_chances:
			if move_chances[move] > highest_value:
				highest_value = move_chances[move]
				highest_move = move
		
		if highest_move != "":
			move_chances[highest_move] += difference

# Calculate the total remaining move chance points that can be distributed
func calculate_remaining_chance() -> int:
	var used = 0
	for chance in move_chances.values():
		used += chance
	print("Remaining move chance points: ", TOTAL_CHANCE - used)
	return TOTAL_CHANCE - used

# Handle increase button press for a move
func _on_move_increase_pressed(move: String) -> void:
	if move_changes_remaining <= 0:
		return
		
	var amount = min(MOVE_CHANGE_AMOUNT, calculate_max_increase(move))
	if amount > 0:
		move_changes_remaining -= 1
		move_chances[move] += amount
		_redistribute_changes(move, amount)
		_update_move_chance_ui()
		
		# Save to GameState if available
		if not current_titan_name.is_empty() and Engine.has_singleton("GameState"):
			GameState.update_move_chances(current_titan_name, move_chances)
			
		# Emit signal with current move chances
		move_chances_updated.emit(move_chances)

# Handle decrease button press for a move
func _on_move_decrease_pressed(move: String) -> void:
	if move_changes_remaining <= 0 or move_chances[move] <= MIN_MOVE_CHANCE:
		return
		
	var amount = min(MOVE_CHANGE_AMOUNT, move_chances[move] - MIN_MOVE_CHANCE)
	if amount > 0:
		move_changes_remaining -= 1
		move_chances[move] -= amount
		_redistribute_changes(move, -amount)  # Negative amount means decreasing
		_update_move_chance_ui()
		
		# Save to GameState if available
		if not current_titan_name.is_empty() and Engine.has_singleton("GameState"):
			GameState.update_move_chances(current_titan_name, move_chances)
			
		# Emit signal with current move chances
		move_chances_updated.emit(move_chances)

func _on_fight_button_pressed() -> void:
	# Save the titan's current stats before switching scenes
	if titan:
		var titan_stats = {
			"scene_path": titan_scene_path,
			"max_health": titan.max_health,
			"current_health": titan.current_health,
			"power": titan.power,
			"range_stat": titan.range_stat,
			"bulk": titan.bulk,
			"agility": titan.agility,
			"weight": titan.weight,
			"move_chances": move_chances,
			"training_completed": training_completed
		}
		get_tree().root.set_meta("selected_titan_stats", titan_stats)
		
		# Save to GameState if available
		if Engine.has_singleton("GameState"):
			GameState.update_move_chances(current_titan_name, move_chances)
	
	# Load the test scene
	get_tree().change_scene_to_file("res://Scenes/test.tscn")
