extends Titan
class_name GryphonTitan

# Make sure Titan class is loaded
const Titan = preload("res://Scripts/titan.gd")

# Gryphon-specific stats
@export var feather_projectile_scene: PackedScene
@export var feather_speed: float = 600.0
@export var feather_cooldown: float = 1.5
var can_shoot: bool = true
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
	
	# Move weights - favors ranged attacks and mobility
	move_weights = {
		"dodge": 0.4,    # Good at dodging
		"tackle": 0.2,   # Less likely to tackle
		"block": 0.1,    # Rarely blocks
		"shoot": 0.3     # Added shoot move
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
	if not can_shoot:
		return
		
	if feather_projectile_scene:
		var feather = feather_projectile_scene.instantiate()
		get_parent().add_child(feather)
		feather.global_position = global_position
		
		# Set velocity based on facing direction
		var direction = Vector2.RIGHT * facing_direction
		if "velocity" in feather:
			feather.velocity = direction * feather_speed
		elif "linear_velocity" in feather:
			feather.linear_velocity = direction * feather_speed
		
		# Apply cooldown
		can_shoot = false
		var cooldown_timer = get_tree().create_timer(feather_cooldown)
		cooldown_timer.timeout.connect(
			func():
				can_shoot = true
		)

# Override to customize visuals
func _setup_visuals() -> void:
	super._setup_visuals()
	# Add gryphon-specific visual setup
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.9, 0.8, 0.5)  # Golden-brown tint

# Override _execute_move to handle custom moves
func _execute_move(move: String) -> void:
	match move:
		"shoot":
			if can_shoot:
				_shoot()
				# Let the base class know we're busy
				super._execute_move(move)
			else:
				# If shoot is on cooldown, try another move
				_make_decision()
			return  # Skip the base class execution for shoot
		_:
			super._execute_move(move)

# Override _make_decision to include shoot in move selection
func _make_decision() -> void:
	# Create a temporary move_weights dictionary that excludes shoot if on cooldown
	var temp_move_weights = move_weights.duplicate()
	if not can_shoot and temp_move_weights.has("shoot"):
		temp_move_weights.erase("shoot")
	
	# If no moves are available, use a default move
	if temp_move_weights.is_empty():
		super._make_decision()
		return
	
	# Calculate total weight for probability distribution
	var total = 0.0
	for move in temp_move_weights:
		total += temp_move_weights[move]
	
	# If total is 0, use super implementation
	if total <= 0:
		super._make_decision()
		return
	
	# Select a move based on weights
	var roll = randf() * total
	var current = 0.0
	
	for move in temp_move_weights:
		current += temp_move_weights[move]
		if roll <= current:
			_execute_move(move)
			return
	
	# Fallback to base implementation if something goes wrong
	super._make_decision()
