extends CharacterBody2D
class_name Titan

# Base class for all titans
# Extend this class to create different titan types

# Signals
signal action_selected(move: String)  # Emitted when the Titan selects an action
signal health_changed(new_health: float, max_health: float)  # Emitted when health changes
signal defeated  # Emitted when the titan is defeated

# Enums
enum State { IDLE, BUSY }

# Base stats - these should be overridden in child classes
@export_category("Base Stats")
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var power: float = 10.0  # PWR - Modifies physical move damage
@export var range_stat: float = 10.0  # RNG - Modifies special/ranged move damage
@export var bulk: float = 5.0  # BLK - Reduces damage taken from all moves
@export var agility: float = 1.0  # AGI - Affects move frequency
@export var weight: float = 100.0  # Affects knockback resistance
@export var move_weights: Dictionary = {
	"dodge": 0.2,
	"tackle": 0.4,
	"block": 0.4
}

# Move chances (percentages)
var move_chances: Dictionary = {
	"dodge": 30,
	"tackle": 30,
	"block": 30
}

# Visuals - override these in child scenes
@export_category("Visuals")
@export var sprite_texture: Texture2D
@export var block_texture: Texture2D

# State variables
var current_state: State = State.IDLE
var is_blocking: bool = false
var tackle_hitbox: Area2D = null
var facing_direction: int = 1  # 1 for right, -1 for left

# Physics variables
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var is_on_ground: bool = false

# AI Timer
@onready var ai_timer: Timer = Timer.new()

func _ready() -> void:
	current_health = max_health
	
	# Setup AI timer
	add_child(ai_timer)
	ai_timer.timeout.connect(_on_ai_timeout)
	ai_timer.one_shot = true
	
	# Get the tackle hitbox
	tackle_hitbox = $Tackle
	if tackle_hitbox:
		tackle_hitbox.body_entered.connect(_on_tackle_hit)
		tackle_hitbox.monitoring = false  # Start disabled
	
	# Setup visuals
	_setup_visuals()
	
	# Start AI decision making
	_start_ai_cycle()

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		is_on_ground = false
	else:
		is_on_ground = true
	
	# Apply movement and handle collisions
	var was_on_floor = is_on_floor()
	move_and_slide()
	
	# Check if we just landed
	if not was_on_floor and is_on_floor():
		pass  # Landing logic can go here

func _start_ai_cycle() -> void:
	if current_state != State.BUSY:
		var interval = 1.0 / agility
		ai_timer.start(interval)  # Faster decisions with higher AGI

func _on_ai_timeout() -> void:
	if current_state == State.IDLE:
		_make_decision()
	_start_ai_cycle()

func _make_decision() -> void:
	var total = 0.0
	var roll = randf()
	
	for move in move_weights:
		total += move_weights[move]
		if roll <= total:
			_execute_move(move)
			return

func _execute_move(move: String) -> void:
	current_state = State.BUSY
	
	match move:
		"dodge":
			_dodge()
		"tackle":
			_tackle()
		"block":
			_block()
	
	action_selected.emit(move)
	current_state = State.IDLE  # Reset state after move is done

func _dodge() -> void:
	print("[", name, "] Dodging!")
	var dodge_force = 300.0 * (agility / 2.0)  # Scale dodge with AGI
	# Dodge away from the nearest opponent
	facing_direction = _get_direction_to_opponent()
	# Move in the opposite direction of the opponent
	var dodge_direction = -facing_direction
	velocity.x = dodge_force * dodge_direction
	# Update facing to match dodge direction
	facing_direction = dodge_direction
	scale.x = abs(scale.x) * facing_direction

func _get_opponent_group() -> String:
	# Returns the group name of the opposing team
	return "team_blue" if is_in_group("team_red") else "team_red"

