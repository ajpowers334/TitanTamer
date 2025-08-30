extends Titan
class_name ImpTitan

# Make sure Titan class is loaded
const Titan = preload("res://Scripts/titan.gd")

# Imp-specific stats
@export var dash_multiplier: float = 1.5  # How much faster the dash is
@export var dash_damage_bonus: float = 0.3  # 30% bonus damage when dashing
var is_dashing: bool = false

func _init() -> void:
	# Imp stats - fast but fragile
	max_health = 60.0      # Very low health
	current_health = 60.0  # Start at full health
	range_stat = 8.0       # Lower range focus
	power = 15.0           # High power (PWR)
	agility = 2.0          # Very fast (AGI)
	weight = 50.0          # Very light, easy to knock around
	bulk = 2.0             # Low damage reduction (BLK)
	
	# Move weights - favors dodging and quick attacks
	move_weights = {
		"dodge": 0.5,    # Very good at dodging
		"tackle": 0.4,   # Quick attacks
		"block": 0.1     # Rarely blocks
	}

# Override dodge to make it a dash attack
func _dodge() -> void:
	# Call base dodge first
	super._dodge()
	
	# Add dash effect
	is_dashing = true
	var dash_speed = 400.0 * dash_multiplier * (agility / 2.0)
	velocity = Vector2(dash_speed * facing_direction, 0)
	
	# End dash after a short time
	var dash_timer = get_tree().create_timer(0.3)
	dash_timer.timeout.connect(_end_dash)

func _end_dash() -> void:
	is_dashing = false
	velocity = Vector2.ZERO

# Override tackle to work with dash
func _tackle() -> void:
	var base_power = power
	
	# If dashing, add bonus damage
	if is_dashing:
		power *= (1.0 + dash_damage_bonus)
	
	# Call base tackle
	super._tackle()
	
	# Reset power
	power = base_power

# Override to customize visuals
func _setup_visuals() -> void:
	super._setup_visuals()

# Override take_damage to be more vulnerable when not dashing
func take_damage(amount: float, source_position: Vector2) -> void:
	# Take 20% more damage when not dashing
	if not is_dashing:
		amount *= 1.2
	
	super.take_damage(amount, source_position)
