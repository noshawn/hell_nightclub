class_name LighterMinigame
extends CanvasLayer

signal minigame_success
signal minigame_fail
signal minigame_burn  # catastrophic failure

@export var bar_speed: float = 400.0  # pixels per second
@export var ok_zone_ratio: float = 0.2  # 20% of bar is OK zone
@export var burn_zone_ratio: float = 0.1  # 10% on each end is BURN zone

@onready var panel: PanelContainer = $Panel
@onready var bar_bg: ColorRect = $Panel/VBoxContainer/BarContainer/BarBG
@onready var burn_left: ColorRect = $Panel/VBoxContainer/BarContainer/BurnLeft
@onready var fail_left: ColorRect = $Panel/VBoxContainer/BarContainer/FailLeft
@onready var ok_zone: ColorRect = $Panel/VBoxContainer/BarContainer/OKZone
@onready var fail_right: ColorRect = $Panel/VBoxContainer/BarContainer/FailRight
@onready var burn_right: ColorRect = $Panel/VBoxContainer/BarContainer/BurnRight
@onready var marker: ColorRect = $Panel/VBoxContainer/BarContainer/Marker
@onready var instruction_label: Label = $Panel/VBoxContainer/InstructionLabel
@onready var result_label: Label = $Panel/VBoxContainer/ResultLabel

var is_active: bool = false
var marker_position: float = 0.0  # 0.0 to 1.0
var direction: int = 1
var current_npc: Node = null
var bar_width: float = 0.0

func _ready() -> void:
	panel.visible = false
	add_to_group("lighter_minigame")

func _process(delta: float) -> void:
	if not is_active:
		return
	
	# Move marker back and forth
	marker_position += direction * (bar_speed / bar_width) * delta
	
	if marker_position >= 1.0:
		marker_position = 1.0
		direction = -1
	elif marker_position <= 0.0:
		marker_position = 0.0
		direction = 1
	
	# Update marker visual position
	marker.position.x = marker_position * (bar_width - marker.size.x)

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		stop_and_evaluate()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		stop_and_evaluate()
		get_viewport().set_input_as_handled()

func start_minigame(npc: Node) -> void:
	current_npc = npc
	panel.visible = true
	result_label.text = ""
	instruction_label.text = "Press SPACE or CLICK to light!"
	
	# Wait a frame for layout
	await get_tree().process_frame
	
	bar_width = bar_bg.size.x
	setup_zones()
	
	# Start marker at random position
	marker_position = randf()
	direction = 1 if randf() > 0.5 else -1
	is_active = true

func setup_zones() -> void:
	var burn_w = bar_width * burn_zone_ratio
	var ok_w = bar_width * ok_zone_ratio
	var fail_w = (bar_width - ok_w - burn_w * 2) / 2
	
	burn_left.size.x = burn_w
	burn_left.position.x = 0
	
	fail_left.size.x = fail_w
	fail_left.position.x = burn_w
	
	ok_zone.size.x = ok_w
	ok_zone.position.x = burn_w + fail_w
	
	fail_right.size.x = fail_w
	fail_right.position.x = burn_w + fail_w + ok_w
	
	burn_right.size.x = burn_w
	burn_right.position.x = bar_width - burn_w

func stop_and_evaluate() -> void:
	is_active = false
	
	var result = evaluate_position()
	
	match result:
		"ok":
			result_label.add_theme_color_override("font_color", Color.GREEN)
			result_label.text = "Perfect! Cigarette lit."
			await get_tree().create_timer(1.0).timeout
			panel.visible = false
			minigame_success.emit()
			if current_npc and current_npc.has_method("light_cigarette"):
				current_npc.light_cigarette()
		"fail":
			result_label.add_theme_color_override("font_color", Color.YELLOW)
			result_label.text = "Fizzle... Try again."
			await get_tree().create_timer(1.0).timeout
			minigame_fail.emit()
			# Restart
			start_minigame(current_npc)
		"burn":
			result_label.add_theme_color_override("font_color", Color.RED)
			result_label.text = "BOOM! You burned their face!"
			await get_tree().create_timer(1.5).timeout
			panel.visible = false
			minigame_burn.emit()
			if current_npc and current_npc.has_method("on_burned"):
				current_npc.on_burned()

func evaluate_position() -> String:
	var burn_end = burn_zone_ratio
	var fail_end = burn_zone_ratio + (0.5 - ok_zone_ratio / 2 - burn_zone_ratio)
	var ok_end = 0.5 + ok_zone_ratio / 2
	var fail2_end = 1.0 - burn_zone_ratio
	
	if marker_position < burn_end or marker_position > fail2_end:
		return "burn"
	elif marker_position >= fail_end and marker_position <= ok_end:
		return "ok"
	else:
		return "fail"
