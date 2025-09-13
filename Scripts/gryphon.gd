extends Titan
class_name GryphonTitan

# Make sure Titan class is loaded
const Titan = preload("res://Scripts/titan.gd")

# Gryphon-specific stats
var is_gliding: bool = false

func _init() -> void:
	# Gryphon stats - ranger type
	max_health = 90.0       # Moderate health
	current_health = 90.0   # Start at full health
	range_stat = 18.0       # High range focus (RNG)
	power = 8.0            # Lower power (PWR) - relies on ranged attacks
	agility = 1.5          # Medium agility (AGI)
	weight = 70.0          # Lighter for better mobility
	bulk = 3.0             # Moderate damage reduction (BLK)
	
	# Move chances - favors dodging and quick attacks
	move_chances = {
		"dodge": 40,    # Good at dodging
		"tackle": 20,   # Less likely to tackle
		"block": 10     # Rarely blocks
	}

func _ready() -> void:
	super._ready()
	# Set up any Gryphon-specific initialization here

# Override dodge to make it a glide
func _dodge() -> void:
	is_gliding = true
	# Call base dodge first
	super._dodge()
	
	# Add glide effect - reduce gravity while gliding
	var original_gravity = gravity
	gravity *= 0.3
	
	# End glide after a short time
	var glide_timer = get_tree().create_timer(1.0)
	glide_timer.timeout.connect(
		func():
			is_gliding = false
			gravity = original_gravity
	)

# New shoot action for Gryphon
func _shoot() -> void:
		return

# Override to customize visuals
func _setup_visuals() -> void:
	super._setup_visuals()
	# Add gryphon-specific visual setup
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.9, 0.8, 0.5)  # Golden-brown tint

# Override _execute_move to handle custom moves
func _execute_move(move: String) -> void:
	return
