class_name NPC
extends Area2D

@export var npc_name: String = "Unknown"
@export var dialogue_file: String = ""
@export var portrait_texture: Texture2D = null
@export var interaction_enabled: bool = true

var dialogue_manager: DialogueManager = null
var dialogue_data: Dictionary = {}
var has_cigarette: bool = false
var is_burned: bool = false
var talked_count: int = 0

func _ready() -> void:
	dialogue_manager = get_tree().get_first_node_in_group("dialogue_manager")
	add_to_group("npcs")
	
	# Load dialogue from JSON
	if dialogue_file != "":
		load_dialogue(dialogue_file)
	
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func load_dialogue(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			dialogue_data = json.data
			if dialogue_data.has("npc_name"):
				npc_name = dialogue_data.npc_name
		file.close()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not interaction_enabled:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		interact()
		get_viewport().set_input_as_handled()

func _on_mouse_entered() -> void:
	if interaction_enabled:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func interact() -> void:
	if dialogue_manager and not dialogue_manager.is_active:
		var dialogue = get_dialogue()
		if not dialogue.is_empty():
			dialogue_manager.start_dialogue(self, dialogue)

func get_dialogue() -> Array:
	# Override in subclass or use dialogue_data
	return []

func get_dialogue_branch(key: String) -> Array:
	if dialogue_data.has(key):
		return dialogue_data[key]
	return []

func get_portrait() -> Texture2D:
	return portrait_texture

func light_cigarette() -> void:
	has_cigarette = true
	print(npc_name, " is now smoking")

func on_burned() -> void:
	is_burned = true
	print(npc_name, " got their face burned!")
