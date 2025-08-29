extends Titan
class_name GolemTitan

# Make sure Titan class is loaded
const Titan = preload("res://Scripts/titan.gd")

# Golem-specific stats
@export var damage_reduction: float = 0.3  # 30% damage reduction due to stony exterior
var current_move: String = ""  # Track current move

func _init() -> void:
	# Override base titan stats - High HP, High BLK, Low AGI
	max_health = 150.0     # Very high health
	current_health = max_health
	range_stat = 6.0       # Poor range (RNG)
	power = 10.0           # Moderate power (PWR)
	agility = 0.7          # Slow movement (AGI)
	weight = 200.0         # Very heavy, resistant to knockback
	bulk = 8.0             # Excellent bulk (BLK)
	
	# Adjust move weights - defensive playstyle with healing
	move_weights = {
		"dodge": 0.1,     # Poor at dodging
		"tackle": 0.3,    # Moderate attacking
		"block": 0.3,     # Good at blocking
		"heal": 0.3       # Can heal itself
	}
	
# Healing properties
@export var heal_amount: float = 20.0  # Amount to heal
@export var heal_duration: float = 1.0 # Time to complete healing
var is_healing: bool = false

# Override take_damage to implement damage reduction
func take_damage(amount: float, source_position: Vector2) -> void:
	# Apply damage reduction
	var reduced_damage = amount * (1.0 - damage_reduction)
	super.take_damage(reduced_damage, source_position)

# Override tackle to be slower but more powerful
func _tackle() -> void:
	# Increase power for the tackle
	var original_power = power
	power *= 1.3  # 30% stronger tackles
	
	super._tackle()  # Call base tackle
	
	# Reset power after tackle
	power = original_power

# Override the select_move function to include healing
func select_move() -> void:
	# If health is low, increase heal chance
	var health_ratio = current_health / max_health
	var heal_chance = move_weights["heal"] * (1.0 - health_ratio)  # More likely to heal when low on health
	
	var move_choices = ["dodge", "tackle", "block"]
	var weights = [move_weights["dodge"], move_weights["tackle"], move_weights["block"]]
	
	# Add heal to possible moves if not already healing
	if !is_healing:
		move_choices.append("heal")
		weights.append(heal_chance)
	
	var selected_move = move_choices[randi() % move_choices.size()]  # Simple random selection
	
	match selected_move:
		"heal":
			heal_self()
		_:
			current_move = selected_move
			emit_signal("move_selected", current_move)

# Heal over time
func heal_self() -> void:
	is_healing = true
	current_move = "heal"
	emit_signal("move_selected", current_move)
	
	# Create a healing effect
	var heal_timer = get_tree().create_timer(heal_duration, false)
	heal_timer.timeout.connect(_on_heal_complete)
	
	# Visual feedback
	if has_node("HealParticles"):
		$HealParticles.emitting = true
	
	# Optional: Play heal animation
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("heal")

func _on_heal_complete() -> void:
	if is_healing:  # Make sure we're still healing (in case of interruptions)
		current_health = min(max_health, current_health + heal_amount)
		health_changed.emit(current_health, max_health)
		is_healing = false
		
		# Reset particles if they exist
		if has_node("HealParticles"):
			$HealParticles.emitting = false

# Override to customize visuals
func _setup_visuals() -> void:
	super._setup_visuals()
	# Add any golem-specific visual setup here
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.7, 0.7, 0.7)  # Stone-like gray color
		# Optional: Add some visual effects to show the golem's sturdiness
		if has_node("AnimationPlayer"):
			$AnimationPlayer.play("idle_heavy")
