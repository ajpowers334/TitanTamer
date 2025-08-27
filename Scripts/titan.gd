extends CharacterBody2D

# Signals
signal action_selected(move: String)  # Emitted when the Titan selects an action
signal health_changed(new_health: float, max_health: float)  # Emitted when health changes

# Enums
enum State { IDLE, BUSY }

# Exported stats
@export var max_health: float = 100.0
@export var power: float = 10.0
@export var attack_range: float = 100.0
@export var block_power: float = 5.0
@export var agility: float = 1.0
@export var weight: float = 100.0  # Fixed weight for knockback calculations

# State variables
var current_state: State = State.IDLE
var current_health: float
var is_blocking: bool = false
var tackle_hitbox: Area2D = null
var facing_direction: int = 1  # 1 for right, -1 for left

# Physics variables
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var is_on_ground: bool = false

# AI Timer
@onready var ai_timer: Timer = Timer.new()

func _ready():
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
	var move_weights = {
		"dodge": 0.4,  # 40% chance
		"tackle": 0.4,  # 40% chance
		"block": 0.2   # 20% chance
	}
	
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
	current_state = State.IDLE

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
	
	# Flip the sprite based on direction
	scale.x = abs(scale.x) * facing_direction
	
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

func _block() -> void:
	print("[", name, "] Blocking for 1 second")
	is_blocking = true
	# Blocking reduces incoming damage for a short duration
	var block_timer = get_tree().create_timer(1.0)  # Block lasts 1 second
	block_timer.timeout.connect(
		func():
			is_blocking = false
			print("[", name, "] Block ended")
	)

func take_damage(amount: float, source_position: Vector2) -> void:
	var original_amount = amount
	
	if is_blocking:
		print("[", name, "] Blocked an attack! Reduced damage by ", block_power)
		amount = max(0, amount - block_power)
	
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
	# Handle death (e.g., play animation, emit signal, queue_free())
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
