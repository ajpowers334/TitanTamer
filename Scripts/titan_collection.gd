extends Control

# Dictionary mapping titan names to their scene paths
const TITAN_SCENES = {
	"Base Titan": "res://Scenes/titan.tscn",
	"Vampire Titan": "res://Scenes/vampire.tscn",
	"Golem Titan": "res://Scenes/golem.tscn",
	"Gryphon Titan": "res://Scenes/gryphon.tscn",
	"Imp Titan": "res://Scenes/imp.tscn"
}

@onready var titan_container = $TitanContainer
@onready var back_button = $BackButton

func _ready() -> void:
	# Connect the back button
	back_button.pressed.connect(_on_back_pressed)
	
	# Load all titans
	load_titans()

func load_titans() -> void:
	var titan_nodes = titan_container.get_children()
	
	# Sort titan nodes by name to ensure consistent ordering
	titan_nodes.sort_custom(func(a, b): return a.name < b.name)
	
	# Load each titan scene into its corresponding container
	for i in range(min(titan_nodes.size(), TITAN_SCENES.size())):
		var titan_node = titan_nodes[i]
		var titan_name = titan_node.get("editor_description")
		var titan_scene_path = TITAN_SCENES.get(titan_name, "")
		
		if titan_name and titan_scene_path and ResourceLoader.exists(titan_scene_path):
			var titan_scene = load(titan_scene_path).instantiate()
			titan_node.add_child(titan_scene)
			
			# Disable physics and AI for the gallery
			disable_titan_physics(titan_scene)
			
			# Set up click detection
			setup_titan_interaction(titan_node, titan_name)

func disable_titan_physics(titan: Node) -> void:
	# Disable physics processing
	titan.set_physics_process(false)
	if titan is CharacterBody2D:
		titan.set_physics_process_internal(false)
		titan.velocity = Vector2.ZERO
		titan.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Recursively disable physics for all children
	for child in titan.get_children():
		disable_titan_physics(child)

func setup_titan_interaction(titan_node: Control, titan_name: String) -> void:
	# Set up the control to be clickable
	titan_node.mouse_filter = Control.MOUSE_FILTER_STOP
	titan_node.custom_minimum_size = Vector2(100, 200)  # Adjust size as needed
	
	# Connect the gui_input signal for click detection
	titan_node.gui_input.connect(
		func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_titan_clicked(titan_name)
	)
	
	# Store titan name for reference
	titan_node.set_meta("titan_name", titan_name)

func _on_titan_clicked(titan_name: String) -> void:
	print("Selected titan:", titan_name)
	# Here you can add code to show more details about the titan

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")  # Adjust to your main menu scene