func _find_nearest_opponent() -> Node2D:
	var opponents = get_tree().get_nodes_in_group(_get_opponent_group())
	if opponents.is_empty():
		return null
		
	var nearest = null
	var nearest_dist = INF
	
	for opponent in opponents:
		var dist = global_position.distance_to(opponent.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = opponent
			
	return nearest

func _get_direction_to_opponent() -> int:
	var opponent = _find_nearest_opponent()
	if not opponent:
		return facing_direction  # Default to current facing if no opponent
		
	return 1 if opponent.global_position.x > global_position.x else -1

func _tackle() -> void:
	print("[", name, "] Tackling with power: ", power)
	var tackle_force = 200.0 * (power / 10.0)  # Scale with PWR
	facing_direction = _get_direction_to_opponent()
	velocity.x = tackle_force * facing_direction
	
	
	# Enable hitbox when tackling
	if tackle_hitbox:
		tackle_hitbox.monitoring = true
		# Disable hitbox after a short duration
		var hitbox_timer = get_tree().create_timer(0.5)
		hitbox_timer.timeout.connect(
			func():
				if tackle_hitbox:
					tackle_hitbox.monitoring = false
		)

@onready var block_sprite = $Block

func _block() -> void:
	print("[", name, "] Blocking for 1 second")
	is_blocking = true
	velocity = Vector2.ZERO  # Stop all movement when blocking
	
	# Show the block sprite
	if block_sprite:
		block_sprite.visible = true
	
	# Blocking reduces incoming damage for a short duration
	var block_timer = get_tree().create_timer(1.0)  # Block lasts 1 second
	block_timer.timeout.connect(
		func():
			is_blocking = false
			# Hide the block sprite when blocking ends
			if block_sprite:
				block_sprite.visible = false
			print("[", name, "] Block ended")
	)

# Get the current move chances as percentages
func get_move_chances() -> Dictionary:
	return move_chances.duplicate()

# Set new move chances (percentages)
func set_move_chances(chances: Dictionary) -> void:
	# Validate and normalize the chances
	var total = 0.0
	for move in chances:
		if move in move_chances:  # Only update existing moves
			move_chances[move] = max(0, min(100, chances[move]))  # Clamp between 0-100
			total += move_chances[move]
	
	# If total is 0, reset to default to avoid division by zero
	if total <= 0:
		move_chances = {"dodge": 30, "tackle": 30, "block": 30}
		total = 90.0
	
	# Convert percentages to weights (0-1) for the AI
	for move in move_weights:
		if move in move_chances:
			move_weights[move] = move_chances[move] / total

# Virtual method for setting up visuals - override in child classes
func _setup_visuals() -> void:
	# Set up sprite if available
	if has_node("Sprite2D") and sprite_texture:
		$Sprite2D.texture = sprite_texture
	
	# Set up block sprite if available
	block_sprite = $Block if has_node("Block") else null
	if block_sprite and block_texture:
		block_sprite.texture = block_texture
		block_sprite.visible = false

func take_damage(amount: float, source_position: Vector2) -> void:
	var original_amount = amount
	
	if is_blocking:
		print("[", name, "] Blocked an attack! Reduced damage by ", bulk)
		amount = max(0, amount - bulk)
	
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	# Apply knockback based on damage and weight
	var knockback_direction = (global_position - source_position).normalized()
	var knockback_force = (amount * 10) / weight
	velocity = knockback_direction * knockback_force
	
	if current_health <= 0:
		print("[", name, "] Has been defeated!")
		_die()

func heal(amount: float) -> void:
	print("\n--- Healing ---")
	print("Healing for: ", amount)
	var old_health = current_health
	current_health = min(max_health, current_health + amount)
	print("Health: ", old_health, " -> ", current_health, "/", max_health)
	health_changed.emit(current_health, max_health)

func _die() -> void:
	# Emit defeated signal before cleaning up
	defeated.emit()
	queue_free()

func _on_tackle_hit(body: Node) -> void:
	# Make sure we don't hit ourselves
	if body == self:
		return
		
	# Check if the body is a titan
	if body.has_method("take_damage"):
		# Apply damage based on power
		var damage = power * 1.5  # Adjust damage multiplier as needed
		body.take_damage(damage, global_position)

# Public method to check if the titan can be targeted by attacks
func is_vulnerable() -> bool:
	return current_state != State.BUSY and !is_blocking
