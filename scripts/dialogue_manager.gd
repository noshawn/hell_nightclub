class_name DialogueManager
extends CanvasLayer

signal dialogue_started
signal dialogue_ended

@export var text_speed: float = 0.03  # seconds per character

@onready var panel: PanelContainer = $Panel
@onready var portrait_rect: TextureRect = $Panel/MarginContainer/HBoxContainer/PortraitRect
@onready var speaker_label: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/SpeakerLabel
@onready var dialogue_label: RichTextLabel = $Panel/MarginContainer/HBoxContainer/VBoxContainer/DialogueLabel
@onready var choices_container: VBoxContainer = $Panel/MarginContainer/HBoxContainer/VBoxContainer/ChoicesContainer
@onready var continue_hint: Label = $Panel/MarginContainer/HBoxContainer/VBoxContainer/ContinueHint

var current_dialogue: Array = []
var current_index: int = 0
var is_active: bool = false
var current_npc: Node = null

var is_typing: bool = false
var full_text: String = ""
var tween: Tween = null

func _ready() -> void:
	add_to_group("dialogue_manager")
	panel.visible = false
	panel.gui_input.connect(_on_panel_gui_input)

func _on_panel_gui_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if choices_container.get_child_count() > 0:
			return
		
		if is_typing:
			# Skip to full text
			skip_typewriter()
		else:
			advance_dialogue()
		get_viewport().set_input_as_handled()

func start_dialogue(npc: Node, dialogue: Array) -> void:
	current_npc = npc
	current_dialogue = dialogue
	current_index = 0
	is_active = true
	panel.visible = true
	
	if npc.has_method("get_portrait"):
		portrait_rect.texture = npc.get_portrait()
	elif npc.get("portrait_texture"):
		portrait_rect.texture = npc.portrait_texture
	else:
		portrait_rect.texture = null
	
	dialogue_started.emit()
	show_current_line()

func show_current_line() -> void:
	if current_index >= current_dialogue.size():
		end_dialogue()
		return
	
	var line = current_dialogue[current_index]
	speaker_label.text = line.get("speaker", "???")
	full_text = line.get("text", "")
	
	# Clear old choices
	for child in choices_container.get_children():
		child.queue_free()
	
	if line.has("choices"):
		continue_hint.visible = false
		dialogue_label.text = ""
		is_typing = false
		# Add choices
		for i in range(line.choices.size()):
			var choice = line.choices[i]
			var btn = Button.new()
			btn.text = choice.text
			btn.add_theme_font_size_override("font_size", 28)
			btn.pressed.connect(_on_choice_selected.bind(i, choice))
			choices_container.add_child(btn)
	else:
		continue_hint.visible = false
		start_typewriter()

func start_typewriter() -> void:
	is_typing = true
	dialogue_label.text = ""
	dialogue_label.visible_characters = 0
	dialogue_label.text = full_text
	
	if tween:
		tween.kill()
	
	var char_count = full_text.length()
	var duration = char_count * text_speed
	
	tween = create_tween()
	tween.tween_property(dialogue_label, "visible_characters", char_count, duration)
	tween.tween_callback(_on_typewriter_finished)

func skip_typewriter() -> void:
	if tween:
		tween.kill()
	dialogue_label.visible_characters = -1
	_on_typewriter_finished()

func _on_typewriter_finished() -> void:
	is_typing = false
	if choices_container.get_child_count() == 0:
		continue_hint.visible = true

func advance_dialogue() -> void:
	current_index += 1
	show_current_line()

func _on_choice_selected(_index: int, choice: Dictionary) -> void:
	if choice.has("next_dialogue_key") and current_npc:
		var branch = current_npc.get_dialogue_branch(choice.next_dialogue_key)
		if not branch.is_empty():
			current_dialogue = branch
			current_index = 0
			show_current_line()
			return
	
	if choice.has("action") and current_npc:
		if choice.action == "light_cigarette":
			# Trigger minigame instead of direct action
			start_lighter_minigame()
			return
		elif current_npc.has_method(choice.action):
			current_npc.call(choice.action)
	
	advance_dialogue()

func start_lighter_minigame() -> void:
	var minigame = get_tree().get_first_node_in_group("lighter_minigame")
	if minigame:
		panel.visible = false
		
		# Connect signals for this attempt
		if not minigame.minigame_success.is_connected(_on_lighter_success):
			minigame.minigame_success.connect(_on_lighter_success)
		if not minigame.minigame_burn.is_connected(_on_lighter_burn):
			minigame.minigame_burn.connect(_on_lighter_burn)
		
		minigame.start_minigame(current_npc)

func _on_lighter_success() -> void:
	# Show post-cigarette dialogue
	if current_npc:
		var branch = current_npc.get_dialogue_branch("after_cigarette")
		if not branch.is_empty():
			current_dialogue = branch
			current_index = 0
			panel.visible = true
			show_current_line()
		else:
			end_dialogue()

func _on_lighter_burn() -> void:
	# Show burn reaction dialogue
	if current_npc:
		var branch = current_npc.get_dialogue_branch("burned")
		if not branch.is_empty():
			current_dialogue = branch
			current_index = 0
			panel.visible = true
			show_current_line()
		else:
			end_dialogue()

func end_dialogue() -> void:
	is_active = false
	panel.visible = false
	current_npc = null
	current_dialogue = []
	if tween:
		tween.kill()
	dialogue_ended.emit()
