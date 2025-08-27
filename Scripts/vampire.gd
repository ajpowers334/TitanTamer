extends Titan
class_name VampireTitan

# Make sure Titan class is loaded
const Titan = preload("res://Scripts/titan.gd")

# Vampire-specific stats
@export var life_steal_amount: float = 0.3  # 30% of damage dealt is returned as health

func _init() -> void:
	# Override base titan stats
	max_health = 80.0      # Lower health
	range_stat = 12.0      # Moderate range strength (RNG)
	power = 12.0           # Moderate power strength (PWR)
	agility = 1.5          # Faster than average (AGI)
	weight = 80.0          # Lighter, more susceptible to knockback
	bulk = 3.0             # Weaker bulk (BLK)
	
	# Adjust move weights - more aggressive playstyle
	move_weights = {
		"dodge": 0.4,    # Good at dodging
		"tackle": 0.5,   # Prefers attacking
		"block": 0.1     # Rarely blocks
	}

# Override take_damage to implement life steal
func take_damage(amount: float, source_position: Vector2) -> void:
	# First let the base class handle the damage
	super.take_damage(amount, source_position)
	
	# If we're the one dealing damage (source is the one who called take_damage)
	# This would need to be called from the attack that hits the opponent

# Override tackle to add life steal effect
func _tackle() -> void:
	super._tackle()  # Call base tackle first
	
	# Add life steal effect - this would need to be connected to when the tackle hits
	var life_steal_callback = func():
		if tackle_hitbox and tackle_hitbox.has_overlapping_bodies():
			var heal_amount = power * life_steal_amount
			current_health = min(max_health, current_health + heal_amount)
			health_changed.emit(current_health, max_health)
	
	# Connect to when the hitbox is activated
	if tackle_hitbox:
		tackle_hitbox.body_entered.connect(life_steal_callback, CONNECT_ONE_SHOT)

# Override to customize visuals
func _setup_visuals() -> void:
	super._setup_visuals()
	# Add any vampire-specific visual setup here
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.8, 0.1, 0.1)  # Dark red tint
