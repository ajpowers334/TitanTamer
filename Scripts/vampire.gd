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
	
	# Move chances - aggressive playstyle
	move_chances = {
		"dodge": 40,    # Good at dodging
		"tackle": 50,   # Prefers attacking
		"block": 10     # Rarely blocks
	}

# Override take_damage if needed
func take_damage(amount: float, source_position: Vector2) -> void:
	super.take_damage(amount, source_position)

# Override to customize visuals
func _setup_visuals() -> void:
	super._setup_visuals()
	# Add any vampire-specific visual setup here
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.8, 0.1, 0.1)  # Dark red tint
